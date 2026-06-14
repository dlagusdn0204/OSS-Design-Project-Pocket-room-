// 방(거주지) 정보 모델 — 사용자는 여러 개의 방을 등록할 수 있습니다

class Room {
  final String roomId;
  final String ownerId;  // User.id 참조
  final String name;     // 방 이름 (예: "서울 자취방")
  final DateTime createdAt;

  const Room({
    required this.roomId,
    required this.ownerId,
    required this.name,
    required this.createdAt,
  });

  // 이름만 바꾼 복사본 반환 (불변 객체 패턴)
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
