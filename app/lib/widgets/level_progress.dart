import 'package:flutter/material.dart';

import '../theme.dart';
import 'learning_widgets.dart';
import 'widgets.dart';

const kXpPerLevel = 100;

int levelForXp(int xp) => (xp ~/ kXpPerLevel) + 1;

int xpToNextLevel(int xp) => kXpPerLevel - (xp % kXpPerLevel);

/// XP badge, current level and a bar showing progress towards the next level.
class LevelProgress extends StatelessWidget {
  final int xp;

  const LevelProgress({super.key, required this.xp});

  @override
  Widget build(BuildContext context) {
    final level = levelForXp(xp);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              XPBadge(xp: xp),
              const SizedBox(width: Spacing.md),
              Expanded(child: Text('Level $level', style: Theme.of(context).textTheme.titleMedium)),
            ],
          ),
          const SizedBox(height: Spacing.md),
          ClipRRect(
            borderRadius: AppRadius.sm,
            child: LinearProgressIndicator(
              value: (xp % kXpPerLevel) / kXpPerLevel,
              minHeight: 8,
              backgroundColor: AppColors.accent.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            '${xpToNextLevel(xp)} XP to Level ${level + 1}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
