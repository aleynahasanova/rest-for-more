import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/controllers/routine_run_controller.dart';
import 'package:rest_for_more/models/routine_item.dart';
import 'package:rest_for_more/screens/morning_run_screen.dart';

RoutineItem step(String id, {int? minutes = 1}) => RoutineItem(
  routineItemId: id,
  routineId: 'routine',
  title: id,
  durationMinutes: minutes,
  createdAt: DateTime(2026),
);

void main() {
  test('catches up across steps and finishes automatically', () {
    var now = DateTime(2026);
    final source = [step('Water'), step('Stretch'), step('Breakfast')];
    final run = RoutineRunController(source, now: () => now);
    addTearDown(run.dispose);
    source.clear();
    expect(run.steps.length, 3);
    now = now.add(const Duration(seconds: 130));
    run.refresh();
    expect(run.current.title, 'Breakfast');
    expect(run.remaining, const Duration(seconds: 50));
    expect(run.completedIds, {'Water', 'Stretch'});
    now = now.add(const Duration(seconds: 50));
    run.refresh();
    expect(run.status, RoutineRunStatus.finished);
    expect(run.remainingTotal, Duration.zero);
    expect(run.completedIds.length, 3);
  });

  test('pause freezes exact remaining time and resume sets a new deadline', () {
    var now = DateTime(2026);
    final run = RoutineRunController([
      step('Water'),
      step('Stretch'),
    ], now: () => now);
    addTearDown(run.dispose);
    now = now.add(const Duration(seconds: 17));
    run.pause();
    expect(run.remaining, const Duration(seconds: 43));
    now = now.add(const Duration(hours: 2));
    run.refresh();
    expect(run.index, 0);
    expect(run.remaining, const Duration(seconds: 43));
    run.resume();
    now = now.add(const Duration(seconds: 43));
    run.refresh();
    expect(run.index, 1);
    expect(run.remaining, const Duration(minutes: 1));
  });

  test(
    'next from pause resumes and stop does not complete unfinished steps',
    () {
      final run = RoutineRunController([step('Water'), step('Stretch')]);
      addTearDown(run.dispose);
      run.pause();
      run.advance();
      expect(run.status, RoutineRunStatus.running);
      expect(run.current.title, 'Stretch');
      run.stop();
      expect(run.status, RoutineRunStatus.finished);
      expect(run.stoppedEarly, isTrue);
      expect(run.completedIds, {'Water'});
    },
  );

  test('next at an automatic transition does not skip two steps', () {
    var now = DateTime(2026);
    final run = RoutineRunController([
      step('Water'),
      step('Stretch'),
    ], now: () => now);
    addTearDown(run.dispose);
    now = now.add(const Duration(minutes: 1));
    run.advance();
    expect(run.current.title, 'Stretch');
    expect(run.status, RoutineRunStatus.running);
  });

  test('rejects empty and untimed routines', () {
    for (final steps in <List<RoutineItem>>[
      [],
      [step('Untimed', minutes: null)],
      [step('Zero', minutes: 0)],
    ]) {
      expect(() => RoutineRunController(steps), throwsArgumentError);
    }
  });

  testWidgets('guided screen supports pause, next, completion and return', (
    tester,
  ) async {
    Set<String>? completed;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                completed = await Navigator.of(context).push<Set<String>>(
                  MaterialPageRoute(
                    builder: (_) => MorningRunScreen(
                      items: [step('Water'), step('Stretch')],
                      iconFor: (_) => Icons.water_drop_outlined,
                    ),
                  ),
                );
              },
              child: const Text('Start'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Start'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 2'), findsOneWidget);
    expect(find.text('Next: Stretch'), findsOneWidget);
    await tester.ensureVisible(find.text('Pause'));
    await tester.tap(find.text('Pause'));
    await tester.pumpAndSettle();
    expect(find.text('Paused'), findsOneWidget);
    await tester.ensureVisible(find.text('Resume'));
    await tester.tap(find.text('Resume'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Next step'));
    await tester.tap(find.text('Next step'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 2'), findsOneWidget);
    await tester.ensureVisible(find.text('I’m done'));
    await tester.tap(find.text('I’m done'));
    await tester.pumpAndSettle();
    expect(find.text('Your morning is complete.'), findsOneWidget);
    await tester.ensureVisible(find.text('Done'));
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(completed, {'Water', 'Stretch'});
    expect(find.text('Start'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('short screen scrolls and stopping shows an honest end state', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MorningRunScreen(
          items: [step('Water')],
          iconFor: (_) => Icons.water_drop_outlined,
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Stop'));
    await tester.tap(find.text('Stop'));
    await tester.pumpAndSettle();
    expect(find.text('Your morning has ended.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
