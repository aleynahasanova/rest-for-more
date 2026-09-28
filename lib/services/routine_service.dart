import '../database/app_database.dart';
import '../database/tables/routine_table.dart';
import '../database/tables/routine_item_table.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';

class RoutineService {
  // CREATE
  Future<void> createRoutine(Routine routine) async {
    final database = await AppDatabase.database;

    await database.insert(RoutineTable.tableName, routine.toMap());
  }

  Future<void> createRoutineItem(RoutineItem item) async {
    final database = await AppDatabase.database;

    await database.insert(RoutineItemTable.tableName, item.toMap());
  }

  // READ
  Future<List<Routine>> getRoutinesByUserId(String userId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      RoutineTable.tableName,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    return result.map((map) => Routine.fromMap(map)).toList();
  }

  Future<Routine?> getRoutineById(String routineId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      RoutineTable.tableName,
      where: 'routine_id = ?',
      whereArgs: [routineId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Routine.fromMap(result.first);
  }

  Future<List<RoutineItem>> getRoutineItems(String routineId) async {
    final database = await AppDatabase.database;

    final result = await database.query(
      RoutineItemTable.tableName,
      where: 'routine_id = ?',
      whereArgs: [routineId],
      orderBy: 'sort_order ASC',
    );

    return result.map((map) => RoutineItem.fromMap(map)).toList();
  }

  // UPDATE
  Future<void> updateRoutine(Routine routine) async {
    final database = await AppDatabase.database;

    await database.update(
      RoutineTable.tableName,
      routine.toMap(),
      where: 'routine_id = ?',
      whereArgs: [routine.routineId],
    );
  }

  Future<void> updateRoutineItem(RoutineItem item) async {
    final database = await AppDatabase.database;

    await database.update(
      RoutineItemTable.tableName,
      item.toMap(),
      where: 'routine_item_id = ?',
      whereArgs: [item.routineItemId],
    );
  }

  // DELETE
  Future<void> deleteRoutine(String routineId) async {
    final database = await AppDatabase.database;

    await database.delete(
      RoutineTable.tableName,
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> deleteRoutineItem(String routineItemId) async {
    final database = await AppDatabase.database;

    await database.delete(
      RoutineItemTable.tableName,
      where: 'routine_item_id = ?',
      whereArgs: [routineItemId],
    );
  }
}
