class UserModel {
  final String uid;
  final String phone;
  final String name;
  final String roomId;

  UserModel({
    required this.uid,
    required this.phone,
    required this.name,
    required this.roomId,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      roomId: map['roomId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'phone': phone,
      'name': name,
      'roomId': roomId,
    };
  }

  bool get hasProfile => name.trim().isNotEmpty;

  bool get hasRoom => roomId.trim().isNotEmpty;
}