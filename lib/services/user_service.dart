import '../database/app_database.dart';
import '../database/tables/user_table.dart';
import '../models/user.dart';

class UserService {
  // CREATE
  Future<void> createUser(User user) async {
    final database = await AppDatabase.database;

    await database.insert(UserTable.tableName, user.toMap());
  }

  // READ
  Future<User?> getUserById(String userId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      UserTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return User.fromMap(result.first);
  }

  // UPDATE
  Future<void> updateUser(User user) async {
    final database = await AppDatabase.database;

    await database.update(
      UserTable.tableName,
      user.toMap(),
      where: 'user_id = ?',
      whereArgs: [user.userId],
    );
  }

  // DELETE
  Future<void> deleteUser(String userId) async {
    final database = await AppDatabase.database;

    await database.delete(
      UserTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}
