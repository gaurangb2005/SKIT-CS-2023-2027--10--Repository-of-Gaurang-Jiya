import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/theme.dart';
import 'package:app/widgets/widgets.dart';

void main() {
  testWidgets('Dashboard cards show hover feedback', (tester) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme,
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              child: AppCard(onTap: _noop, child: Text('Dashboard row')),
            ),
          ),
        ),
      ),
    );

    BoxDecoration cardSurface() =>
        tester
                .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                .decoration!
            as BoxDecoration;
    expect(cardSurface().boxShadow, isEmpty);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await mouse.moveTo(tester.getCenter(find.text('Dashboard row')));
    await tester.pumpAndSettle();

    expect(cardSurface().boxShadow, isNotEmpty);
  });
}

void _noop() {}
