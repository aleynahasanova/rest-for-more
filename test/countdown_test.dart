import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/controllers/countdown_controller.dart';
import 'package:rest_for_more/controllers/routine_run_controller.dart';
import 'package:rest_for_more/models/routine_item.dart';
import 'package:rest_for_more/screens/focusmode.dart';
import 'package:rest_for_more/screens/night_run_screen.dart';
import 'package:rest_for_more/widgets/countdown_timer.dart';

void main() {
  test('format rounds up, clamps expired time, and supports long sessions', () {
    expect(
      CountdownController.format(const Duration(milliseconds: 1)),
      '00:01',
    );
    expect(CountdownController.format(const Duration(seconds: -1)), '00:00');
    expect(CountdownController.format(const Duration(minutes: 180)), '180:00');
  });

  test('pause preserves time while suspended ticks still catch up', () {
    var now = DateTime(2026);
    final timer = CountdownController(onTick: () {}, now: () => now);
    addTearDown(timer.dispose);
    timer.start(const Duration(minutes: 1));
    now = now.add(const Duration(seconds: 17));
    timer.pause();
    expect(timer.remaining, const Duration(seconds: 43));
    now = now.add(const Duration(hours: 2));
    timer.refresh();
    expect(timer.remaining, const Duration(seconds: 43));
    timer.resume();
    timer.suspendTicks();
    now = now.add(const Duration(seconds: 50));
    expect(timer.refresh(), isTrue);
    expect(timer.remaining, Duration.zero);
    expect(timer.progress, 1);
    timer.reset(const Duration(minutes: 2));
    expect(timer.deadline, isNull);
    expect(timer.progress, 0);
  });

  testWidgets('focus uses shared ticking, pause, resume and completion', (
    tester,
  ) async {
    var now = DateTime(2026);
    final focus = FocusTimerController(now: () => now);
    addTearDown(focus.dispose);
    focus.selectDuration(const Duration(minutes: 1));
    focus.startSession();
    now = now.add(const Duration(seconds: 5));
    await tester.pump(const Duration(seconds: 1));
    expect(focus.remaining, const Duration(seconds: 55));
    focus.pauseSession();
    expect(focus.status, FocusTimerStatus.paused);
    final frozen = focus.remaining;
    await tester.pump(const Duration(seconds: 10));
    expect(focus.remaining, frozen);
    focus.resumeSession();
    expect(focus.status, FocusTimerStatus.running);
    now = now.add(const Duration(minutes: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(focus.status, FocusTimerStatus.completed);
    expect(focus.remaining, Duration.zero);
    focus.cancelSession();
    expect(focus.status, FocusTimerStatus.ready);
    expect(focus.remaining, const Duration(minutes: 1));
    focus.startSession();
    focus.didChangeAppLifecycleState(AppLifecycleState.paused);
    now = now.add(const Duration(minutes: 2));
    focus.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(focus.status, FocusTimerStatus.completed);
  });

  testWidgets(
    'night routine uses shared display and preserves step transitions',
    (tester) async {
      final run = RoutineRunController([
        for (final title in ['Read', 'Rest'])
          RoutineItem(
            routineItemId: title,
            routineId: 'night',
            title: title,
            durationMinutes: 1,
            createdAt: DateTime(2026),
          ),
      ]);
      addTearDown(run.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: NightRunScreen(
            controller: run,
            iconFor: (_) => Icons.bedtime_outlined,
          ),
        ),
      );
      expect(find.byType(CountdownTimer), findsOneWidget);
      run.pause();
      await tester.pumpAndSettle();
      expect(find.text('Paused'), findsOneWidget);
      run.advance();
      await tester.pumpAndSettle();
      expect(find.text('Rest'), findsOneWidget);
      run.advance();
      await tester.pumpAndSettle();
      expect(find.byType(CountdownTimer), findsNothing);
      expect(find.text('Your evening is complete.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('shared display fits long countdowns and supports night colors', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CountdownTimer(
            remaining: Duration(minutes: 180),
            progress: 0.5,
            textColor: Colors.white,
            progressColor: Colors.amber,
            trackColor: Colors.black,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('180:00'), findsOneWidget);
    final ring = tester.widget<CircularProgressIndicator>(
      find.byType(CircularProgressIndicator),
    );
    expect(ring.value, 0.5);
    expect(ring.color, Colors.amber);
    expect(tester.takeException(), isNull);
  });
}
