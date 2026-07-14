import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<PaymentModel>> streamPayments(String roomId) {
    return _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<List<PaymentModel>> getPayments(String roomId) async {
    final snapshot = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('payments')
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<PaymentModel>> getPaymentsByTransaction(
    String roomId,
    String transactionId,
  ) async {
    final snapshot = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('payments')
        .where('transactionId', isEqualTo: transactionId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => PaymentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> recordPayment({
    required String roomId,
    required PaymentModel payment,
  }) async {
    final paymentRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('payments')
        .doc();

    final data = payment.toMap();
    data['paymentId'] = paymentRef.id;

    await paymentRef.set(data);
  }
}
