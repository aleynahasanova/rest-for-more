class Program {
  final String programId;
  final String userId;
  final DateTime startDate;
  final int currentDay;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Program({
    required this.programId,
    required this.userId,
    required this.startDate,
    this.currentDay = 1,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'program_id': programId,
      'user_id': userId,
      'start_date': startDate.toIso8601String(),
      'current_day': currentDay,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Program.fromMap(Map<String, Object?> map) {
    return Program(
      programId: map['program_id'] as String,
      userId: map['user_id'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      currentDay: map['current_day'] as int,
      status: map['status'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
