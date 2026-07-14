import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/balance_model.dart';
import '../../models/payment_model.dart';
import '../../models/settlement_transaction_model.dart';
import '../../services/balance_service.dart';
import '../../services/payment_service.dart';
import '../../services/settlement_service.dart';
import 'settlement_details_screen.dart';

class SettlementScreen extends StatefulWidget {
  final String roomId;

  const SettlementScreen({super.key, required this.roomId});

  @override
  State<SettlementScreen> createState() => _SettlementScreenState();
}

class _SettlementScreenState extends State<SettlementScreen> {
  final BalanceService _balanceService = BalanceService();
  final PaymentService _paymentService = PaymentService();
  final SettlementService _settlementService = SettlementService();

  void _retry() {
    setState(() {});
  }

  String _formatCurrency(double value) => '₹ ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    if (widget.roomId.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Settlement')),
        body: const Center(
          child: Text(
            'Room information is unavailable.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settlement')),
      body: StreamBuilder<List<PaymentModel>>(
        stream: _paymentService.streamPayments(widget.roomId),
        builder: (context, paymentsSnapshot) {
          if (paymentsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (paymentsSnapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Unable to load payments.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            );
          }

          final payments = paymentsSnapshot.data ?? [];

          return StreamBuilder<BalanceSummary>(
            stream: _balanceService.streamBalanceSummary(widget.roomId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Unable to load settlements.',
                        style: TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              final data = snapshot.data;
              if (data == null) {
                return const Center(
                  child: Text('Unable to load settlements.'),
                );
              }

              final List<SettlementTransactionModel> transactionSuggestions =
                  _settlementService.generateTransactions(data, payments);
              final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

              if (transactionSuggestions.isEmpty) {
                return const Center(
                  child: Text(
                    '🎉 Everyone is Settled Up',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: transactionSuggestions.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final transaction = transactionSuggestions[index];
                  final isCurrentUserPayer = transaction.fromMemberId == currentUserId;
                  final cardColor = isCurrentUserPayer ? Colors.red.shade50 : Colors.green.shade50;
                  final borderColor = isCurrentUserPayer ? Colors.red : Colors.green;
                  final titleText = isCurrentUserPayer
                      ? '💸 Pay ${_formatCurrency(transaction.amount)} to ${transaction.toMemberName}'
                      : '💰 Receive ${_formatCurrency(transaction.amount)} from ${transaction.fromMemberName}';
                  final subtitleText = '${transaction.fromMemberName} → ${transaction.toMemberName}';

                  return Card(
                    color: cardColor,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(color: borderColor.withAlpha((0.4 * 255).round()), width: 1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SettlementDetailsScreen(
                              transaction: transaction,
                              roomId: widget.roomId,
                            ),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleText,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subtitleText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatCurrency(transaction.amount),
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
