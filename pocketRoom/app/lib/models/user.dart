// 사용자 정보 모델 — 회원가입/로그인에 사용됩니다

class User {
  final String id;           // 사용자 ID (아이디)
  final String passwordHash; // SHA-256 해시된 비밀번호 (평문 절대 저장 금지)
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.passwordHash,
    required this.email,
    required this.createdAt,
  });

  // SQLite 저장용: 객체 → Map
  Map<String, dynamic> toMap() => {
        'id': id,
        'password_hash': passwordHash,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };

  // SQLite 조회용: Map → 객체
  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as String,
        passwordHash: map['password_hash'] as String,
        email: map['email'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  String toString() => 'User(id: $id, email: $email)';
}
