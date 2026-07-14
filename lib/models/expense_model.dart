import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String expenseId;
  final String roomId;
  final String title;
  final double amount;
  final String paidBy;
  final List<String> splitBetween;
  final DateTime expenseDate;
  final DateTime? createdAt;
  final String createdBy;
  final String splitType;
  final String? notes;

  ExpenseModel({
    required this.expenseId,
    required this.roomId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitBetween,
    required this.expenseDate,
    this.createdAt,
    required this.createdBy,
    this.splitType = 'equal',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'roomId': roomId,
      'title': title,
      'amount': amount,
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'createdBy': createdBy,
      'splitType': splitType,
    };

    if (notes != null && notes!.isNotEmpty) {
      data['notes'] = notes;
    }

    data['createdAt'] = createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp();

    return data;
  }

  factory ExpenseModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return ExpenseModel(
      expenseId: id,
      roomId: map['roomId'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] is num) ? (map['amount'] as num).toDouble() : 0.0,
      paidBy: map['paidBy'] ?? '',
      splitBetween: map['splitBetween'] != null
          ? List<String>.from(map['splitBetween'] as List)
          : <String>[],
      expenseDate: map['expenseDate'] is Timestamp
          ? (map['expenseDate'] as Timestamp).toDate()
          : DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      createdBy: map['createdBy'] ?? '',
      splitType: map['splitType'] ?? 'equal',
      notes: map['notes'],
    );
  }
}
