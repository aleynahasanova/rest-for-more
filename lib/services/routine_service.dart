import 'dart:math';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../database/tables/routine_table.dart';
import '../database/tables/routine_item_table.dart';
import '../models/routine.dart';
import '../models/routine_item.dart';

class RoutineService {
  RoutineService({Future<Database> Function()? databaseProvider})
    : _databaseProvider = databaseProvider ?? (() => AppDatabase.database);

  final Future<Database> Function() _databaseProvider;

  static String newId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }

  /// Creates defaults only when creating a routine, never when its list is empty.
  /// With no authenticated user, use a dedicated local-only guest profile.
  Future<Routine> ensureMorningRoutine({
    String? userId,
    required List<(String, String, int)> defaults,
  }) async {
    final database = await _databaseProvider();
    return database.transaction((txn) async {
      const guestId = '00000000-0000-4000-8000-000000000001';
      final ownerId = userId ?? guestId;
      final now = DateTime.now();
      if (userId == null) {
        final guests = await txn.query(
          'users',
          where: 'user_id = ?',
          whereArgs: [guestId],
        );
        if (guests.isEmpty) {
          await txn.insert('users', {
            'user_id': guestId,
            'email': 'local-guest@rest-for-more.invalid',
            'password_hash': '!local-only-no-login',
            'first_name': 'Guest',
            'username': 'local_guest_$guestId',
            'marketing_consent': 0,
            'created_at': now.toIso8601String(),
          });
        }
      }
      final existing = await txn.query(
        RoutineTable.tableName,
        where: 'user_id = ? AND routine_type = ?',
        whereArgs: [ownerId, 'morning'],
        orderBy: 'created_at ASC',
        limit: 1,
      );
      if (existing.isNotEmpty) return Routine.fromMap(existing.first);
      final routine = Routine(
        routineId: newId(),
        userId: ownerId,
        name: 'Morning routine',
        routineType: 'morning',
        createdAt: now,
      );
      await txn.insert(RoutineTable.tableName, routine.toMap());
      for (var i = 0; i < defaults.length; i++) {
        final (title, description, minutes) = defaults[i];
        await txn.insert(
          RoutineItemTable.tableName,
          RoutineItem(
            routineItemId: newId(),
            routineId: routine.routineId,
            title: title,
            description: description,
            durationMinutes: minutes,
            sortOrder: i,
            isDefault: true,
            createdAt: now,
          ).toMap(),
        );
      }
      return routine;
    });
  }

  /// Creates the default evening routine only when the routine is first created.
  /// With no authenticated user, use the same local-only guest profile.
  Future<Routine> ensureEveningRoutine({
    String? userId,
    required List<(String, String, int)> defaults,
  }) async {
    final database = await _databaseProvider();

    return database.transaction((txn) async {
      const guestId = '00000000-0000-4000-8000-000000000001';
      final ownerId = userId ?? guestId;
      final now = DateTime.now();

      // Make sure the local guest exists when there is no logged-in user.
      if (userId == null) {
        final guests = await txn.query(
          'users',
          where: 'user_id = ?',
          whereArgs: [guestId],
        );

        if (guests.isEmpty) {
          await txn.insert('users', {
            'user_id': guestId,
            'email': 'local-guest@rest-for-more.invalid',
            'password_hash': '!local-only-no-login',
            'first_name': 'Guest',
            'username': 'local_guest_$guestId',
            'marketing_consent': 0,
            'created_at': now.toIso8601String(),
          });
        }
      }

      // Check whether this user already has an evening routine.
      final existing = await txn.query(
        RoutineTable.tableName,
        where: 'user_id = ? AND routine_type = ?',
        whereArgs: [ownerId, 'evening'],
        orderBy: 'created_at ASC',
        limit: 1,
      );

      if (existing.isNotEmpty) {
        return Routine.fromMap(existing.first);
      }

      // No evening routine yet, so create it.
      final routine = Routine(
        routineId: newId(),
        userId: ownerId,
        name: 'Evening routine',
        routineType: 'evening',
        createdAt: now,
      );

      await txn.insert(RoutineTable.tableName, routine.toMap());

      // Seed the default evening steps.
      for (var i = 0; i < defaults.length; i++) {
        final (title, description, minutes) = defaults[i];

        await txn.insert(
          RoutineItemTable.tableName,
          RoutineItem(
            routineItemId: newId(),
            routineId: routine.routineId,
            title: title,
            description: description,
            durationMinutes: minutes,
            sortOrder: i,
            isDefault: true,
            createdAt: now,
          ).toMap(),
        );
      }

      return routine;
    });
  }

  // CREATE
  Future<void> createRoutine(Routine routine) async {
    final database = await _databaseProvider();

    final data = routine.toMap();

    // Any locally created routine needs to be synced.
    data['sync_status'] = 'PENDING';

    await database.insert(RoutineTable.tableName, data);
  }

  Future<void> createRoutineItem(RoutineItem item) async {
    final database = await _databaseProvider();

    await database.insert(RoutineItemTable.tableName, item.toMap());
  }

  // READ
  Future<List<Routine>> getRoutinesByUserId(String userId) async {
    final database = await _databaseProvider();

    final result = await database.query(
      RoutineTable.tableName,
      where: 'user_id = ? AND deleted_at IS NULL',
      whereArgs: [userId],
      orderBy: 'created_at ASC',
    );

    return result.map((map) => Routine.fromMap(map)).toList();
  }

  Future<Routine?> getRoutineById(String routineId) async {
    final database = await _databaseProvider();

    final result = await database.query(
      RoutineTable.tableName,
      where: 'routine_id = ? AND deleted_at IS NULL',
      whereArgs: [routineId],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return Routine.fromMap(result.first);
  }

  Future<List<RoutineItem>> getRoutineItems(String routineId) async {
    final database = await _databaseProvider();

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
    final database = await _databaseProvider();

    final data = routine.toMap();

    // Any local change must be uploaded again.
    data['sync_status'] = 'PENDING';

    await database.update(
      RoutineTable.tableName,
      data,
      where: 'routine_id = ?',
      whereArgs: [routine.routineId],
    );
  }

  Future<void> updateRoutineItem(RoutineItem item) async {
    final database = await _databaseProvider();

    await database.update(
      RoutineItemTable.tableName,
      item.toMap(),
      where: 'routine_item_id = ?',
      whereArgs: [item.routineItemId],
    );
  }

  // DELETE
  /// Persist the displayed order atomically, including rows with old gaps.
  Future<void> reorderItems(List<RoutineItem> items) async {
    final database = await _databaseProvider();
    await database.transaction((txn) async {
      for (var i = 0; i < items.length; i++) {
        await txn.update(
          RoutineItemTable.tableName,
          {'sort_order': i, 'updated_at': DateTime.now().toIso8601String()},
          where: 'routine_item_id = ? AND routine_id = ?',
          whereArgs: [items[i].routineItemId, items[i].routineId],
        );
      }
    });
  }

  Future<void> deleteRoutine(String routineId) async {
    final database = await _databaseProvider();

    final now = DateTime.now().toUtc().toIso8601String();

    // Soft delete instead of physically removing the row.
    // The tombstone can then be sent to PostgreSQL.
    await database.update(
      RoutineTable.tableName,
      {'deleted_at': now, 'updated_at': now, 'sync_status': 'PENDING'},
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }

  Future<void> deleteRoutineItem(String routineItemId) async {
    final database = await _databaseProvider();

    // RoutineItem sync will be implemented separately.
    // Keep the current behavior for now.
    await database.delete(
      RoutineItemTable.tableName,
      where: 'routine_item_id = ?',
      whereArgs: [routineItemId],
    );
  }
}
