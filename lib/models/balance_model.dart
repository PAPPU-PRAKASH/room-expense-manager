class BalanceModel {
  final String memberId;
  final String memberName;
  final double totalPaid;
  final double totalShare;
  final double netBalance;
  final bool isSettled;

  BalanceModel({
    required this.memberId,
    required this.memberName,
    required this.totalPaid,
    required this.totalShare,
    required this.netBalance,
    this.isSettled = false,
  });
}

class BalanceSummary {
  final double totalExpense;
  final List<BalanceModel> balances;
  final double currentUserBalance;

  BalanceSummary({
    required this.totalExpense,
    required this.balances,
    required this.currentUserBalance,
  });
}
