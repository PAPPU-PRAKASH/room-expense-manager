import 'package:firebase_auth/firebase_auth.dart';

import '../models/balance_model.dart';
import '../models/expense_model.dart';
import 'expense_service.dart';
import 'member_service.dart';

class BalanceService {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _memberService = MemberService();

  /// Calculates the share amount for a specific member for a given expense.
  /// This is the single source of truth for all share calculations.
  static double calculateMemberShare(ExpenseModel expense, String memberId, int totalMembers) {
    // Check if member is in split list
    if (!expense.splitBetween.contains(memberId)) {
      return 0.0;
    }

    switch (expense.splitType) {
      case 'equal':
        final membersCount = expense.splitBetween.isNotEmpty
            ? expense.splitBetween.length
            : totalMembers;
        return membersCount > 0 ? expense.amount / membersCount : 0.0;
      
      case 'exact':
        if (expense.splitDetails != null) {
          return expense.splitDetails![memberId] ?? 0.0;
        }
        return 0.0;
      
      case 'percentage':
        if (expense.splitDetails != null) {
          final percentage = expense.splitDetails![memberId] ?? 0.0;
          return (expense.amount * percentage) / 100.0;
        }
        return 0.0;
      
      default:
        // Fallback to equal split for unknown types
        final membersCount = expense.splitBetween.isNotEmpty
            ? expense.splitBetween.length
            : totalMembers;
        return membersCount > 0 ? expense.amount / membersCount : 0.0;
    }
  }

  Stream<BalanceSummary> streamBalanceSummary(String roomId) async* {
    await for (final expenses in _expenseService.streamRoomExpenses(roomId)) {
      final members = await _memberService.getRoomMembers(roomId);
      final currentUser = FirebaseAuth.instance.currentUser;
      final currentUserId = currentUser?.uid ?? '';

      final totalExpense = expenses.fold<double>(0.0, (sum, expense) => sum + expense.amount);

      final memberPaidMap = <String, double>{};
      final memberShareMap = <String, double>{};

      for (final member in members) {
        memberPaidMap[member.memberId] = 0.0;
        memberShareMap[member.memberId] = 0.0;
      }

      for (final expense in expenses) {
        final paidById = expense.paidBy;
        memberPaidMap[paidById] = (memberPaidMap[paidById] ?? 0.0) + expense.amount;

        // Calculate shares using the centralized helper method
        if (expense.splitType == 'equal') {
          final splitMembers = expense.splitBetween.isNotEmpty
              ? expense.splitBetween
              : members.map((m) => m.memberId).toList();

          for (final memberId in splitMembers) {
            final share = calculateMemberShare(expense, memberId, members.length);
            memberShareMap[memberId] = (memberShareMap[memberId] ?? 0.0) + share;
          }
        } else if (expense.splitType == 'exact' && expense.splitDetails != null) {
          // Use exact amounts from splitDetails
          for (final entry in expense.splitDetails!.entries) {
            final memberId = entry.key;
            final amount = entry.value;
            memberShareMap[memberId] = (memberShareMap[memberId] ?? 0.0) + amount;
          }
        } else if (expense.splitType == 'percentage' && expense.splitDetails != null) {
          // Calculate shares based on percentages
          for (final entry in expense.splitDetails!.entries) {
            final memberId = entry.key;
            final percentage = entry.value;
            final share = (expense.amount * percentage) / 100.0;
            memberShareMap[memberId] = (memberShareMap[memberId] ?? 0.0) + share;
          }
        } else {
          // Fallback to equal split for unknown types
          final splitMembers = expense.splitBetween.isNotEmpty
              ? expense.splitBetween
              : members.map((m) => m.memberId).toList();

          for (final memberId in splitMembers) {
            final share = calculateMemberShare(expense, memberId, members.length);
            memberShareMap[memberId] = (memberShareMap[memberId] ?? 0.0) + share;
          }
        }
      }

      final balances = members.map((member) {
        final paid = memberPaidMap[member.memberId] ?? 0.0;
        final share = memberShareMap[member.memberId] ?? 0.0;
        return BalanceModel(
          memberId: member.memberId,
          memberName: member.name,
          totalPaid: paid,
          totalShare: share,
          netBalance: paid - share,
        );
      }).toList();

      final currentUserBalance = balances
          .firstWhere(
            (element) => element.memberId == currentUserId,
            orElse: () => BalanceModel(
              memberId: currentUserId,
              memberName: '',
              totalPaid: 0.0,
              totalShare: 0.0,
              netBalance: 0.0,
            ),
          )
          .netBalance;

      yield BalanceSummary(
        totalExpense: totalExpense,
        balances: balances,
        currentUserBalance: currentUserBalance,
      );
    }
  }
}
