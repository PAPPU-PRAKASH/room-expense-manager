import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import 'edit_expense_screen.dart';

class ExpenseDetailsScreen extends StatefulWidget {
  final ExpenseModel expense;
  final String paidByName;

  const ExpenseDetailsScreen({
    super.key,
    required this.expense,
    required this.paidByName,
  });

  @override
  State<ExpenseDetailsScreen> createState() => _ExpenseDetailsScreenState();
}

class _ExpenseDetailsScreenState extends State<ExpenseDetailsScreen> {
  final ExpenseService _expenseService = ExpenseService();
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Expense'),
          content: const Text('Are you sure you want to delete this expense? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      await _expenseService.deleteExpense(
        roomId: widget.expense.roomId,
        expenseId: widget.expense.expenseId,
      );

      if (!mounted) return;

      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully.')),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to delete expense. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditExpenseScreen(
          expense: widget.expense,
          paidByName: widget.paidByName,
        ),
      ),
    );

    if (result == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  bool _canEditExpense() {
    final currentUser = FirebaseAuth.instance.currentUser;
    return currentUser != null && currentUser.uid == widget.expense.createdBy;
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEditExpense();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Details'),
        actions: canEdit
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _isDeleting ? null : _handleEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: _isDeleting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete),
                  onPressed: _isDeleting ? null : _handleDelete,
                  tooltip: 'Delete',
                ),
              ]
            : null,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.expense.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Amount', _formatAmount(widget.expense.amount)),
            const SizedBox(height: 12),
            _buildDetailRow('Paid By', widget.paidByName),
            const SizedBox(height: 12),
            _buildDetailRow('Expense Date', _formatDate(widget.expense.expenseDate)),
            const SizedBox(height: 12),
            _buildDetailRow('Split Type', widget.expense.splitType),
            const SizedBox(height: 12),
            _buildDetailRow('Notes', widget.expense.notes?.isNotEmpty == true ? widget.expense.notes! : 'No notes'),
            const SizedBox(height: 12),
            _buildDetailRow('Created By', widget.expense.createdBy),
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
