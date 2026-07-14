import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_model.dart';

class MemberService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addMemberToRoom({
    required String roomId,
    required MemberModel member,
  }) async {
    final collectionRef = _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members');

    final memberRef = member.memberId.isNotEmpty
        ? collectionRef.doc(member.memberId)
        : collectionRef.doc();

    await memberRef.set({
      ...member.toMap(),
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<bool> isMemberExist({
    required String roomId,
    required String memberId,
  }) async {
    final doc = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(memberId)
        .get();

    return doc.exists;
  }

  Future<QueryDocumentSnapshot<Map<String, dynamic>>?>
      findMemberByPhone({
    required String roomId,
    required String phone,
  }) async {
    final normalizedPhone = phone.trim();
    if (normalizedPhone.isEmpty) {
      return null;
    }

    final query = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .where('phone', isEqualTo: normalizedPhone)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }

    return query.docs.first;
  }

  Future<void> claimMember({
    required String roomId,
    required String memberId,
    required String uid,
  }) async {
    await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .doc(memberId)
        .update({
      'uid': uid,
      'joined': true,
      'joinedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<MemberModel>> getRoomMembers(String roomId) async {
    final snapshot = await _firestore
        .collection('rooms')
        .doc(roomId)
        .collection('members')
        .orderBy('joinedAt', descending: false)
        .get();

    return snapshot.docs
        .map((doc) => MemberModel.fromMap(doc.data(), doc.id))
        .toList();
  }
}
