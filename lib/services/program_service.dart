import '../database/app_database.dart';
import '../database/tables/program_table.dart';
import '../database/tables/program_day_table.dart';
import '../models/program.dart';
import '../models/program_day.dart';

class ProgramService {
  // CREATE

  Future<void> createProgram(Program program) async {
    final database = await AppDatabase.database;

    await database.insert(ProgramTable.tableName, program.toMap());
  }

  Future<void> createProgramDay(ProgramDay programDay) async {
    final database = await AppDatabase.database;

    await database.insert(ProgramDayTable.tableName, programDay.toMap());
  }

  // READ

  Future<List<Program>> getProgramsByUserId(String userId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ProgramTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return result.map((map) => Program.fromMap(map)).toList();
  }

  Future<Program?> getProgramById(String programId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ProgramTable.tableName,
      where: 'program_id = ?',
      whereArgs: [programId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Program.fromMap(result.first);
  }

  Future<Program?> getActiveProgramByUserId(String userId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ProgramTable.tableName,
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'ACTIVE'],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Program.fromMap(result.first);
  }

  Future<List<ProgramDay>> getProgramDays(String programId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ProgramDayTable.tableName,
      where: 'program_id = ?',
      whereArgs: [programId],
      orderBy: 'day_number ASC',
    );

    return result.map((map) => ProgramDay.fromMap(map)).toList();
  }

  Future<ProgramDay?> getProgramDayById(String programDayId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ProgramDayTable.tableName,
      where: 'program_day_id = ?',
      whereArgs: [programDayId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ProgramDay.fromMap(result.first);
  }

  Future<ProgramDay?> getProgramDayByNumber(
    String programId,
    int dayNumber,
  ) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ProgramDayTable.tableName,
      where: 'program_id = ? AND day_number = ?',
      whereArgs: [programId, dayNumber],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return ProgramDay.fromMap(result.first);
  }

  // UPDATE

  Future<void> updateProgram(Program program) async {
    final database = await AppDatabase.database;

    await database.update(
      ProgramTable.tableName,
      program.toMap(),
      where: 'program_id = ?',
      whereArgs: [program.programId],
    );
  }

  Future<void> updateProgramDay(ProgramDay programDay) async {
    final database = await AppDatabase.database;

    await database.update(
      ProgramDayTable.tableName,
      programDay.toMap(),
      where: 'program_day_id = ?',
      whereArgs: [programDay.programDayId],
    );
  }

  // DELETE

  Future<void> deleteProgram(String programId) async {
    final database = await AppDatabase.database;

    await database.delete(
      ProgramTable.tableName,
      where: 'program_id = ?',
      whereArgs: [programId],
    );
  }

  Future<void> deleteProgramDay(String programDayId) async {
    final database = await AppDatabase.database;

    await database.delete(
      ProgramDayTable.tableName,
      where: 'program_day_id = ?',
      whereArgs: [programDayId],
    );
  }
}
