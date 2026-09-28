import '../database/app_database.dart';
import '../database/tables/session_table.dart';
import '../database/tables/session_blocked_app_table.dart';
import '../models/session.dart';
import '../models/session_blocked_app.dart';

class SessionService {
  // CREATE
  Future<void> createSession(Session session) async {
    final database = await AppDatabase.database;

    await database.insert(SessionTable.tableName, session.toMap());
  }

  Future<void> createSessionBlockedApp(SessionBlockedApp blockedApp) async {
    final database = await AppDatabase.database;

    await database.insert(SessionBlockedAppTable.tableName, blockedApp.toMap());
  }

  // READ
  Future<List<Session>> getSessionsByModeId(String modeId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      SessionTable.tableName,
      where: 'mode_id = ?',
      whereArgs: [modeId],
      orderBy: 'created_at DESC',
    );

    return result.map((map) => Session.fromMap(map)).toList();
  }

  Future<Session?> getSessionById(String sessionId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      SessionTable.tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Session.fromMap(result.first);
  }

  Future<List<SessionBlockedApp>> getBlockedAppsBySessionId(
    String sessionId,
  ) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      SessionBlockedAppTable.tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'app_name ASC',
    );

    return result.map((map) => SessionBlockedApp.fromMap(map)).toList();
  }

  // UPDATE
  Future<void> updateSession(Session session) async {
    final database = await AppDatabase.database;

    await database.update(
      SessionTable.tableName,
      session.toMap(),
      where: 'session_id = ?',
      whereArgs: [session.sessionId],
    );
  }

  Future<void> updateSessionBlockedApp(SessionBlockedApp blockedApp) async {
    final database = await AppDatabase.database;

    await database.update(
      SessionBlockedAppTable.tableName,
      blockedApp.toMap(),
      where: 'session_blocked_app_id = ?',
      whereArgs: [blockedApp.sessionBlockedAppId],
    );
  }

  // DELETE
  Future<void> deleteSession(String sessionId) async {
    final database = await AppDatabase.database;

    await database.delete(
      SessionTable.tableName,
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSessionBlockedApp(String sessionBlockedAppId) async {
    final database = await AppDatabase.database;

    await database.delete(
      SessionBlockedAppTable.tableName,
      where: 'session_blocked_app_id = ?',
      whereArgs: [sessionBlockedAppId],
    );
  }
}
