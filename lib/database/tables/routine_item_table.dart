import 'package:sqflite/sqflite.dart';

class RoutineItemTable {
  static const String tableName = 'routine_items';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        routine_item_id TEXT PRIMARY KEY,
        routine_id TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        start_time TEXT,
        duration_minutes INTEGER,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_default INTEGER NOT NULL DEFAULT 0,

        created_at TEXT NOT NULL,
        updated_at TEXT,
        deleted_at TEXT,

        sync_status TEXT NOT NULL DEFAULT 'PENDING',

        FOREIGN KEY (routine_id)
          REFERENCES routines(routine_id)
          ON DELETE CASCADE
      )
    ''');
  }
}
