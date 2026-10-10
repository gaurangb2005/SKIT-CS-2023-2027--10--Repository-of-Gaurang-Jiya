import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/theme.dart';
import 'package:app/widgets/quiz_stars.dart';

void main() {
  test('stars follow the 90 / 60 / above-zero thresholds', () {
    expect(starsForPercentage(100), 3);
    expect(starsForPercentage(90), 3);
    expect(starsForPercentage(89.9), 2);
    expect(starsForPercentage(60), 2);
    expect(starsForPercentage(20), 1);
    expect(starsForPercentage(0), 0);
  });

  test('starsForScore handles an empty quiz', () {
    expect(starsForScore(5, 5), 3);
    expect(starsForScore(3, 5), 2);
    expect(starsForScore(0, 0), 0);
  });

  testWidgets('StarRating colours only the earned stars', (tester) async {
    await tester.pumpWidget(MaterialApp(theme: appTheme, home: const Scaffold(body: StarRating(stars: 2))));

    final icons = tester.widgetList<Icon>(find.byIcon(Icons.star_rounded)).toList();
    expect(icons.length, 3);
    expect(icons.where((i) => i.color == AppColors.accent).length, 2);
  });
}
