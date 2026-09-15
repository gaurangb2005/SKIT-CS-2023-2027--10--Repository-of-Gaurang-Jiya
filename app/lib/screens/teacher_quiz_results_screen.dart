import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/widgets.dart';

class TeacherQuizResultsScreen extends StatefulWidget {
  final int quizId;
  final String quizTitle;

  const TeacherQuizResultsScreen({super.key, required this.quizId, required this.quizTitle});

  @override
  State<TeacherQuizResultsScreen> createState() => _TeacherQuizResultsScreenState();
}

class _TeacherQuizResultsScreenState extends State<TeacherQuizResultsScreen> {
  List<dynamic>? _attempts;
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
      final res = await Api.authedGet('/quizzes/${widget.quizId}/attempts');
      if (res.statusCode != 200) {
        setState(() => _error = 'Could not load results.');
        return;
      }
      setState(() => _attempts = Api.decodeList(res));
    } catch (_) {
      setState(() => _error = 'Could not load results. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading && _attempts == null) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _attempts == null) {
      body = ErrorState(message: _error!, onRetry: _load);
    } else {
      final attempts = _attempts ?? [];
      body = attempts.isEmpty
          ? const EmptyState(icon: Icons.bar_chart_rounded, message: 'No attempts yet.')
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(Spacing.lg),
                itemCount: attempts.length,
                separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
                itemBuilder: (context, i) {
                  final a = attempts[i] as Map<String, dynamic>;
                  return AppCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(a['student_name']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
                        ),
                        Text('${a['score']}/${a['total']}', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  );
                },
              ),
            );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${widget.quizTitle} Results')),
      body: CenteredMaxWidth(child: body),
    );
  }
}
