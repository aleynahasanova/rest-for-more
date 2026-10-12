import 'package:sqflite/sqflite.dart';

class SessionBlockedAppTable {
  static const String tableName = 'session_blocked_apps';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        session_blocked_app_id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        app_identifier TEXT NOT NULL,
        app_name TEXT NOT NULL,

        sync_status TEXT NOT NULL DEFAULT 'PENDING',

        FOREIGN KEY (session_id)
          REFERENCES sessions(session_id)
          ON DELETE CASCADE,

        UNIQUE (session_id, app_identifier)
      )
    ''');
  }
}
