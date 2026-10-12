/// Optional morning check: "Were you able to protect your chosen moment?"
/// A skipped check is stored as null, never as `no`.
enum ProtectedMomentAnswer { yes, partly, no }

/// Derived from the timestamps. There is deliberately no "failed" or "missed"
/// status: missed days stay readable and are not marked as failures.
enum DayStatus { notOffered, offered, opened, completed }

/// One day of the personal 14-day programme: the generated content and what
/// happened on that day. Offered, opened and completed are recorded separately
/// (App design, Flow B).
class ProgramDay {
  static const int totalDays = 14;

  final String programDayId;
  final String programId;
  final int dayNumber;

  // Content generated from the onboarding answers.
  final String title;

  /// Short paragraphs separated by a blank line. Use [paragraphs] to read them.
  final String body;
  final String primaryAction;

  /// Shown behind "Make it smaller".
  final String smallerAlternative;

  /// Shown behind "Why this step?".
  final String whyThisStep;

  /// True when today's main action serves the primary goal.
  /// At least 10 of the 14 days must have this (R01).
  final bool supportsPrimaryGoal;

  // Scheduling. Store local date and time zone (design doc, notification rule 12).
  /// Local calendar date as 'yyyy-MM-dd'.
  final String? scheduledDate;

  /// IANA time zone id at scheduling time, e.g. 'Europe/Amsterdam'.
  final String? timeZoneId;

  // Progress. Timestamps are stored in UTC.
  final DateTime? offeredAt;
  final DateTime? openedAt;
  final DateTime? completedAt;
  final bool usedSmallerAlternative;

  /// Self-reported experience, not measured data.
  final ProtectedMomentAnswer? protectedMoment;

  /// Self-reported 1-5, null = unknown.
  final int? restedRating;

  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProgramDay({
    required this.programDayId,
    required this.programId,
    required this.dayNumber,
    required this.title,
    required this.body,
    required this.primaryAction,
    required this.smallerAlternative,
    required this.whyThisStep,
    this.supportsPrimaryGoal = true,
    this.scheduledDate,
    this.timeZoneId,
    this.offeredAt,
    this.openedAt,
    this.completedAt,
    this.usedSmallerAlternative = false,
    this.protectedMoment,
    this.restedRating,
    required this.createdAt,
    this.updatedAt,
  });

  List<String> get paragraphs =>
      body.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

  /// Days 7 and 14 include a short review.
  bool get isReviewDay => dayNumber == 7 || dayNumber == 14;

  DayStatus get status {
    if (completedAt != null) return DayStatus.completed;
    if (openedAt != null) return DayStatus.opened;
    if (offeredAt != null) return DayStatus.offered;
    return DayStatus.notOffered;
  }

  // The mark* methods only record the first occurrence, so opening or
  // completing a day twice never overwrites earlier history.
  ProgramDay markOffered(
    DateTime now, {
    String? scheduledDate,
    String? timeZoneId,
  }) {
    return _copy(
      offeredAt: offeredAt ?? now.toUtc(),
      scheduledDate: this.scheduledDate ?? scheduledDate,
      timeZoneId: this.timeZoneId ?? timeZoneId,
      updatedAt: now.toUtc(),
    );
  }

  ProgramDay markOpened(DateTime now) {
    return _copy(
      openedAt: openedAt ?? now.toUtc(),
      updatedAt: now.toUtc(),
    );
  }

  ProgramDay markCompleted(DateTime now, {bool? usedSmallerAlternative}) {
    return _copy(
      completedAt: completedAt ?? now.toUtc(),
      usedSmallerAlternative:
          usedSmallerAlternative ?? this.usedSmallerAlternative,
      updatedAt: now.toUtc(),
    );
  }

  ProgramDay withMorningCheck(
    DateTime now, {
    ProtectedMomentAnswer? protectedMoment,
    int? restedRating,
  }) {
    return _copy(
      protectedMoment: protectedMoment ?? this.protectedMoment,
      restedRating: restedRating ?? this.restedRating,
      updatedAt: now.toUtc(),
    );
  }

  ProgramDay _copy({
    String? scheduledDate,
    String? timeZoneId,
    DateTime? offeredAt,
    DateTime? openedAt,
    DateTime? completedAt,
    bool? usedSmallerAlternative,
    ProtectedMomentAnswer? protectedMoment,
    int? restedRating,
    DateTime? updatedAt,
  }) {
    return ProgramDay(
      programDayId: programDayId,
      programId: programId,
      dayNumber: dayNumber,
      title: title,
      body: body,
      primaryAction: primaryAction,
      smallerAlternative: smallerAlternative,
      whyThisStep: whyThisStep,
      supportsPrimaryGoal: supportsPrimaryGoal,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      offeredAt: offeredAt ?? this.offeredAt,
      openedAt: openedAt ?? this.openedAt,
      completedAt: completedAt ?? this.completedAt,
      usedSmallerAlternative:
          usedSmallerAlternative ?? this.usedSmallerAlternative,
      protectedMoment: protectedMoment ?? this.protectedMoment,
      restedRating: restedRating ?? this.restedRating,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'program_day_id': programDayId,
      'program_id': programId,
      'day_number': dayNumber,
      'title': title,
      'content': body,
      'scheduled_date': scheduledDate ?? '',
      'timezone': timeZoneId ?? '',
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
      title: (map['title'] as String?) ?? '',
      body: (map['body'] ?? map['content'] ?? '') as String,
      primaryAction: (map['primary_action'] as String?) ?? '',
      smallerAlternative: (map['smaller_alternative'] as String?) ?? '',
      whyThisStep: (map['why_this_step'] as String?) ?? '',
      supportsPrimaryGoal: (map['supports_primary_goal'] as int?) == 1,
      scheduledDate: _optionalText(map['scheduled_date']),
      timeZoneId: _optionalText(map['time_zone_id'] ?? map['timezone']),
      offeredAt: _parseDate(map['offered_at']),
      openedAt: _parseDate(map['opened_at']),
      completedAt: _parseDate(map['completed_at']),
      usedSmallerAlternative: (map['used_smaller_alternative'] as int?) == 1,
      protectedMoment: _parseAnswer(map['protected_moment']),
      restedRating: map['rested_rating'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: _parseDate(map['updated_at']),
    );
  }

  static String? _optionalText(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return value;
  }

  static DateTime? _parseDate(Object? value) {
    return value is String ? DateTime.parse(value) : null;
  }

  static ProtectedMomentAnswer? _parseAnswer(Object? value) {
    for (final answer in ProtectedMomentAnswer.values) {
      if (answer.name == value) return answer;
    }
    return null;
  }
}
