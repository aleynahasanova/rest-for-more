import '../database/app_database.dart';
import '../database/tables/program_day_table.dart';
import '../database/tables/program_table.dart';
import '../models/onboarding_profile.dart';
import '../models/program.dart';
import '../models/program_status.dart';
import '../utils/id_generator.dart';
import 'plan_generator.dart';
import 'program_service.dart';

/// Starts the 14-day programme when onboarding is finished: makes the plan from
/// the answers and saves the programme and its 14 days in the database.
class ProgramStarter {
  ProgramStarter({
    ProgramService? programService,
    this.generator = const PlanGenerator(),
  }) : _programService = programService ?? ProgramService();

  final ProgramService _programService;
  final PlanGenerator generator;

  /// Makes the programme for the user of [profile], unless the user already
  /// has an active one. Returns true when a new programme was made.
  ///
  /// A programme that already exists is not replaced, so progress is never
  /// lost when someone opens the onboarding again to change an answer.
  /// TODO: decide with the team whether changed answers should update the plan.
  Future<bool> startProgramIfNone(OnboardingProfile profile) async {
    final existing =
        await _programService.getActiveProgramByUserId(profile.userId);

    if (existing != null) return false;

    final now = DateTime.now();
    final programId = IdGenerator.newId();

    // Day 1 is today.
    final startDate = DateTime(now.year, now.month, now.day);

    final program = Program(
      programId: programId,
      userId: profile.userId,
      startDate: startDate,
      currentDay: 1,
      status: ProgramStatus.active,
      createdAt: now.toUtc(),
    );

    final days = generator.generate(
      profile,
      programId: programId,
      startDate: startDate,
      // TODO: use the real IANA name (for example 'Europe/Amsterdam') with a
      // package like flutter_timezone. This is the short name of the phone's
      // time zone, for example 'CEST'.
      timeZoneId: now.timeZoneName,
      now: now,
    );

    // One transaction: the programme is saved with all 14 days or not at all.
    final database = await AppDatabase.database;

    await database.transaction((transaction) async {
      await transaction.insert(ProgramTable.tableName, program.toMap());

      for (final day in days) {
        await transaction.insert(ProgramDayTable.tableName, day.toMap());
      }
    });

    return true;
  }
}
