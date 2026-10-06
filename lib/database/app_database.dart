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
      version: 2,
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

      // Add the new program_days table.
      await ProgramDayTable.create(database);
    }
  }
}
