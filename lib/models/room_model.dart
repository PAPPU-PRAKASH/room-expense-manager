class RoomModel {
  final String roomId;
  final String roomName;
  final String description;
  final String roomCode;
  final String createdBy;
  final int maxMembers;

  RoomModel({
    required this.roomId,
    required this.roomName,
    required this.description,
    required this.roomCode,
    required this.createdBy,
    required this.maxMembers,
  });

  Map<String, dynamic> toMap() {
    return {
      'roomId': roomId,
      'roomName': roomName,
      'description': description,
      'roomCode': roomCode,
      'createdBy': createdBy,
      'maxMembers': maxMembers,
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      roomId: map['roomId'] ?? '',
      roomName: map['roomName'] ?? '',
      description: map['description'] ?? '',
      roomCode: map['roomCode'] ?? '',
      createdBy: map['createdBy'] ?? '',
      maxMembers: map['maxMembers'] ?? 0,
    );
  }
}