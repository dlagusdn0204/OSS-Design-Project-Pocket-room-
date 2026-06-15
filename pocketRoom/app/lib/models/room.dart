
class Room {
  final String roomId;
  final String ownerId;
  final String name;
  final DateTime createdAt;

  const Room({
    required this.roomId,
    required this.ownerId,
    required this.name,
    required this.createdAt,
  });

  Room copyWith({String? name}) => Room(
        roomId: roomId,
        ownerId: ownerId,
        name: name ?? this.name,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'room_id': roomId,
        'owner_id': ownerId,
        'name': name,
        'created_at': createdAt.toIso8601String(),
      };

  factory Room.fromMap(Map<String, dynamic> map) => Room(
        roomId: map['room_id'] as String,
        ownerId: map['owner_id'] as String,
        name: map['name'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  String toString() => 'Room(roomId: $roomId, name: $name)';
}
