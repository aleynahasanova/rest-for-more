import 'package:flutter_test/flutter_test.dart';

import 'package:rest_for_more/main.dart';

void main() {
  testWidgets('App loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Ready to put your phone aside?'), findsOneWidget);

    expect(find.text('Start Focus Mode'), findsOneWidget);
  });
}
