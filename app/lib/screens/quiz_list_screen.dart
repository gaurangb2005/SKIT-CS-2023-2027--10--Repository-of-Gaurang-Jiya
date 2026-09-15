import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/widgets.dart';

class QuizListScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const QuizListScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  State<QuizListScreen> createState() => _QuizListScreenState();
}

class _QuizListScreenState extends State<QuizListScreen> {
  List<dynamic>? _quizzes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.authedGet('/quizzes?subject_id=${widget.subjectId}');
      if (res.statusCode != 200) {
        setState(() => _error = 'Could not load quizzes.');
        return;
      }
      setState(() => _quizzes = Api.decodeList(res));
    } catch (_) {
      setState(() => _error = 'Could not load quizzes. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading && _quizzes == null) {
      body = ListView.separated(
        padding: const EdgeInsets.all(Spacing.lg),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
        itemBuilder: (_, _) => const LoadingSkeleton(height: 72),
      );
    } else if (_error != null && _quizzes == null) {
      body = ErrorState(message: _error!, onRetry: _load);
    } else {
      final quizzes = _quizzes ?? [];
      body = quizzes.isEmpty
          ? const EmptyState(icon: Icons.quiz_rounded, message: 'No quizzes here yet.')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(Spacing.lg),
                itemCount: quizzes.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
                itemBuilder: (context, i) {
                  final q = quizzes[i] as Map<String, dynamic>;
                  final best = q['best_attempt'] as Map<String, dynamic>?;
                  return AppCard(
                    onTap: () => context.push('/student/quiz/${q['id']}', extra: q['title']),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(q['title']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: Spacing.xs),
                              Text(
                                '${q['question_count']} questions',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (best != null)
                          Text('Best: ${best['score']}/${best['total']}', style: Theme.of(context).textTheme.bodyMedium)
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'New',
                              style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                          ),
                        const SizedBox(width: Spacing.sm),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  );
                },
              ),
            );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.subjectName} Quizzes')),
      body: CenteredMaxWidth(child: body),
    );
  }
}
