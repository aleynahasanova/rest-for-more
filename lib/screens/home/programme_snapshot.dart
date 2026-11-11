import '../../models/program_day.dart';

/// How a day of the programme stands, compared with today's date.
enum StepTiming { today, stillOpen, comingUp, unscheduled }

/// What the home screens need to know about the user's 14-day programme.
///
/// [days] is empty when the user has no programme yet.
class ProgrammeSnapshot {
  const ProgrammeSnapshot(this.days);

  final List<ProgramDay> days;

  bool get hasProgramme => days.isNotEmpty;

  int get doneCount => days.where((day) => day.completedAt != null).length;

  bool get allDone => hasProgramme && doneCount >= ProgramDay.totalDays;

  /// 'yyyy-MM-dd', the same text the plan generator saves.
  static String dateKey(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  StepTiming timingOf(ProgramDay day, DateTime now) {
    final key = day.scheduledDate;

    if (key == null || key.isEmpty) return StepTiming.unscheduled;

    final comparison = key.compareTo(dateKey(now));

    if (comparison == 0) return StepTiming.today;
    if (comparison < 0) return StepTiming.stillOpen;
    return StepTiming.comingUp;
  }

  /// The step to show first: today's step, then the earliest step that is
  /// still open, then the next one that is coming up. null when all are done.
  ProgramDay? nextStep(DateTime now) {
    ProgramDay? today;
    ProgramDay? stillOpen;
    ProgramDay? other;

    for (final day in days) {
      if (day.completedAt != null) continue;

      switch (timingOf(day, now)) {
        case StepTiming.today:
          today ??= day;
        case StepTiming.stillOpen:
          stillOpen ??= day;
        case StepTiming.comingUp:
        case StepTiming.unscheduled:
          other ??= day;
      }
    }

    return today ?? stillOpen ?? other;
  }
}
