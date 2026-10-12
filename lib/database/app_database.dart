import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/user_table.dart';
import 'tables/onboarding_profile_table.dart';
import 'tables/routine_table.dart';
import 'tables/routine_item_table.dart';
import 'tables/mode_table.dart';
import 'tables/mode_blocked_app_table.dart';
import 'tables/session_table.dart';
import 'tables/session_blocked_app_table.dart';
import 'tables/program_table.dart';
import 'tables/program_day_table.dart';

class AppDatabase {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initializeDatabase();
    return _database!;
  }

  static Future<Database> _initializeDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'rest_for_more.db');

    return openDatabase(
      path,
      version: 3,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  static Future<void> _createDatabase(Database database, int version) async {
    await UserTable.create(database);
    await OnboardingProfileTable.create(database);
    await RoutineTable.create(database);
    await RoutineItemTable.create(database);
    await ModeTable.create(database);
    await ModeBlockedAppTable.create(database);
    await SessionTable.create(database);
    await SessionBlockedAppTable.create(database);
    await ProgramTable.create(database);
    await ProgramDayTable.create(database);
  }

  static Future<void> _upgradeDatabase(
    Database database,
    int oldVersion,
    int newVersion,
  ) async {
    // ==========================================
    // VERSION 1 -> VERSION 2
    // ==========================================
    if (oldVersion < 2) {
      // Add the new onboarding fields.
      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN rhythm TEXT',
      );

      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN rest_moments TEXT',
      );

      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN feasible_step TEXT',
      );

      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN preferred_activity TEXT',
      );

      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN custom_activity TEXT',
      );

      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN product_ownership TEXT',
      );

      await database.execute(
        'ALTER TABLE onboarding_profiles ADD COLUMN onboarding_step INTEGER',
      );

      // IMPORTANT:
      // Create program_days using the historical Version 2 schema.
      // Do not call ProgramDayTable.create() here because that now creates
      // the current Version 3 schema, which already contains sync_status.
      await database.execute('''
        CREATE TABLE program_days (
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

    // ==========================================
    // VERSION 2 -> VERSION 3
    // ==========================================
    if (oldVersion < 3) {
      // ------------------------------------------
      // Soft-delete / tombstone fields
      // ------------------------------------------

      await database.execute('ALTER TABLE routines ADD COLUMN deleted_at TEXT');

      await database.execute(
        'ALTER TABLE routine_items ADD COLUMN deleted_at TEXT',
      );

      await database.execute('ALTER TABLE modes ADD COLUMN deleted_at TEXT');

      await database.execute(
        'ALTER TABLE mode_blocked_apps ADD COLUMN deleted_at TEXT',
      );

      await database.execute('ALTER TABLE sessions ADD COLUMN deleted_at TEXT');

      // ------------------------------------------
      // Local synchronization tracking
      // ------------------------------------------

      await database.execute(
        "ALTER TABLE onboarding_profiles "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE routines "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE routine_items "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE modes "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE mode_blocked_apps "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE sessions "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE session_blocked_apps "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE programs "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await database.execute(
        "ALTER TABLE program_days "
        "ADD COLUMN sync_status TEXT NOT NULL DEFAULT 'PENDING'",
      );
    }
  }
}
