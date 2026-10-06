import 'package:sqflite/sqflite.dart';

class ProgramDayTable {
  static const String tableName = 'program_days';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        program_day_id TEXT PRIMARY KEY,
        program_id TEXT NOT NULL,
        day_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        primary_action TEXT NOT NULL,
        smaller_alternative TEXT NOT NULL,
        why_this_step TEXT NOT NULL,
        supports_primary_goal INTEGER NOT NULL DEFAULT 1,
        scheduled_date TEXT,
        time_zone_id TEXT,
        offered_at TEXT,
        opened_at TEXT,
        completed_at TEXT,
        used_smaller_alternative INTEGER NOT NULL DEFAULT 0,
        protected_moment TEXT,
        rested_rating INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        UNIQUE (program_id, day_number),

        FOREIGN KEY (program_id)
          REFERENCES programs(program_id)
          ON DELETE CASCADE
      )
    ''');
  }
}
