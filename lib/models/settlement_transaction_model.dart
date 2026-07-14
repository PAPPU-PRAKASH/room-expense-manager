class SettlementTransactionModel {
  final String? transactionId;
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final double amount;
  final String reason;
  final String status;
  final DateTime? createdAt;

  SettlementTransactionModel({
    this.transactionId,
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
    required this.reason,
    this.status = 'pending',
    this.createdAt,
  });
}
