class Routine {
  final String routineId;
  final String userId;
  final String name;
  final String routineType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Routine({
    required this.routineId,
    required this.userId,
    required this.name,
    required this.routineType,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'routine_id': routineId,
      'user_id': userId,
      'name': name,
      'routine_type': routineType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Routine.fromMap(Map<String, Object?> map) {
    return Routine(
      routineId: map['routine_id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      routineType: map['routine_type'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
