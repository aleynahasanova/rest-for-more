import 'package:flutter_test/flutter_test.dart';

import 'package:rest_for_more/main.dart';

void main() {
  testWidgets('App opens the login screen when nobody is logged in', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    // Wait for the check of a saved login to finish.
    await tester.pumpAndSettle();

    expect(find.text('Create account'), findsOneWidget);
  });
}
