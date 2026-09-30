import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rest_for_more/database/tables/user_table.dart';
import 'package:rest_for_more/database/tables/routine_table.dart';
import 'package:rest_for_more/database/tables/routine_item_table.dart';
import 'package:rest_for_more/models/routine.dart';
import 'package:rest_for_more/models/routine_item.dart';
import 'package:rest_for_more/services/routine_service.dart';
import 'package:rest_for_more/screens/morningroutine.dart';

class MemoryRoutineService extends RoutineService {
  final items = <RoutineItem>[];
  bool failSave = false;
  final routine = Routine(
    routineId: 'morning',
    userId: 'guest',
    name: 'Morning',
    routineType: 'morning',
    createdAt: DateTime(2026),
  );
  @override
  Future<Routine> ensureMorningRoutine({
    String? userId,
    required List<(String, String, int)> defaults,
  }) async => routine;
  @override
  Future<List<RoutineItem>> getRoutineItems(String id) async => List.of(items);
  @override
  Future<void> createRoutineItem(RoutineItem item) async {
    if (failSave) throw StateError('Offline');
    items.add(item);
  }

  @override
  Future<void> updateRoutineItem(RoutineItem item) async {
    if (failSave) throw StateError('Offline');
    items[items.indexWhere((old) => old.routineItemId == item.routineItemId)] =
        item;
  }

  @override
  Future<void> deleteRoutineItem(String id) async =>
      items.removeWhere((item) => item.routineItemId == id);
}

void main() {
  test(
    'SQLite seeds once, saves edits and additions, and retains deletions',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('PRAGMA foreign_keys = ON');
      await UserTable.create(db);
      await RoutineTable.create(db);
      await RoutineItemTable.create(db);
      final service = RoutineService(databaseProvider: () async => db);
      final routine = await service.ensureMorningRoutine(
        defaults: MorningRoutineScreen.defaultItems,
      );
      final defaults = await service.getRoutineItems(routine.routineId);
      expect(defaults.length, 5);
      expect(defaults.every((item) => item.isDefault), isTrue);
      expect(defaults.map((item) => item.sortOrder), [0, 1, 2, 3, 4]);
      expect(
        (await service.ensureMorningRoutine(
          defaults: MorningRoutineScreen.defaultItems,
        )).routineId,
        routine.routineId,
      );
      expect((await service.getRoutineItems(routine.routineId)).length, 5);
      final row = defaults.first.toMap()
        ..['title'] = 'A glass of water'
        ..['start_time'] = '07:30';
      await service.updateRoutineItem(RoutineItem.fromMap(row));
      final added = RoutineItem(
        routineItemId: RoutineService.newId(),
        routineId: routine.routineId,
        title: 'Read',
        durationMinutes: 10,
        sortOrder: 5,
        createdAt: DateTime.now(),
      );
      await service.createRoutineItem(added);
      // A new service reads saved rows rather than in-memory UI state.
      final reopened = RoutineService(databaseProvider: () async => db);
      final saved = await reopened.getRoutineItems(routine.routineId);
      expect(saved.first.title, 'A glass of water');
      expect(saved.first.startTime, '07:30');
      expect(saved.last.title, 'Read');
      await reopened.reorderItems(saved.reversed.toList());
      final reordered = await reopened.getRoutineItems(routine.routineId);
      expect(reordered.first.title, 'Read');
      expect(reordered.map((item) => item.sortOrder), [0, 1, 2, 3, 4, 5]);
      for (final item in saved) {
        await reopened.deleteRoutineItem(item.routineItemId);
      }
      await reopened.ensureMorningRoutine(
        defaults: MorningRoutineScreen.defaultItems,
      );
      expect(await reopened.getRoutineItems(routine.routineId), isEmpty);
      expect((await db.query('users')).length, 1);
    },
  );

  testWidgets('add, validate, retry save, edit, and delete a card', (
    tester,
  ) async {
    final service = MemoryRoutineService();
    await tester.pumpWidget(
      MaterialApp(home: MorningRoutineScreen(service: service)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add step'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a title.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Read');
    await tester.enterText(find.byType(TextFormField).at(2), '10');
    await tester.enterText(find.byType(TextFormField).at(3), '25:00');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid time, e.g. 07:30.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(3), '07:30');
    service.failSave = true;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(
      find.text('Could not save this step. Please try again.'),
      findsOneWidget,
    );
    expect(service.items, isEmpty);
    service.failSave = false;
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Read'), findsOneWidget);
    expect(service.items.single.startTime, '07:30');
    await tester.tap(find.text('Read'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Read a chapter');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.items.single.title, 'Read a chapter');
    await tester.tap(find.byTooltip('Options for Read a chapter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 1 complete • 10 min planned'), findsOneWidget);
    await tester.tap(find.byTooltip('Options for Read a chapter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(service.items.length, 1);
    await tester.tap(find.byTooltip('Options for Read a chapter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(service.items, isEmpty);
    expect(find.text('0 of 0 complete • 0 min planned'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
