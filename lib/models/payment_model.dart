import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String? paymentId;
  final String transactionId;
  final String fromMemberId;
  final String fromMemberName;
  final String toMemberId;
  final String toMemberName;
  final double amount;
  final String paymentMethod;
  final DateTime paymentDate;
  final String notes;
  final String status;
  final DateTime? createdAt;

  PaymentModel({
    this.paymentId,
    required this.transactionId,
    required this.fromMemberId,
    required this.fromMemberName,
    required this.toMemberId,
    required this.toMemberName,
    required this.amount,
    required this.paymentMethod,
    required this.paymentDate,
    this.notes = '',
    this.status = 'completed',
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'transactionId': transactionId,
      'fromMemberId': fromMemberId,
      'fromMemberName': fromMemberName,
      'toMemberId': toMemberId,
      'toMemberName': toMemberName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'notes': notes,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map, String id) {
    final paymentDateValue = map['paymentDate'];
    final createdAtValue = map['createdAt'];

    return PaymentModel(
      paymentId: id,
      transactionId: map['transactionId'] ?? '',
      fromMemberId: map['fromMemberId'] ?? '',
      fromMemberName: map['fromMemberName'] ?? '',
      toMemberId: map['toMemberId'] ?? '',
      toMemberName: map['toMemberName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? '',
      paymentDate: paymentDateValue is Timestamp
          ? paymentDateValue.toDate()
          : DateTime.tryParse(paymentDateValue?.toString() ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'completed',
      createdAt: createdAtValue is Timestamp
          ? createdAtValue.toDate()
          : DateTime.tryParse(createdAtValue?.toString() ?? ''),
    );
  }
}
