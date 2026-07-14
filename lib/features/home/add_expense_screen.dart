import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/member_model.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../services/member_service.dart';

class AddExpenseScreen extends StatefulWidget {
  final String roomId;

  const AddExpenseScreen({super.key, required this.roomId});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _paidBy;
  String _splitType = 'equal';
  DateTime _expenseDate = DateTime.now();
  final List<String> _splitBetween = [];
  bool _isSaving = false;

  late Future<List<MemberModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = MemberService().getRoomMembers(widget.roomId);
    _dateController.text = _formatDate(_expenseDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_paidBy == null || _paidBy!.isEmpty) {
      _showMessage('Please select who paid the expense.');
      return;
    }

    if (_splitBetween.isEmpty) {
      _showMessage('Please select at least one member for split.');
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid amount greater than zero.');
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      _showMessage('Unable to determine the current user.');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final expenseId = FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .collection('expenses')
          .doc()
          .id;

      final expense = ExpenseModel(
        expenseId: expenseId,
        roomId: widget.roomId,
        title: _titleController.text.trim(),
        amount: amount,
        paidBy: _paidBy!,
        splitBetween: List.from(_splitBetween),
        expenseDate: _expenseDate,
        createdAt: null,
        createdBy: currentUser.uid,
        splitType: _splitType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      await ExpenseService().addExpense(expense);

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _toggleSplitBetween(String memberId) {
    setState(() {
      if (_splitBetween.contains(memberId)) {
        _splitBetween.remove(memberId);
      } else {
        _splitBetween.add(memberId);
      }
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickExpenseDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      setState(() {
        _expenseDate = selected;
        _dateController.text = _formatDate(selected);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
      ),
      body: FutureBuilder<List<MemberModel>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading members: ${snapshot.error}'),
            );
          }

          final members = snapshot.data ?? [];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Expense Title',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an expense title.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      final amount = double.tryParse(text);
                      if (amount == null || amount <= 0) {
                        return 'Enter an amount greater than zero.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Expense Date',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _pickExpenseDate,
                            ),
                          ),
                          onTap: _pickExpenseDate,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select an expense date.';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _splitType,
                    decoration: const InputDecoration(
                      labelText: 'Split Type',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'equal',
                        child: Text('Equal'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _splitType = value ?? 'equal';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _paidBy,
                    decoration: const InputDecoration(
                      labelText: 'Paid By',
                      border: OutlineInputBorder(),
                    ),
                    items: members
                        .map(
                          (member) => DropdownMenuItem(
                            value: member.memberId,
                            child: Text(member.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _paidBy = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Select the member who paid.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Split Between',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (members.isEmpty)
                    const Text('No members found for this room.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: members.map((member) {
                        final isSelected = _splitBetween.contains(member.memberId);
                        return FilterChip(
                          selected: isSelected,
                          label: Text(member.name),
                          onSelected: (_) => _toggleSplitBetween(member.memberId),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveExpense,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Expense'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
