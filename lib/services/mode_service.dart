import '../database/app_database.dart';
import '../database/tables/mode_table.dart';
import '../database/tables/mode_blocked_app_table.dart';
import '../models/mode.dart';
import '../models/mode_blocked_app.dart';

class ModeService {
  // CREATE
  Future<void> createMode(Mode mode) async {
    final database = await AppDatabase.database;

    await database.insert(ModeTable.tableName, mode.toMap());
  }

  Future<void> createModeBlockedApp(ModeBlockedApp blockedApp) async {
    final database = await AppDatabase.database;

    await database.insert(ModeBlockedAppTable.tableName, blockedApp.toMap());
  }

  // READ
  Future<List<Mode>> getModesByUserId(String userId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ModeTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    return result.map((map) => Mode.fromMap(map)).toList();
  }

  Future<Mode?> getModeById(String modeId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ModeTable.tableName,
      where: 'mode_id = ?',
      whereArgs: [modeId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Mode.fromMap(result.first);
  }

  Future<List<ModeBlockedApp>> getBlockedAppsByModeId(String modeId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      ModeBlockedAppTable.tableName,
      where: 'mode_id = ?',
      whereArgs: [modeId],
      orderBy: 'app_name ASC',
    );

    return result.map((map) => ModeBlockedApp.fromMap(map)).toList();
  }

  // UPDATE
  Future<void> updateMode(Mode mode) async {
    final database = await AppDatabase.database;

    await database.update(
      ModeTable.tableName,
      mode.toMap(),
      where: 'mode_id = ?',
      whereArgs: [mode.modeId],
    );
  }

  Future<void> updateModeBlockedApp(ModeBlockedApp blockedApp) async {
    final database = await AppDatabase.database;

    await database.update(
      ModeBlockedAppTable.tableName,
      blockedApp.toMap(),
      where: 'mode_blocked_app_id = ?',
      whereArgs: [blockedApp.modeBlockedAppId],
    );
  }

  // DELETE
  Future<void> deleteMode(String modeId) async {
    final database = await AppDatabase.database;

    await database.delete(
      ModeTable.tableName,
      where: 'mode_id = ?',
      whereArgs: [modeId],
    );
  }

  Future<void> deleteModeBlockedApp(String modeBlockedAppId) async {
    final database = await AppDatabase.database;

    await database.delete(
      ModeBlockedAppTable.tableName,
      where: 'mode_blocked_app_id = ?',
      whereArgs: [modeBlockedAppId],
    );
  }
}
