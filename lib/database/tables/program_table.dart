import 'package:sqflite/sqflite.dart';

class ProgramTable {
  static const String tableName = 'programs';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        program_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        start_date TEXT NOT NULL,
        current_day INTEGER NOT NULL DEFAULT 1,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        sync_status TEXT NOT NULL DEFAULT 'PENDING',

        FOREIGN KEY (user_id)
          REFERENCES users(user_id)
          ON DELETE CASCADE
      )
    ''');
  }
}
