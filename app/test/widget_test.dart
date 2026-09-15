import 'package:flutter_test/flutter_test.dart';

import 'package:app/main.dart';

void main() {
  testWidgets('App starts on splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RuralEduApp());

    expect(find.text('Rural Edu Platform'), findsOneWidget);

    // Flush the splash screen's delayed redirect timer so it doesn't leak past the test.
    await tester.pump(const Duration(seconds: 1));
  });
}
