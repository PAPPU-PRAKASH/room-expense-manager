import 'package:flutter/material.dart';

import '../../models/payment_model.dart';
import '../../models/settlement_transaction_model.dart';
import '../../services/payment_service.dart';

class SettlementDetailsScreen extends StatefulWidget {
  final String roomId;
  final SettlementTransactionModel transaction;

  const SettlementDetailsScreen({super.key, required this.roomId, required this.transaction});

  @override
  State<SettlementDetailsScreen> createState() => _SettlementDetailsScreenState();
}

class _SettlementDetailsScreenState extends State<SettlementDetailsScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<String> _paymentMethods = ['UPI', 'Cash', 'Bank Transfer', 'Other'];
  final PaymentService _paymentService = PaymentService();

  String _selectedPaymentMethod = 'UPI';
  DateTime _paymentDate = DateTime.now();
  String? _amountError;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.transaction.amount.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) => '₹ ${value.toStringAsFixed(2)}';

  String get _transactionId {
    return widget.transaction.transactionId ??
        'settlement_${widget.transaction.fromMemberId}_to_${widget.transaction.toMemberId}';
  }

  Future<void> _selectPaymentDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null) {
      setState(() {
        _paymentDate = selectedDate;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handleSavePayment() async {
    final value = double.tryParse(_amountController.text.trim());
    final remainingAmount = widget.transaction.amount;

    setState(() {
      _amountError = null;
    });

    if (value == null) {
      setState(() {
        _amountError = 'Enter a valid amount.';
      });
      return;
    }

    if (value <= 0) {
      setState(() {
        _amountError = 'Amount must be greater than 0.';
      });
      return;
    }

    if (value > remainingAmount) {
      setState(() {
        _amountError = 'Amount cannot exceed remaining ₹${remainingAmount.toStringAsFixed(2)}.';
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildConfirmationRow('From Member', widget.transaction.fromMemberName),
              const SizedBox(height: 8),
              _buildConfirmationRow('To Member', widget.transaction.toMemberName),
              const SizedBox(height: 8),
              _buildConfirmationRow('Amount', _formatCurrency(value)),
              const SizedBox(height: 8),
              _buildConfirmationRow('Payment Method', _selectedPaymentMethod),
              const SizedBox(height: 8),
              _buildConfirmationRow('Payment Date', _paymentDate.toLocal().toString().split(' ')[0]),
              if (_notesController.text.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildConfirmationRow('Notes', _notesController.text.trim()),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _paymentService.recordPayment(
        roomId: widget.roomId,
        payment: PaymentModel(
          transactionId: _transactionId,
          fromMemberId: widget.transaction.fromMemberId,
          fromMemberName: widget.transaction.fromMemberName,
          toMemberId: widget.transaction.toMemberId,
          toMemberName: widget.transaction.toMemberName,
          amount: value,
          paymentMethod: _selectedPaymentMethod,
          paymentDate: _paymentDate,
          notes: _notesController.text.trim(),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment recorded successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      _showError('Unable to save payment. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settlement Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Settlement Suggestion',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildDetailRow('From Member', widget.transaction.fromMemberName),
              const SizedBox(height: 16),
              _buildDetailRow('To Member', widget.transaction.toMemberName),
              const SizedBox(height: 16),
              _buildDetailRow('Remaining Amount', _formatCurrency(widget.transaction.amount)),
              const SizedBox(height: 16),
              _buildDetailRow('Reason', widget.transaction.reason),
              const SizedBox(height: 32),
              const Text(
                'Mark as Paid',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
                  prefixText: '₹ ',
                  errorText: _amountError,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPaymentMethod,
                    isExpanded: true,
                    items: _paymentMethods
                        .map((method) => DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPaymentMethod = value;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectPaymentDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Payment Date',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(_paymentDate.toLocal().toString().split(' ')[0]),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleSavePayment,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Payment'),
                ),
              ),
            ],
          ),
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
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
