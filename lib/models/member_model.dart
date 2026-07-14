import 'package:cloud_firestore/cloud_firestore.dart';

class MemberModel {
  final String memberId;
  final String name;
  final String? phone;
  final String? uid;
  final String role;
  final bool joined;
  final DateTime? joinedAt;

  MemberModel({
    required this.memberId,
    required this.name,
    this.phone,
    this.uid,
    required this.role,
    this.joined = false,
    this.joinedAt,
  });

  Map<String, dynamic> toMap() {
    final data = <String, dynamic>{
      'name': name,
      'role': role,
      'joined': joined,
    };

    if (phone != null && phone!.isNotEmpty) {
      data['phone'] = phone;
    }

    if (uid != null && uid!.isNotEmpty) {
      data['uid'] = uid;
    }

    return data;
  }

  factory MemberModel.fromMap(
    Map<String, dynamic> map,
    String id,
  ) {
    return MemberModel(
      memberId: id,
      name: map['name'] ?? '',
      phone: map['phone'],
      uid: map['uid'],
      role: map['role'] ?? 'member',
      joined: map['joined'] == true,
      joinedAt: map['joinedAt'] != null
          ? (map['joinedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
