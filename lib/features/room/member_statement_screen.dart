import 'package:flutter/material.dart';

import '../../models/ledger_entry_model.dart';
import '../../services/member_ledger_service.dart';

class MemberStatementScreen extends StatefulWidget {
  final String roomId;
  final String memberId;
  final String memberName;

  const MemberStatementScreen({
    super.key,
    required this.roomId,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<MemberStatementScreen> createState() => _MemberStatementScreenState();
}

class _MemberStatementScreenState extends State<MemberStatementScreen> {
  final MemberLedgerService _ledgerService = MemberLedgerService();
  late Future<MemberStatement> _statementFuture;

  @override
  void initState() {
    super.initState();
    _statementFuture = _ledgerService.generateMemberStatement(
      roomId: widget.roomId,
      memberId: widget.memberId,
    );
  }

  String _formatCurrency(double value) {
    return '₹ ${value.toStringAsFixed(2)}';
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Statement'),
      ),
      body: FutureBuilder<MemberStatement>(
        future: _statementFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 80,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          final statement = snapshot.data!;
          final entries = statement.entries;

          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'No expenses found for this member.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              // Header Card
              Container(
                width: double.infinity,
                color: statement.shouldReceive
                    ? Colors.green.shade50
                    : statement.shouldPay
                        ? Colors.red.shade50
                        : Colors.grey.shade100,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      widget.memberName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: statement.shouldReceive
                            ? Colors.green
                            : statement.shouldPay
                                ? Colors.red
                                : Colors.grey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statement.shouldReceive
                            ? 'To Receive: ${_formatCurrency(statement.netBalance.abs())}'
                            : statement.shouldPay
                                ? 'To Pay: ${_formatCurrency(statement.netBalance.abs())}'
                                : 'Settled Up',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Ledger List
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: entries.length,
                  separatorBuilder: (context, index) {
                    // Add date separator
                    if (index > 0) {
                      final currentDate = _formatDate(entries[index].expenseDate);
                      final previousDate = _formatDate(entries[index - 1].expenseDate);
                      if (currentDate != previousDate) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            currentDate,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        );
                      }
                    }
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    final isPositive = entry.balanceChange >= 0;
                    
                    // Determine if we need a date header
                    bool showDateHeader = false;
                    String dateHeaderText = '';
                    
                    if (index == 0) {
                      showDateHeader = true;
                      dateHeaderText = _formatDate(entry.expenseDate);
                    } else {
                      final currentDate = _formatDate(entry.expenseDate);
                      final previousDate = _formatDate(entries[index - 1].expenseDate);
                      if (currentDate != previousDate) {
                        showDateHeader = true;
                        dateHeaderText = currentDate;
                      }
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showDateHeader)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              dateHeaderText,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        Card(
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.expenseTitle,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(entry.totalAmount),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildDetailRow('Paid by', entry.paidByName),
                                const SizedBox(height: 4),
                                _buildDetailRow('Split type', entry.splitType),
                                const SizedBox(height: 4),
                                _buildDetailRow('Your share', _formatCurrency(entry.memberShare)),
                                const SizedBox(height: 4),
                                _buildDetailRow(
                                  'You paid',
                                  _formatCurrency(entry.memberPaid),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                                      color: isPositive ? Colors.green : Colors.red,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isPositive
                                          ? 'Receive: ${_formatCurrency(entry.balanceChange.abs())}'
                                          : 'Pay: ${_formatCurrency(entry.balanceChange.abs())}',
                                      style: TextStyle(
                                        color: isPositive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Running Balance',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _formatCurrency(entry.runningBalance),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: entry.runningBalance >= 0
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              // Footer Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Total Paid', _formatCurrency(statement.totalPaid)),
                    const SizedBox(height: 8),
                    _buildSummaryRow('Total Share', _formatCurrency(statement.totalShare)),
                    const SizedBox(height: 8),
                    _buildSummaryRow(
                      'Net Balance',
                      _formatCurrency(statement.netBalance),
                      isBold: true,
                      color: statement.netBalance >= 0 ? Colors.green : Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}
