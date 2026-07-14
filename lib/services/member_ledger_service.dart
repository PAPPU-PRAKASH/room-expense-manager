import '../models/expense_model.dart';
import '../models/ledger_entry_model.dart';
import '../models/member_model.dart';
import 'balance_service.dart';
import 'expense_service.dart';
import 'member_service.dart';

class MemberLedgerService {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _memberService = MemberService();

  Future<MemberStatement> generateMemberStatement({
    required String roomId,
    required String memberId,
  }) async {
    final expenses = await _expenseService.getRoomExpenses(roomId);
    final members = await _memberService.getRoomMembers(roomId);
    
    final member = members.firstWhere(
      (m) => m.memberId == memberId,
      orElse: () => MemberModel(
        memberId: memberId,
        name: 'Unknown',
        role: 'member',
      ),
    );

    // Sort expenses chronologically
    expenses.sort((a, b) => a.expenseDate.compareTo(b.expenseDate));

    final ledgerEntries = <LedgerEntry>[];
    double totalPaid = 0.0;
    double totalShare = 0.0;
    double runningBalance = 0.0;

    for (final expense in expenses) {
      final memberPaid = expense.paidBy == memberId ? expense.amount : 0.0;
      // Use BalanceService's centralized calculation method
      final memberShare = BalanceService.calculateMemberShare(
        expense,
        memberId,
        members.length,
      );
      final balanceChange = memberPaid - memberShare;
      
      runningBalance += balanceChange;
      totalPaid += memberPaid;
      totalShare += memberShare;

      // Find payer name
      final payer = members.firstWhere(
        (m) => m.memberId == expense.paidBy,
        orElse: () => MemberModel(
          memberId: expense.paidBy,
          name: expense.paidBy,
          role: 'member',
        ),
      );

      ledgerEntries.add(LedgerEntry(
        expenseId: expense.expenseId,
        expenseTitle: expense.title,
        expenseDate: expense.expenseDate,
        totalAmount: expense.amount,
        paidBy: expense.paidBy,
        paidByName: payer.name,
        splitType: expense.splitType,
        memberShare: memberShare,
        memberPaid: memberPaid,
        balanceChange: balanceChange,
        runningBalance: runningBalance,
      ));
    }

    return MemberStatement(
      memberId: memberId,
      memberName: member.name,
      totalPaid: totalPaid,
      totalShare: totalShare,
      netBalance: runningBalance,
      entries: ledgerEntries,
    );
  }
}
