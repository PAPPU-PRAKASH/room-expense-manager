import 'package:flutter/material.dart';

import '../../models/expense_model.dart';

class ExpenseDetailsScreen extends StatelessWidget {
  final ExpenseModel expense;
  final String paidByName;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    required this.paidByName,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              expense.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Amount', _formatAmount(expense.amount)),
            const SizedBox(height: 12),
            _buildDetailRow('Paid By', paidByName),
            const SizedBox(height: 12),
            _buildDetailRow('Expense Date', _formatDate(expense.expenseDate)),
            const SizedBox(height: 12),
            _buildDetailRow('Split Type', expense.splitType),
            const SizedBox(height: 12),
            _buildDetailRow('Notes', expense.notes?.isNotEmpty == true ? expense.notes! : 'No notes'),
            const SizedBox(height: 12),
            _buildDetailRow('Created By', expense.createdBy),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}
