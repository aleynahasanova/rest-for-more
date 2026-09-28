import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rest_for_more/components/routine_item.dart';
import 'package:rest_for_more/models/routine_item.dart';

void main() {
  RoutineItem step({bool withDetails = true}) => RoutineItem(
    routineItemId: 'local-step-1',
    routineId: 'local-morning',
    title: 'Stretch',
    description: withDetails ? 'Take a gentle movement break.' : null,
    startTime: withDetails ? '07:30' : null,
    durationMinutes: withDetails ? 5 : null,
    sortOrder: 0,
    isDefault: false,
    createdAt: DateTime(2026, 9, 28),
  );

  testWidgets('shows timing and delegates editing and completion to parent', (
    tester,
  ) async {
    var completed = false;
    var edits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RoutineItemCard(
              item: RoutineItem.fromMap(step().toMap()),
              isCompleted: completed,
              onCompletedChanged: (value) => setState(() => completed = value),
              onEdit: () => edits++,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Stretch'), findsOneWidget);
    expect(find.text('Take a gentle movement break.'), findsOneWidget);
    expect(find.text('5 min'), findsOneWidget);
    expect(find.textContaining('Starts at '), findsOneWidget);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(completed, isTrue);
    expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(completed, isFalse);
    await tester.tap(find.byTooltip('Edit Stretch'));
    expect(edits, 1);
  });

  for (final storedTime in [
    '07:30',
    '07:30:15',
    '07:30:15.250',
    '00:00',
    '23:59',
  ]) {
    testWidgets('displays database time $storedTime without changing it', (
      tester,
    ) async {
      final row = step().toMap()..['start_time'] = storedTime;
      final item = RoutineItem.fromMap(row);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(alwaysUse24HourFormat: true),
            child: Scaffold(body: RoutineItemCard(item: item)),
          ),
        ),
      );
      expect(
        find.text('Starts at ${storedTime.substring(0, 5)}'),
        findsOneWidget,
      );
      expect(item.toMap(), equals(row));
      expect(tester.takeException(), isNull);
    });
  }

  for (final storedTime in ['', 'invalid', '24:00', '07:60', '07:30:60']) {
    testWidgets('handles invalid database time "$storedTime" safely', (
      tester,
    ) async {
      final item = RoutineItem.fromMap(
        step().toMap()..['start_time'] = storedTime,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: RoutineItemCard(item: item)),
        ),
      );
      expect(find.text('Start time unavailable'), findsOneWidget);
      expect(find.text('5 min'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'supports nullable fields and read-only display at narrow width',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 280,
              child: RoutineItemCard(item: step(withDetails: false)),
            ),
          ),
        ),
      );

      expect(find.text('Stretch'), findsOneWidget);
      expect(find.textContaining(' min'), findsNothing);
      expect(find.textContaining('Starts at '), findsNothing);
      expect(find.byType(IconButton), findsNothing);
      expect(tester.widget<Checkbox>(find.byType(Checkbox)).onChanged, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
