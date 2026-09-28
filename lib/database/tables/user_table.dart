import 'package:sqflite/sqflite.dart';

class UserTable {
  static const String tableName = 'users';

  static Future<void> create(Database database) async {
    await database.execute('''
      CREATE TABLE $tableName (
        user_id TEXT PRIMARY KEY,
        email TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        first_name TEXT NOT NULL,
        username TEXT NOT NULL UNIQUE,
        marketing_consent INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');
  }
}
