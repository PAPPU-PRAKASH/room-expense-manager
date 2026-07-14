import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/expense_model.dart';

class ExpenseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExpense(ExpenseModel expense) async {
    final collectionRef = _firestore
        .collection('rooms')
        .doc(expense.roomId)
        .collection('expenses');

    final docRef = collectionRef.doc(expense.expenseId);
    await docRef.set(expense.toMap());
  }

  Future<List<ExpenseModel>> getRoomExpenses(String roomId) async {
    final snapshot = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<ExpenseModel>> streamRoomExpenses(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> deleteExpense({
    required String roomId,
    required String expenseId,
  }) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    final collectionRef = _firestore
        .collection('rooms')
        .doc(expense.roomId)
        .collection('expenses');

    final docRef = collectionRef.doc(expense.expenseId);
    await docRef.update(expense.toMap());
  }
}
