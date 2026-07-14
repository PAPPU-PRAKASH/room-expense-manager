import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member_model.dart';
import '../models/room_model.dart';
import 'firestore_service.dart';
import 'member_service.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final MemberService _memberService = MemberService();

  /// Create New Room
  Future<void> createRoom(
    RoomModel room,
    String creatorName,
    String creatorPhone,
  ) async {
    await _firestore.collection('rooms').doc(room.roomId).set({
      ...room.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestoreService.updateRoomId(
      uid: room.createdBy,
      roomId: room.roomId,
    );

    final alreadyMember = await _memberService.isMemberExist(
      roomId: room.roomId,
      memberId: room.createdBy,
    );

    if (!alreadyMember) {
      final creator = MemberModel(
        memberId: room.createdBy,
        name: creatorName,
        phone: creatorPhone,
        role: 'admin',
      );

      await _memberService.addMemberToRoom(
        roomId: room.roomId,
        member: creator,
      );
    }
  }

  /// Join Existing Room
  Future<bool> joinRoom({
    required String uid,
    required String roomCode,
  }) async {
    final query = await _firestore
        .collection('rooms')
        .where('roomCode', isEqualTo: roomCode.trim().toUpperCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return false;
    }

    final roomDoc = query.docs.first;
    final roomId = roomDoc.id;

    final userModel = await _firestoreService.getUserModel(uid);
    if (userModel == null) {
      return false;
    }

    final alreadyMember = await _memberService.isMemberExist(
      roomId: roomId,
      memberId: uid,
    );

    if (!alreadyMember) {
      final member = MemberModel(
        memberId: uid,
        name: userModel.name,
        phone: userModel.phone,
        role: 'member',
      );

      await _memberService.addMemberToRoom(
        roomId: roomId,
        member: member,
      );
    }

    await _firestoreService.updateRoomId(
      uid: uid,
      roomId: roomId,
    );

    return true;
  }

  /// Get Room Data
  Future<DocumentSnapshot<Map<String, dynamic>>> getRoom(
    String roomId,
  ) {
    return _firestore.collection('rooms').doc(roomId).get();
  }
}
