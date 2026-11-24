import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../data/mock_blockable_apps.dart';
import '../models/blocking_mode.dart';
import '../utils/id_generator.dart';

/// Independent saved selections, using the existing modes/blocked-app tables.
class ModeAppSelectionService {
  ModeAppSelectionService({
    Future<Database> Function()? databaseProvider,
    this._userId,
  }) : _databaseProvider = databaseProvider ?? (() => AppDatabase.database);

  final Future<Database> Function() _databaseProvider;
  final String? _userId;

  Future<String> _ensureMode(Transaction txn, BlockingMode mode) async {
    const guestId = '00000000-0000-4000-8000-000000000001';
    final owner = _userId ?? guestId;
    final now = DateTime.now().toIso8601String();
    if (_userId == null) {
      final users = await txn.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [owner],
      );
      if (users.isEmpty) {
        await txn.insert('users', {
          'user_id': owner,
          'email': 'local-guest@rest-for-more.invalid',
          'password_hash': '!local-only-no-login',
          'first_name': 'Guest',
          'username': 'local_guest_$owner',
          'marketing_consent': 0,
          'created_at': now,
        });
      }
    }
    final modes = await txn.query(
      'modes',
      where: 'user_id = ? AND mode_type = ? AND deleted_at IS NULL',
      whereArgs: [owner, mode.name],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (modes.isNotEmpty) return modes.first['mode_id'] as String;
    final id = IdGenerator.newId();
    await txn.insert('modes', {
      'mode_id': id,
      'user_id': owner,
      'mode_type': mode.name,
      'name': '${mode.title} Mode',
      'created_at': now,
    });
    // Seed each mode once. A deliberately empty saved list stays empty.
    for (final app in MockBlockableApps.all.where(
      (app) => MockBlockableApps.defaultSelectedIds.contains(app.id),
    )) {
      await txn.insert('mode_blocked_apps', {
        'mode_blocked_app_id': IdGenerator.newId(),
        'mode_id': id,
        'app_identifier': app.packageName,
        'app_name': app.name,
        'created_at': now,
      });
    }
    return id;
  }

  Future<Set<String>> load(BlockingMode mode) async {
    final db = await _databaseProvider();
    return db.transaction((txn) async {
      final id = await _ensureMode(txn, mode);
      final rows = await txn.query(
        'mode_blocked_apps',
        where: 'mode_id = ? AND deleted_at IS NULL',
        whereArgs: [id],
      );
      final packages = rows.map((row) => row['app_identifier']).toSet();
      return MockBlockableApps.all
          .where((app) => packages.contains(app.packageName))
          .map((app) => app.id)
          .toSet();
    });
  }

  Future<void> save(BlockingMode mode, Set<String> selectedIds) async {
    final knownIds = MockBlockableApps.all.map((app) => app.id).toSet();
    if (!knownIds.containsAll(selectedIds)) {
      throw ArgumentError('Unknown app selection');
    }
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      final id = await _ensureMode(txn, mode);
      final now = DateTime.now().toIso8601String();
      await txn.update(
        'mode_blocked_apps',
        {'deleted_at': now, 'sync_status': 'PENDING'},
        where: 'mode_id = ?',
        whereArgs: [id],
      );
      for (final app in MockBlockableApps.all.where(
        (app) => selectedIds.contains(app.id),
      )) {
        final rows = await txn.query(
          'mode_blocked_apps',
          where: 'mode_id = ? AND app_identifier = ?',
          whereArgs: [id, app.packageName],
        );
        if (rows.isEmpty) {
          await txn.insert('mode_blocked_apps', {
            'mode_blocked_app_id': IdGenerator.newId(),
            'mode_id': id,
            'app_identifier': app.packageName,
            'app_name': app.name,
            'created_at': now,
          });
        } else {
          await txn.update(
            'mode_blocked_apps',
            {'deleted_at': null, 'sync_status': 'PENDING'},
            where: 'mode_blocked_app_id = ?',
            whereArgs: [rows.first['mode_blocked_app_id']],
          );
        }
      }
      await txn.update(
        'modes',
        {'updated_at': now, 'sync_status': 'PENDING'},
        where: 'mode_id = ?',
        whereArgs: [id],
      );
    });
  }
}
