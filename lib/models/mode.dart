class Mode {
  final String modeId;
  final String userId;
  final String name;
  final String modeType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Mode({
    required this.modeId,
    required this.userId,
    required this.name,
    required this.modeType,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'mode_id': modeId,
      'user_id': userId,
      'name': name,
      'mode_type': modeType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Mode.fromMap(Map<String, Object?> map) {
    return Mode(
      modeId: map['mode_id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      modeType: map['mode_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
