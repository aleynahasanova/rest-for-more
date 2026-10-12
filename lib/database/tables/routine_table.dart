import 'package:sqflite/sqflite.dart';

class RoutineTable {
  static const String tableName = 'routines';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        routine_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        name TEXT NOT NULL,
        routine_type TEXT NOT NULL,

        created_at TEXT NOT NULL,
        updated_at TEXT,
        deleted_at TEXT,

        sync_status TEXT NOT NULL DEFAULT 'PENDING',

        FOREIGN KEY (user_id)
          REFERENCES users(user_id)
          ON DELETE CASCADE
      )
    ''');
  }
}
