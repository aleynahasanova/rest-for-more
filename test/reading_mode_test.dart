import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:rest_for_more/controllers/blocking_mode_session.dart';
import 'package:rest_for_more/controllers/focus_timer_controller.dart';
import 'package:rest_for_more/database/tables/user_table.dart';
import 'package:rest_for_more/database/tables/mode_table.dart';
import 'package:rest_for_more/database/tables/mode_blocked_app_table.dart';
import 'package:rest_for_more/models/blocking_mode.dart';
import 'package:rest_for_more/screens/reading_mode_screen.dart';
import 'package:rest_for_more/services/mode_app_selection_service.dart';
import 'package:rest_for_more/widgets/countdown_timer.dart';

class MemorySelections extends ModeAppSelectionService {
  final selections = <BlockingMode, Set<String>>{
    BlockingMode.focus: {'youtube'},
    BlockingMode.reading: {'instagram'},
  };
  bool failSave = false;
  @override
  Future<Set<String>> load(BlockingMode mode) async =>
      Set.of(selections[mode]!);
  @override
  Future<void> save(BlockingMode mode, Set<String> ids) async {
    if (failSave) throw StateError('Save failed');
    selections[mode] = Set.of(ids);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('rest_for_more/app_blocking');
  final calls = <MethodCall>[];
  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'isAccessibilityEnabled') return true;
          return null;
        });
  });
  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test(
    'SQLite keeps selections separate across reloads and preserves empty lists',
    () async {
      sqfliteFfiInit();
      final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
      addTearDown(db.close);
      await db.execute('PRAGMA foreign_keys = ON');
      await UserTable.create(db);
      await ModeTable.create(db);
      await ModeBlockedAppTable.create(db);
      final service = ModeAppSelectionService(databaseProvider: () async => db);
      final defaults = await service.load(BlockingMode.focus);
      await service.load(BlockingMode.reading);
      await service.save(BlockingMode.reading, {'instagram'});
      expect(await service.load(BlockingMode.focus), defaults);
      await service.save(BlockingMode.focus, {'youtube'});
      final reopened = ModeAppSelectionService(
        databaseProvider: () async => db,
      );
      expect(await reopened.load(BlockingMode.reading), {'instagram'});
      expect(await reopened.load(BlockingMode.focus), {'youtube'});
      await reopened.save(BlockingMode.reading, {});
      expect(await service.load(BlockingMode.reading), isEmpty);
      await service.save(BlockingMode.reading, {'instagram'});
      expect(await reopened.load(BlockingMode.reading), {'instagram'});
      expect(await db.query('modes'), hasLength(2));
      final before = await reopened.load(BlockingMode.reading);
      await expectLater(
        service.save(BlockingMode.reading, {'unknown'}),
        throwsArgumentError,
      );
      expect(await reopened.load(BlockingMode.reading), before);
    },
  );

  test(
    'reading uses its own apps and prevents overlapping focus sessions',
    () async {
      final coordinator = BlockingSessionCoordinator();
      final selections = MemorySelections();
      var now = DateTime(2026);
      final reading = BlockingModeSession(
        mode: BlockingMode.reading,
        coordinator: coordinator,
        selections: selections,
        now: () => now,
      );
      final focus = BlockingModeSession(
        mode: BlockingMode.focus,
        coordinator: coordinator,
        selections: selections,
      );
      addTearDown(reading.dispose);
      addTearDown(focus.dispose);
      reading.selectDuration(const Duration(minutes: 1));
      await reading.startBlockingSession();
      expect(calls.first.arguments, {
        'apps': ['com.instagram.android'],
      });
      final count = calls.length;
      await expectLater(focus.startBlockingSession(), throwsStateError);
      expect(calls.length, count);
      await reading.pauseBlockingSession();
      await expectLater(focus.startBlockingSession(), throwsStateError);
      await reading.resumeBlockingSession();
      expect(reading.status, FocusTimerStatus.running);
      now = now.add(const Duration(minutes: 2));
      reading.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await reading.stopBlocking();
      expect(reading.status, FocusTimerStatus.completed);
      expect(calls.last.method, 'stopBlocking');
      await focus.startBlockingSession();
      final appsCall = calls
          .where((call) => call.method == 'setBlockedApps')
          .last;
      expect(appsCall.arguments, {
        'apps': ['com.google.android.youtube'],
      });
      await focus.stopBlockingSession();
    },
  );

  test('failed selection save leaves both modes unchanged', () async {
    final store = MemorySelections();
    final session = BlockingModeSession(
      mode: BlockingMode.reading,
      coordinator: BlockingSessionCoordinator(),
      selections: store,
    );
    addTearDown(session.dispose);
    await session.loadSelection();
    store.failSave = true;
    await expectLater(session.saveSelection({'tiktok'}), throwsStateError);
    expect(session.selectedAppIds, {'instagram'});
    expect(store.selections[BlockingMode.focus], {'youtube'});
  });

  testWidgets(
    'reading setup, selection, timer and reopening use the same session',
    (tester) async {
      final selections = MemorySelections();
      final session = BlockingModeSession(
        mode: BlockingMode.reading,
        coordinator: BlockingSessionCoordinator(),
        selections: selections,
      );
      addTearDown(session.dispose);
      tester.view.physicalSize = const Size(420, 920);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(home: ReadingModeScreen(session: session)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('How long do you want to read?'), findsOneWidget);
      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();
      expect(
        find.text('These apps will be blocked during reading mode.'),
        findsOneWidget,
      );
      await tester.tap(find.text('TikTok'));
      await tester.tap(find.text('Save selection'));
      await tester.pumpAndSettle();
      expect(session.selectedAppIds, {'instagram', 'tiktok'});
      expect(selections.selections[BlockingMode.focus], {'youtube'});
      await tester.tap(find.text('Start 45 min'));
      await tester.pumpAndSettle();
      expect(find.byType(CountdownTimer), findsOneWidget);
      expect(find.text('Stay with the page in front of you.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        MaterialApp(home: ReadingModeScreen(session: session)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CountdownTimer), findsOneWidget);
      await tester.tap(find.text('Pause'));
      await tester.pumpAndSettle();
      expect(find.text('Your reading session is paused.'), findsOneWidget);
      await tester.tap(find.text('Resume'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.text('How long do you want to read?'), findsOneWidget);
      expect(session.selectedAppIds, {'instagram', 'tiktok'});
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('reading controls remain reachable on a short screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final session = BlockingModeSession(
      mode: BlockingMode.reading,
      coordinator: BlockingSessionCoordinator(),
      selections: MemorySelections(),
    );
    addTearDown(session.dispose);
    await tester.pumpWidget(
      MaterialApp(home: ReadingModeScreen(session: session)),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Start 45 min'));
    await tester.tap(find.text('Start 45 min'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Stop'));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(session.status, FocusTimerStatus.ready);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
