import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/controllers/morning_routine_session.dart';
import 'package:rest_for_more/controllers/routine_run_controller.dart';
import 'package:rest_for_more/services/android_focus_notification.dart';
import 'package:rest_for_more/models/routine_item.dart';
import 'package:rest_for_more/screens/morningroutine.dart';

import 'morning_routine_test.dart' show MemoryRoutineService;

class FakeNotification extends AndroidFocusNotification {
  final ends = <DateTime>[];
  int hides = 0;
  @override
  Future<void> show({required DateTime finishingAt}) async =>
      ends.add(finishingAt);
  @override
  Future<void> hide() async {
    hides++;
  }
}

RoutineItem step(String id) => RoutineItem(
  routineItemId: id,
  routineId: 'morning',
  title: id,
  durationMinutes: 1,
  createdAt: DateTime(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('background catch-up, pause, resume and notification deadlines', () {
    var now = DateTime(2026);
    final notification = FakeNotification();
    final session = MorningRoutineSession(
      now: () => now,
      notification: notification,
    );
    addTearDown(session.dispose);
    final run = session.startOrContinue([
      step('Water'),
      step('Stretch'),
      step('Read'),
    ]);
    expect(notification.ends.single, now.add(const Duration(minutes: 3)));
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 80));
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(run.current.title, 'Stretch');
    expect(run.remaining, const Duration(seconds: 40));
    expect(notification.ends.length, 1);
    run.pause();
    expect(session.isActive, isTrue);
    expect(notification.hides, 1);
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(hours: 1));
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(run.remaining, const Duration(seconds: 40));
    expect(session.startOrContinue([]), same(run));
    run.resume();
    expect(notification.ends.last, now.add(const Duration(seconds: 100)));
    run.advance();
    expect(notification.ends.last, now.add(const Duration(minutes: 1)));
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 2));
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(session.isActive, isFalse);
    expect(run.status, RoutineRunStatus.finished);
    expect(notification.hides, 2);
  });

  testWidgets('continue retains the run after closing timer and routine menu', (
    tester,
  ) async {
    var now = DateTime(2026);
    final session = MorningRoutineSession(
      now: () => now,
      notification: FakeNotification(),
    );
    final service = MemoryRoutineService()
      ..items.addAll([step('Water'), step('Stretch')]);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      MorningRoutineScreen(service: service, session: session),
                ),
              ),
              child: const Text('Open routine'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Start your morning'));
    await tester.pumpAndSettle();
    final original = session.run;
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Continue your morning'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    session.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(seconds: 75));
    session.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await tester.tap(find.text('Open routine'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue your morning'));
    await tester.pumpAndSettle();
    expect(session.run, same(original));
    expect(find.text('Step 2 of 2'), findsOneWidget);
    expect(find.text('00:45'), findsOneWidget);
    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Continue your morning'), findsOneWidget);
    await tester.tap(find.text('Continue your morning'));
    await tester.pumpAndSettle();
    expect(find.text('Resume'), findsOneWidget);
    await tester.ensureVisible(find.text('Stop'));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.text('Start your morning'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    session.dispose();
  });
}
