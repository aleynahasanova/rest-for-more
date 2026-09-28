import 'package:sqflite/sqflite.dart';

class OnboardingProfileTable {
  static const String tableName = 'onboarding_profiles';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        onboarding_profile_id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL UNIQUE,
        age_group TEXT,
        main_goal TEXT,
        biggest_challenge TEXT,
        phone_use_in_bed TEXT,
        phone_free_target_minutes INTEGER,
        reminder_time TEXT,
        product_expectation TEXT NOT NULL,
        product_issue TEXT,
        wants_support INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT,

        FOREIGN KEY (user_id)
          REFERENCES users(user_id)
          ON DELETE CASCADE
      )
    ''');
  }
}
