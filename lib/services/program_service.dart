import '../database/app_database.dart';
import '../database/tables/program_table.dart';
import '../models/program.dart';

class ProgramService {
  // CREATE
  Future<void> createProgram(Program program) async {
    final database = await AppDatabase.database;

    await database.insert(ProgramTable.tableName, program.toMap());
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

  // DELETE
  Future<void> deleteProgram(String programId) async {
    final database = await AppDatabase.database;

    await database.delete(
      ProgramTable.tableName,
      where: 'program_id = ?',
      whereArgs: [programId],
    );
  }
}
