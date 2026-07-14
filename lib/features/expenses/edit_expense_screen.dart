import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/member_model.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../services/member_service.dart';

class EditExpenseScreen extends StatefulWidget {
  final ExpenseModel expense;
  final String paidByName;

  const EditExpenseScreen({
    super.key,
    required this.expense,
    required this.paidByName,
  });

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  String? _paidBy;
  String _splitType = 'equal';
  DateTime _expenseDate = DateTime.now();
  final List<String> _splitBetween = [];
  final Map<String, TextEditingController> _splitControllers = {};
  bool _isSaving = false;

  late Future<List<MemberModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _membersFuture = MemberService().getRoomMembers(widget.expense.roomId);
  }

  void _initializeFields() {
    _titleController.text = widget.expense.title;
    _amountController.text = widget.expense.amount.toString();
    _notesController.text = widget.expense.notes ?? '';
    _expenseDate = widget.expense.expenseDate;
    _dateController.text = _formatDate(_expenseDate);
    _splitType = widget.expense.splitType;
    _paidBy = widget.expense.paidBy;
    _splitBetween.addAll(widget.expense.splitBetween);

    // Initialize split controllers for custom split types
    if (widget.expense.splitDetails != null) {
      for (final entry in widget.expense.splitDetails!.entries) {
        _splitControllers[entry.key] = TextEditingController(
          text: entry.value.toString(),
        );
      }
    } else {
      // Create empty controllers for all split members
      for (final memberId in _splitBetween) {
        _splitControllers[memberId] = TextEditingController();
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    _dateController.dispose();
    for (final controller in _splitControllers.values) {
      controller.dispose();
    }
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

    // Validate split details for custom split types
    if (_splitType != 'equal') {
      if (!_validateSplitDetails(amount)) {
        return;
      }
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
      // Build split details for custom split types
      Map<String, double>? splitDetails;
      if (_splitType != 'equal') {
        splitDetails = _buildSplitDetails(amount);
      }

      final updatedExpense = ExpenseModel(
        expenseId: widget.expense.expenseId,
        roomId: widget.expense.roomId,
        title: _titleController.text.trim(),
        amount: amount,
        paidBy: _paidBy!,
        splitBetween: List.from(_splitBetween),
        expenseDate: _expenseDate,
        createdAt: widget.expense.createdAt,
        createdBy: widget.expense.createdBy,
        splitType: _splitType,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        splitDetails: splitDetails,
      );

      await ExpenseService().updateExpense(updatedExpense);

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
        _splitControllers.remove(memberId);
      } else {
        _splitBetween.add(memberId);
        _splitControllers[memberId] = TextEditingController();
      }
    });
  }

  bool _validateSplitDetails(double totalAmount) {
    if (_splitType == 'exact') {
      double totalSplit = 0.0;
      for (final memberId in _splitBetween) {
        final value = double.tryParse(_splitControllers[memberId]?.text ?? '0.0') ?? 0.0;
        totalSplit += value;
      }
      if ((totalSplit - totalAmount).abs() > 0.01) {
        _showMessage('Split amounts must equal total expense (₹${totalAmount.toStringAsFixed(2)}). Current total: ₹${totalSplit.toStringAsFixed(2)}');
        return false;
      }
    } else if (_splitType == 'percentage') {
      double totalPercentage = 0.0;
      for (final memberId in _splitBetween) {
        final value = double.tryParse(_splitControllers[memberId]?.text ?? '0.0') ?? 0.0;
        totalPercentage += value;
      }
      if ((totalPercentage - 100.0).abs() > 0.01) {
        _showMessage('Percentages must equal 100%. Current total: ${totalPercentage.toStringAsFixed(1)}%');
        return false;
      }
    }
    return true;
  }

  Map<String, double> _buildSplitDetails(double totalAmount) {
    final splitDetails = <String, double>{};
    
    if (_splitType == 'exact') {
      for (final memberId in _splitBetween) {
        final value = double.tryParse(_splitControllers[memberId]?.text ?? '0.0') ?? 0.0;
        splitDetails[memberId] = value;
      }
    } else if (_splitType == 'percentage') {
      for (final memberId in _splitBetween) {
        final percentage = double.tryParse(_splitControllers[memberId]?.text ?? '0.0') ?? 0.0;
        splitDetails[memberId] = percentage;
      }
    }
    
    return splitDetails;
  }

  void _distributeEqualSplit() {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0 || _splitBetween.isEmpty) return;

    final equalAmount = amount / _splitBetween.length;
    for (final memberId in _splitBetween) {
      _splitControllers[memberId]?.text = equalAmount.toStringAsFixed(2);
    }
    setState(() {});
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
        title: const Text('Edit Expense'),
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
                      DropdownMenuItem(
                        value: 'exact',
                        child: Text('Exact Amounts'),
                      ),
                      DropdownMenuItem(
                        value: 'percentage',
                        child: Text('Percentage'),
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
                  if (_splitType != 'equal' && _splitBetween.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _splitType == 'exact' ? 'Split Amounts' : 'Split Percentages',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_splitType == 'exact')
                          TextButton(
                            onPressed: _distributeEqualSplit,
                            child: const Text('Distribute Equally'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ..._splitBetween.map((memberId) {
                      final member = members.firstWhere(
                        (m) => m.memberId == memberId,
                        orElse: () => MemberModel(
                          memberId: memberId,
                          name: memberId,
                          role: 'member',
                        ),
                      );
                      final controller = _splitControllers[memberId] ?? TextEditingController();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                member.name,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: controller,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: _splitType == 'exact' ? 'Amount (₹)' : 'Percentage (%)',
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (_splitType == 'percentage')
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Total must equal 100%',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
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
                              : const Text('Update Expense'),
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
