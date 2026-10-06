import 'package:sqflite/sqflite.dart';

class ProgramDayTable {
  static const String tableName = 'program_days';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        program_day_id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        scheduled_date TEXT NOT NULL,
        timezone TEXT NOT NULL,
        offered_at TEXT,
        opened_at TEXT,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (program_id)
          REFERENCES programs(program_id)
          ON DELETE CASCADE,

        UNIQUE (program_id, day_number)
      )
    ''');
  }
}
