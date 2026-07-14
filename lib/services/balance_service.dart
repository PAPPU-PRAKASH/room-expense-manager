import 'package:firebase_auth/firebase_auth.dart';

import '../models/balance_model.dart';
import 'expense_service.dart';
import 'member_service.dart';

class BalanceService {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _memberService = MemberService();

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
        final membersCount = expense.splitBetween.isNotEmpty
            ? expense.splitBetween.length
            : members.length;

        final share = membersCount > 0 ? expense.amount / membersCount : 0.0;

        final paidById = expense.paidBy;
        memberPaidMap[paidById] = (memberPaidMap[paidById] ?? 0.0) + expense.amount;

        final splitMembers = expense.splitBetween.isNotEmpty
            ? expense.splitBetween
            : members.map((m) => m.memberId).toList();

        for (final memberId in splitMembers) {
          memberShareMap[memberId] = (memberShareMap[memberId] ?? 0.0) + share;
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
