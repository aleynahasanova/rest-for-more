class User {
  final String userId;
  final String email;
  final String passwordHash;
  final String firstName;
  final String username;
  final bool marketingConsent;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.userId,
    required this.email,
    required this.passwordHash,
    required this.firstName,
    required this.username,
    this.marketingConsent = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'email': email,
      'password_hash': passwordHash,
      'first_name': firstName,
      'username': username,
      'marketing_consent': marketingConsent ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, Object?> map) {
    return User(
      userId: map['user_id'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      firstName: map['first_name'] as String,
      username: map['username'] as String,
      marketingConsent: (map['marketing_consent'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
