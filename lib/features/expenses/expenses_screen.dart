import 'package:flutter/material.dart';

import '../../models/expense_model.dart';
import '../../models/member_model.dart';
import '../../services/expense_service.dart';
import '../../services/member_service.dart';
import '../home/add_expense_screen.dart';
import 'expense_details_screen.dart';

class ExpensesScreen extends StatefulWidget {
  final String roomId;

  const ExpensesScreen({super.key, required this.roomId});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpenseService _expenseService = ExpenseService();
  final MemberService _memberService = MemberService();
  late Future<List<MemberModel>> _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _memberService.getRoomMembers(widget.roomId);
  }

  void _retryMembers() {
    setState(() {
      _membersFuture = _memberService.getRoomMembers(widget.roomId);
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatAmount(double amount) {
    return '₹ ${amount.toStringAsFixed(2)}';
  }

  String _memberName(String memberId, List<MemberModel> members) {
    final member = members.firstWhere(
      (element) => element.memberId == memberId,
      orElse: () => MemberModel(
        memberId: memberId,
        name: memberId,
        phone: '',
        role: 'member',
      ),
    );
    return member.name.isNotEmpty ? member.name : memberId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
      ),
      body: FutureBuilder<List<MemberModel>>(
        future: _membersFuture,
        builder: (context, memberSnapshot) {
          if (memberSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (memberSnapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Unable to load expenses.',
                      style: TextStyle(fontSize: 18),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retryMembers,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final members = memberSnapshot.data ?? [];

          return StreamBuilder<List<ExpenseModel>>(
            stream: _expenseService.streamRoomExpenses(widget.roomId),
            builder: (context, expenseSnapshot) {
              if (expenseSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (expenseSnapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Unable to load expenses.',
                          style: TextStyle(fontSize: 18),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final expenses = expenseSnapshot.data ?? [];

              if (expenses.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '📄 No expenses yet.',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddExpenseScreen(
                                  roomId: widget.roomId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Add First Expense'),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: expenses.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final expense = expenses[index];
                  final paidByName = _memberName(expense.paidBy, members);

                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ExpenseDetailsScreen(
                              expense: expense,
                              paidByName: paidByName,
                            ),
                          ),
                        );
                        if (result == true) {
                          setState(() {});
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text('Amount: ${_formatAmount(expense.amount)}'),
                            const SizedBox(height: 6),
                            Text('Paid By: $paidByName'),
                            const SizedBox(height: 6),
                            Text('Expense Date: ${_formatDate(expense.expenseDate)}'),
                            const SizedBox(height: 6),
                            Text('Split Type: ${expense.splitType}'),
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
