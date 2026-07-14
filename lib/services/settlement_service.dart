import '../models/balance_model.dart';
import '../models/payment_model.dart';
import '../models/settlement_transaction_model.dart';

class SettlementService {
  List<SettlementTransactionModel> generateTransactions(
    BalanceSummary summary,
    List<PaymentModel> payments,
  ) {
    final adjustedBalances = summary.balances
        .map((balance) => _MemberBalance(balance.memberId, balance.memberName, balance.netBalance))
        .toList();

    final balanceLookup = {for (var balance in adjustedBalances) balance.memberId: balance};

    for (final payment in payments) {
      final payer = balanceLookup[payment.fromMemberId];
      final receiver = balanceLookup[payment.toMemberId];

      if (payer != null) {
        payer.netBalance += payment.amount;
      }
      if (receiver != null) {
        receiver.netBalance -= payment.amount;
      }
    }

    final payers = adjustedBalances
        .where((balance) => balance.netBalance < 0)
        .map((balance) => _MemberBalance(balance.memberId, balance.memberName, balance.netBalance))
        .toList();

    final receivers = adjustedBalances
        .where((balance) => balance.netBalance > 0)
        .map((balance) => _MemberBalance(balance.memberId, balance.memberName, balance.netBalance))
        .toList();

    payers.sort((a, b) => a.netBalance.compareTo(b.netBalance));
    receivers.sort((a, b) => b.netBalance.compareTo(a.netBalance));

    final transactions = <SettlementTransactionModel>[];
    var payerIndex = 0;
    var receiverIndex = 0;

    while (payerIndex < payers.length && receiverIndex < receivers.length) {
      final payer = payers[payerIndex];
      final receiver = receivers[receiverIndex];
      final amount = (payer.netBalance.abs() < receiver.netBalance)
          ? payer.netBalance.abs()
          : receiver.netBalance;

      transactions.add(SettlementTransactionModel(
        transactionId: _transactionIdFor(payer.memberId, receiver.memberId),
        fromMemberId: payer.memberId,
        fromMemberName: payer.memberName,
        toMemberId: receiver.memberId,
        toMemberName: receiver.memberName,
        amount: amount,
        reason: 'Generated automatically based on equal expense split.',
      ));

      payer.netBalance += amount;
      receiver.netBalance -= amount;

      if (payer.netBalance == 0) {
        payerIndex += 1;
      }
      if (receiver.netBalance == 0) {
        receiverIndex += 1;
      }
    }

    return transactions;
  }

  String _transactionIdFor(String fromMemberId, String toMemberId) {
    return 'settlement_${fromMemberId}_to_$toMemberId';
  }
}

class _MemberBalance {
  final String memberId;
  final String memberName;
  double netBalance;

  _MemberBalance(this.memberId, this.memberName, this.netBalance);
}
