class Session {
  final String sessionId;
  final String modeId;
  final String status;
  final int plannedDurationSeconds;
  final int? remainingDurationSeconds;
  final DateTime? startedAt;
  final DateTime? pausedAt;
  final DateTime? endedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Session({
    required this.sessionId,
    required this.modeId,
    required this.status,
    required this.plannedDurationSeconds,
    this.remainingDurationSeconds,
    this.startedAt,
    this.pausedAt,
    this.endedAt,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, Object?> toMap() {
    return {
      'session_id': sessionId,
      'mode_id': modeId,
      'status': status,
      'planned_duration_seconds': plannedDurationSeconds,
      'remaining_duration_seconds': remainingDurationSeconds,
      'started_at': startedAt?.toIso8601String(),
      'paused_at': pausedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory Session.fromMap(Map<String, Object?> map) {
    return Session(
      sessionId: map['session_id'] as String,
      modeId: map['mode_id'] as String,
      status: map['status'] as String,
      plannedDurationSeconds: map['planned_duration_seconds'] as int,
      remainingDurationSeconds: map['remaining_duration_seconds'] as int?,
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      pausedAt: map['paused_at'] != null
          ? DateTime.parse(map['paused_at'] as String)
          : null,
      endedAt: map['ended_at'] != null
          ? DateTime.parse(map['ended_at'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }
}
