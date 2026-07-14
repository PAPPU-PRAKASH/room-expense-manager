import '../models/balance_model.dart';
import '../models/payment_model.dart';
import '../models/settlement_transaction_model.dart';

class SettlementService {
  List<SettlementTransactionModel> generateTransactions(
    BalanceSummary summary,
    List<PaymentModel> payments,
  ) {
    // Build adjusted balances from expense-only summary
    final adjustedBalances = summary.balances
        .map((balance) => _MemberBalance(balance.memberId, balance.memberName, balance.netBalance))
        .toList();

    final balanceLookup = {for (var balance in adjustedBalances) balance.memberId: balance};

    // Apply payments (history) to adjusted balances
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

    // Round net balances to 2 decimal places to avoid floating point precision issues
    for (final b in adjustedBalances) {
      b.netBalance = double.parse(b.netBalance.toStringAsFixed(2));
    }

    // Separate payers and receivers after rounding
    final payers = adjustedBalances
      .where((balance) => balance.netBalance < 0.0)
      .map((balance) => _MemberBalance(balance.memberId, balance.memberName, balance.netBalance))
      .toList();

    final receivers = adjustedBalances
      .where((balance) => balance.netBalance > 0.0)
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
      final rawAmount = (payer.netBalance.abs() < receiver.netBalance)
          ? payer.netBalance.abs()
          : receiver.netBalance;

      // Round amount to 2 decimals and only add if strictly greater than 0.00
      final roundedAmount = double.parse(rawAmount.toStringAsFixed(2));
      if (roundedAmount > 0.0) {
        transactions.add(SettlementTransactionModel(
          transactionId: _transactionIdFor(payer.memberId, receiver.memberId),
          fromMemberId: payer.memberId,
          fromMemberName: payer.memberName,
          toMemberId: receiver.memberId,
          toMemberName: receiver.memberName,
          amount: roundedAmount,
          reason: 'Generated automatically based on equal expense split.',
        ));

        // Apply the rounded transfer
        payer.netBalance += roundedAmount;
        receiver.netBalance -= roundedAmount;
      } else {
        // Nothing to transfer; break to avoid infinite loop
        break;
      }

      // Advance indices when balances reach zero (after rounding)
      if (double.parse(payer.netBalance.toStringAsFixed(2)) == 0.0) {
        payerIndex += 1;
      }
      if (double.parse(receiver.netBalance.toStringAsFixed(2)) == 0.0) {
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
