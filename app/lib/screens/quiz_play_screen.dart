import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/widgets.dart';

class QuizPlayScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;

  const QuizPlayScreen({super.key, required this.quizId, required this.quizTitle});

  @override
  State<QuizPlayScreen> createState() => _QuizPlayScreenState();
}

class _QuizPlayScreenState extends State<QuizPlayScreen> {
  List<dynamic>? _questions;
  late List<int?> _answers;
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  int _current = 0;

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
      final res = await Api.authedGet('/quizzes/${widget.quizId}');
      if (res.statusCode != 200) {
        setState(() => _error = 'Could not load this quiz.');
        return;
      }
      final questions = Api.decode(res)['questions'] as List;
      setState(() {
        _questions = questions;
        _answers = List<int?>.filled(questions.length, null);
      });
    } catch (_) {
      setState(() => _error = 'Could not load this quiz. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmSubmit() async {
    // Next/Submit is disabled until the current question is answered (see
    // onPressed below), so by the time this fires every question is already
    // answered -- no need for an "answered X of Y" count here.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit quiz?'),
        content: const Text("You won't be able to change your answers after this."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );
    if (confirmed == true) _submit();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final res = await Api.authedPost('/quizzes/${widget.quizId}/submit', {
        'answers': _answers.cast<int>(),
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        context.pushReplacement('/student/quiz-result', extra: Api.decode(res));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit. Please try again.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not submit. Check your connection.')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _questions == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quizTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _questions == null) {
      return Scaffold(appBar: AppBar(title: Text(widget.quizTitle)), body: ErrorState(message: _error!, onRetry: _load));
    }

    final questions = _questions!;
    final q = questions[_current] as Map<String, dynamic>;
    final options = (q['options'] as List).cast<String>();
    final selected = _answers[_current];
    final isLast = _current == questions.length - 1;

    return Scaffold(
      appBar: AppBar(title: Text(widget.quizTitle)),
      body: CenteredMaxWidth(
        maxWidth: 700,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(value: (_current + 1) / questions.length, minHeight: 8),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Question ${_current + 1} of ${questions.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: Spacing.lg),
              Text(q['text']?.toString() ?? '', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: Spacing.xl),
              Expanded(
                child: ListView.separated(
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
                  itemBuilder: (context, i) {
                    final isSelected = selected == i;
                    final primary = Theme.of(context).colorScheme.primary;
                    return InkWell(
                      borderRadius: AppRadius.md,
                      onTap: () => setState(() => _answers[_current] = i),
                      child: Container(
                        padding: const EdgeInsets.all(Spacing.lg),
                        decoration: BoxDecoration(
                          color: isSelected ? primary.withValues(alpha: 0.1) : Colors.white,
                          borderRadius: AppRadius.md,
                          border: Border.all(color: isSelected ? primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                              color: isSelected ? primary : Colors.grey.shade400,
                            ),
                            const SizedBox(width: Spacing.md),
                            Expanded(child: Text(options[i], style: Theme.of(context).textTheme.bodyLarge)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: Spacing.lg),
              Row(
                children: [
                  if (_current > 0) ...[
                    Expanded(child: OutlinedButton(onPressed: () => setState(() => _current--), child: const Text('Previous'))),
                    const SizedBox(width: Spacing.md),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: isLast ? 'Submit' : 'Next',
                      loading: _submitting,
                      onPressed: selected == null
                          ? null
                          : () => isLast ? _confirmSubmit() : setState(() => _current++),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
