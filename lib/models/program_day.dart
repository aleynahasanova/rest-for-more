class ProgramDay {
  final String programDayId;
  final String programId;
  final int dayNumber;
  final String? title;
  final String content;
  final String scheduledDate;
  final String timezone;
  final DateTime? offeredAt;
  final DateTime? openedAt;
  final DateTime? completedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProgramDay({
    required this.programDayId,
    required this.programId,
    required this.dayNumber,
    this.title,
    required this.content,
    required this.scheduledDate,
    required this.timezone,
    this.offeredAt,
    this.openedAt,
    this.completedAt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'program_day_id': programDayId,
      'program_id': programId,
      'day_number': dayNumber,
      'title': title,
      'content': content,
      'scheduled_date': scheduledDate,
      'timezone': timezone,
      'offered_at': offeredAt?.toIso8601String(),
      'opened_at': openedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory ProgramDay.fromMap(Map<String, Object?> map) {
    return ProgramDay(
      programDayId: map['program_day_id'] as String,
      programId: map['program_id'] as String,
      dayNumber: map['day_number'] as int,
      title: map['title'] as String?,
      content: map['content'] as String,
      scheduledDate: map['scheduled_date'] as String,
      timezone: map['timezone'] as String,
      offeredAt: map['offered_at'] != null
          ? DateTime.parse(map['offered_at'] as String)
          : null,
      openedAt: map['opened_at'] != null
          ? DateTime.parse(map['opened_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
