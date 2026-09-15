import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/theme.dart';
import 'package:app/widgets/learning_widgets.dart';
import 'package:app/widgets/responsive_shell.dart';
import 'package:app/widgets/widgets.dart';

const _widths = [360.0, 768.0, 1366.0];

Future<void> _setSize(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget _wrap(Widget child) => MaterialApp(theme: appTheme, home: child);

void main() {
  for (final width in _widths) {
    testWidgets('ResponsiveShell with nav + subject grid has no overflow at ${width}px', (tester) async {
      await _setSize(tester, width);
      await tester.pumpWidget(
        _wrap(
          ResponsiveShell(
            title: 'Student',
            items: const [
              NavItem(Icons.menu_book_rounded, 'Learn'),
              NavItem(Icons.sports_esports_rounded, 'Games'),
              NavItem(Icons.quiz_rounded, 'Quiz'),
              NavItem(Icons.person_rounded, 'Profile'),
            ],
            currentIndex: 0,
            onTap: (_) {},
            body: ListView(
              padding: const EdgeInsets.all(Spacing.lg),
              children: [
                Row(
                  children: [
                    Expanded(child: StatCard(label: 'Students', value: '42', icon: Icons.school_rounded)),
                    const SizedBox(width: Spacing.md),
                    Expanded(child: StatCard(label: 'Teachers', value: '7', icon: Icons.person_rounded)),
                  ],
                ),
                const SizedBox(height: Spacing.lg),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = (constraints.maxWidth / 180).floor().clamp(2, 5);
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: 6,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: Spacing.md,
                        crossAxisSpacing: Spacing.md,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, i) => SubjectCard(name: 'Subject with a long name $i', contentCount: i * 3),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Quiz option cards have no overflow at ${width}px', (tester) async {
      await _setSize(tester, width);
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Column(
                children: [
                  const LinearProgressIndicator(value: 0.4),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final label in [
                          'A fairly short option',
                          'A much longer answer option that could wrap onto multiple lines on a narrow phone screen',
                          'C',
                          'D',
                        ])
                          Container(
                            margin: const EdgeInsets.only(bottom: Spacing.md),
                            padding: const EdgeInsets.all(Spacing.lg),
                            decoration: BoxDecoration(border: Border.all(), borderRadius: AppRadius.md),
                            child: Row(
                              children: [
                                const Icon(Icons.radio_button_unchecked_rounded),
                                const SizedBox(width: Spacing.md),
                                Expanded(child: Text(label)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Previous'))),
                      const SizedBox(width: Spacing.md),
                      Expanded(child: PrimaryButton(label: 'Submit', onPressed: () {})),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Login two-panel layout has no overflow at ${width}px', (tester) async {
      await _setSize(tester, width);
      final wide = width >= 900;
      final phoneController = TextEditingController();
      addTearDown(phoneController.dispose);

      final form = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Welcome 👋'),
          const SizedBox(height: Spacing.lg),
          AppTextField(label: 'Phone number', controller: phoneController, prefixText: '+91  '),
          const SizedBox(height: Spacing.lg),
          PrimaryButton(label: 'Send OTP', onPressed: () {}),
        ],
      );

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: wide
                ? Row(
                    children: [
                      Expanded(child: Container(color: Colors.indigo)),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: SingleChildScrollView(padding: const EdgeInsets.all(Spacing.xxl), child: form),
                          ),
                        ),
                      ),
                    ],
                  )
                : SafeArea(
                    child: SingleChildScrollView(padding: const EdgeInsets.all(Spacing.xl), child: form),
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
