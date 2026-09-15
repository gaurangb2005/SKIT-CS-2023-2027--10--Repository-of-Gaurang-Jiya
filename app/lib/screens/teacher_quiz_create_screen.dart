import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/widgets.dart';

class _QuestionForm {
  final textController = TextEditingController();
  final optionControllers = List.generate(4, (_) => TextEditingController());
  int correct = 0;

  void dispose() {
    textController.dispose();
    for (final c in optionControllers) {
      c.dispose();
    }
  }
}

class TeacherQuizCreateScreen extends StatefulWidget {
  final List<dynamic> subjects;

  const TeacherQuizCreateScreen({super.key, required this.subjects});

  @override
  State<TeacherQuizCreateScreen> createState() => _TeacherQuizCreateScreenState();
}

class _TeacherQuizCreateScreenState extends State<TeacherQuizCreateScreen> {
  int? _subjectId;
  final _titleController = TextEditingController();
  final List<_QuestionForm> _questions = [_QuestionForm()];
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    for (final q in _questions) {
      q.dispose();
    }
    super.dispose();
  }

  void _addQuestion() => setState(() => _questions.add(_QuestionForm()));

  void _removeQuestion(int i) => setState(() {
        _questions[i].dispose();
        _questions.removeAt(i);
      });

  Future<void> _save() async {
    if (_subjectId == null || _titleController.text.trim().isEmpty) {
      setState(() => _error = 'Pick a subject and enter a title');
      return;
    }
    for (final q in _questions) {
      if (q.textController.text.trim().isEmpty || q.optionControllers.any((c) => c.text.trim().isEmpty)) {
        setState(() => _error = 'Fill in every question and all 4 options');
        return;
      }
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await Api.authedPost('/quizzes', {
        'subject_id': _subjectId,
        'title': _titleController.text.trim(),
        'questions': [
          for (final q in _questions)
            {
              'text': q.textController.text.trim(),
              'options': q.optionControllers.map((c) => c.text.trim()).toList(),
              'correct_option': q.correct,
            },
        ],
      });
      if (!mounted) return;
      if (res.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Could not save quiz. Please try again.');
      }
    } catch (_) {
      setState(() => _error = 'Could not save quiz. Check your connection.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create quiz')),
      body: CenteredMaxWidth(
        maxWidth: 700,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            DropdownButtonFormField<int>(
              initialValue: _subjectId,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [for (final s in widget.subjects) DropdownMenuItem(value: s['id'] as int, child: Text(s['name'].toString()))],
              onChanged: (v) => setState(() => _subjectId = v),
            ),
            const SizedBox(height: Spacing.md),
            AppTextField(label: 'Quiz title', controller: _titleController),
            const SizedBox(height: Spacing.xl),
            for (var i = 0; i < _questions.length; i++) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Question ${i + 1}', style: Theme.of(context).textTheme.titleMedium),
                        if (_questions.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                            onPressed: () => _removeQuestion(i),
                          ),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    AppTextField(label: 'Question text', controller: _questions[i].textController),
                    const SizedBox(height: Spacing.md),
                    Text(
                      'Tap the circle next to the correct option',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                    ),
                    RadioGroup<int>(
                      groupValue: _questions[i].correct,
                      onChanged: (v) => setState(() => _questions[i].correct = v ?? 0),
                      child: Column(
                        children: [
                          for (var o = 0; o < 4; o++)
                            Padding(
                              padding: const EdgeInsets.only(top: Spacing.sm),
                              child: Row(
                                children: [
                                  Radio<int>(value: o),
                                  Expanded(
                                    child: AppTextField(label: 'Option ${o + 1}', controller: _questions[i].optionControllers[o]),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
            OutlinedButton.icon(onPressed: _addQuestion, icon: const Icon(Icons.add_rounded), label: const Text('Add question')),
            if (_error != null) ...[
              const SizedBox(height: Spacing.md),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: Spacing.xl),
            PrimaryButton(label: 'Save quiz', onPressed: _save, loading: _submitting),
            const SizedBox(height: Spacing.xxl),
          ],
        ),
      ),
    );
  }
}
