import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/theme.dart';
import 'package:app/widgets/level_progress.dart';

void main() {
  test('level goes up every 100 XP', () {
    expect(levelForXp(0), 1);
    expect(levelForXp(99), 1);
    expect(levelForXp(100), 2);
    expect(levelForXp(250), 3);
  });

  test('xpToNextLevel counts down to the next 100', () {
    expect(xpToNextLevel(0), 100);
    expect(xpToNextLevel(70), 30);
    expect(xpToNextLevel(100), 100);
  });

  testWidgets('LevelProgress shows level, XP left and bar progress', (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: appTheme, home: const Scaffold(body: LevelProgress(xp: 170))),
    );

    expect(find.text('170 XP'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('30 XP to Level 3'), findsOneWidget);
    final bar = tester.widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator));
    expect(bar.value, closeTo(0.7, 0.001));
  });
}
