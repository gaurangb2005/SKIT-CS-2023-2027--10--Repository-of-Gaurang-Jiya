import 'package:flutter/material.dart';

import '../theme.dart';

/// 3 stars from 90%, 2 from 60%, 1 for anything above zero.
int starsForPercentage(double percentage) {
  if (percentage >= 90) return 3;
  if (percentage >= 60) return 2;
  if (percentage > 0) return 1;
  return 0;
}

int starsForScore(int score, int total) => total <= 0 ? 0 : starsForPercentage(score * 100 / total);

/// Row of three stars. With [animate] the earned stars pop in one after another
/// and the rest stay hidden; without it the unearned stars are shown greyed out.
class StarRating extends StatelessWidget {
  final int stars;
  final double size;
  final bool animate;

  const StarRating({super.key, required this.stars, this.size = 20, this.animate = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final earned = i < stars;
        if (!animate) {
          return Icon(Icons.star_rounded, size: size, color: earned ? AppColors.accent : Colors.grey.shade300);
        }
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: earned ? 1.0 : 0.0),
          duration: Duration(milliseconds: 400 + i * 200),
          curve: Curves.elasticOut,
          builder: (context, value, child) =>
              Transform.scale(scale: value, child: Icon(Icons.star_rounded, size: size, color: AppColors.accent)),
        );
      }),
    );
  }
}
