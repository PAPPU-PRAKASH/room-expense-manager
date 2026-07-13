import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/room_model.dart';
import 'firestore_service.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Create New Room
  Future<void> createRoom(RoomModel room) async {
    await _firestore.collection('rooms').doc(room.roomId).set({
      ...room.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestoreService.updateRoomId(
      uid: room.createdBy,
      roomId: room.roomId,
    );
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

    final data = roomDoc.data();

    final membersCount = (data['membersCount'] ?? 0) as int;
    final maxMembers = (data['maxMembers'] ?? 0) as int;

    if (membersCount >= maxMembers) {
      throw Exception("Room is full");
    }

    await roomDoc.reference.update({
      'membersCount': FieldValue.increment(1),
    });

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