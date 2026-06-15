
class User {
  final String id;
  final String passwordHash;
  final String email;
  final DateTime createdAt;

  const User({
    required this.id,
    required this.passwordHash,
    required this.email,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'password_hash': passwordHash,
        'email': email,
        'created_at': createdAt.toIso8601String(),
      };

  factory User.fromMap(Map<String, dynamic> map) => User(
        id: map['id'] as String,
        passwordHash: map['password_hash'] as String,
        email: map['email'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
      );

  @override
  String toString() => 'User(id: $id, email: $email)';
}
