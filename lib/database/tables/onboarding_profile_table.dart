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
        rhythm TEXT,
        rest_moments TEXT,
        feasible_step TEXT,
        preferred_activity TEXT,
        custom_activity TEXT,
        product_ownership TEXT,
        onboarding_step INTEGER,
        product_expectation TEXT NOT NULL DEFAULT 'UNKNOWN',
        product_issue TEXT,
        wants_support INTEGER NOT NULL DEFAULT 0,
        completed_at TEXT,
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
