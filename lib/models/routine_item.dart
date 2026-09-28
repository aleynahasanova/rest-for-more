class RoutineItem {
  final String routineItemId;
  final String routineId;
  final String title;
  final String? description;
  final String? startTime;
  final int? durationMinutes;
  final int sortOrder;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const RoutineItem({
    required this.routineItemId,
    required this.routineId,
    required this.title,
    this.description,
    this.startTime,
    this.durationMinutes,
    this.sortOrder = 0,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'routine_item_id': routineItemId,
      'routine_id': routineId,
      'title': title,
      'description': description,
      'start_time': startTime,
      'duration_minutes': durationMinutes,
      'sort_order': sortOrder,
      'is_default': isDefault ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory RoutineItem.fromMap(Map<String, Object?> map) {
    return RoutineItem(
      routineItemId: map['routine_item_id'] as String,
      routineId: map['routine_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      startTime: map['start_time'] as String?,
      durationMinutes: map['duration_minutes'] as int?,
      sortOrder: map['sort_order'] as int,
      isDefault: (map['is_default'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
