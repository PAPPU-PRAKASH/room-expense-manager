import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create user only if it doesn't already exist
  Future<void> saveUser({
    required String uid,
    required String phone,
  }) async {
    final docRef = _firestore.collection('users').doc(uid);

    final doc = await docRef.get();

    if (!doc.exists) {
      await docRef.set({
        'uid': uid,
        'phone': phone,
        'name': '',
        'roomId': '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Get user document
  Future<DocumentSnapshot<Map<String, dynamic>>> getUser(
    String uid,
  ) {
    return _firestore.collection('users').doc(uid).get();
  }

  /// Update user name
  Future<void> updateUserName({
    required String uid,
    required String name,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'name': name,
    });
  }

  /// Update room id after creating/joining room
  Future<void> updateRoomId({
    required String uid,
    required String roomId,
  }) async {
    await _firestore.collection('users').doc(uid).update({
      'roomId': roomId,
    });
  }

  /// Check profile completion
  Future<bool> isProfileCompleted(String uid) async {
    final doc = await getUser(uid);

    if (!doc.exists) return false;

    final data = doc.data();

    if (data == null) return false;

    return (data['name'] ?? "").toString().trim().isNotEmpty;
  }

  /// Check if user already joined a room
  Future<bool> hasRoom(String uid) async {
    final doc = await getUser(uid);

    if (!doc.exists) return false;

    final data = doc.data();

    if (data == null) return false;

    return (data['roomId'] ?? "").toString().trim().isNotEmpty;
  }
}