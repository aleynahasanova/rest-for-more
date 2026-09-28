import 'package:sqflite/sqflite.dart';

class SessionTable {
  static const String tableName = 'sessions';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        session_id TEXT PRIMARY KEY,
        mode_id TEXT NOT NULL,
        status TEXT NOT NULL,
        planned_duration_seconds INTEGER NOT NULL,
        remaining_duration_seconds INTEGER,
        started_at TEXT,
        paused_at TEXT,
        ended_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (mode_id)
          REFERENCES modes(mode_id)
          ON DELETE CASCADE
      )
    ''');
  }
}
