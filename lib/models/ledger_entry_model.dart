class LedgerEntry {
  final String expenseId;
  final String expenseTitle;
  final DateTime expenseDate;
  final double totalAmount;
  final String paidBy;
  final String paidByName;
  final String splitType;
  final double memberShare;
  final double memberPaid;
  final double balanceChange;
  final double runningBalance;

  LedgerEntry({
    required this.expenseId,
    required this.expenseTitle,
    required this.expenseDate,
    required this.totalAmount,
    required this.paidBy,
    required this.paidByName,
    required this.splitType,
    required this.memberShare,
    required this.memberPaid,
    required this.balanceChange,
    required this.runningBalance,
  });
}

class MemberStatement {
  final String memberId;
  final String memberName;
  final double totalPaid;
  final double totalShare;
  final double netBalance;
  final List<LedgerEntry> entries;

  MemberStatement({
    required this.memberId,
    required this.memberName,
    required this.totalPaid,
    required this.totalShare,
    required this.netBalance,
    required this.entries,
  });

  bool get shouldReceive => netBalance > 0;
  bool get shouldPay => netBalance < 0;
  bool get isSettled => netBalance == 0;
}
