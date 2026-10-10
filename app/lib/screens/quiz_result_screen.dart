import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/quiz_stars.dart';
import '../widgets/widgets.dart';

class QuizResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;

  const QuizResultScreen({super.key, required this.result});

  @override
  State<QuizResultScreen> createState() => _QuizResultScreenState();
}

class _QuizResultScreenState extends State<QuizResultScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 700))..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _messageFor(double percentage) {
    if (percentage == 100) return 'Perfect score! Amazing work! 🎉';
    if (percentage >= 80) return 'Great job! Keep it up! 🌟';
    if (percentage >= 50) return 'Good effort! Practice makes perfect. 💪';
    return "Don't give up, try again! 📚";
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.result['score'] as int;
    final total = widget.result['total'] as int;
    final percentage = (widget.result['percentage'] as num).toDouble();
    final xp = widget.result['xp_earned'] as int;
    final results = (widget.result['results'] as List).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('Result'), automaticallyImplyLeading: false),
      body: CenteredMaxWidth(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Center(
              child: ScaleTransition(
                scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
                child: ProgressRing(
                  value: percentage / 100,
                  label: '$score/$total',
                  color: percentage >= 50 ? AppColors.success : AppColors.error,
                  size: 140,
                ),
              ),
            ),
            const SizedBox(height: Spacing.lg),
            Center(child: Text('$percentage%', style: Theme.of(context).textTheme.displaySmall)),
            const SizedBox(height: Spacing.md),
            Center(child: StarRating(stars: starsForPercentage(percentage), size: 40, animate: true)),
            const SizedBox(height: Spacing.md),
            Center(child: XPBadge(xp: xp)),
            const SizedBox(height: Spacing.lg),
            Center(child: Text(_messageFor(percentage), textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
            const SizedBox(height: Spacing.xxl),
            PrimaryButton(label: 'Done', onPressed: () => context.go('/student')),
            const SizedBox(height: Spacing.xl),
            Text('Answer review', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.md),
            for (final r in results) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(r['text']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: Spacing.sm),
                    ..._buildOptionRows(r),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildOptionRows(Map<String, dynamic> r) {
    final options = (r['options'] as List).cast<String>();
    final selected = r['selected'] as int;
    final correct = r['correct_option'] as int;
    return [
      for (var i = 0; i < options.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Icon(
                i == correct ? Icons.check_circle_rounded : (i == selected ? Icons.cancel_rounded : Icons.circle_outlined),
                size: 18,
                color: i == correct ? AppColors.success : (i == selected ? AppColors.error : Colors.grey.shade400),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  options[i],
                  style: TextStyle(
                    color: i == correct ? AppColors.success : (i == selected ? AppColors.error : null),
                    fontWeight: i == correct || i == selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
    ];
  }
}
