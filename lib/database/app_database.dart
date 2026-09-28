import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'tables/user_table.dart';
import 'tables/onboarding_profile_table.dart';

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
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDatabase,
    );
  }

  static Future<void> _createDatabase(Database database, int version) async {
    // We will create our tables here.
    await UserTable.create(database);
    await OnboardingProfileTable.create(database);
  }
}
