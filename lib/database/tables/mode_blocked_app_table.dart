import 'package:sqflite/sqflite.dart';

class ModeBlockedAppTable {
  static const String tableName = 'mode_blocked_apps';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        mode_blocked_app_id TEXT PRIMARY KEY,
        mode_id TEXT NOT NULL,
        app_identifier TEXT NOT NULL,
        app_name TEXT NOT NULL,
        created_at TEXT NOT NULL,

        FOREIGN KEY (mode_id)
          REFERENCES modes(mode_id)
          ON DELETE CASCADE,

        UNIQUE (mode_id, app_identifier)
      )
    ''');
  }
}
