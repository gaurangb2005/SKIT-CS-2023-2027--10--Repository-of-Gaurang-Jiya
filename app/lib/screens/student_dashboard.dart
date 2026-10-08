import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../services/token_storage.dart';
import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/level_progress.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/widgets.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _index = 0;

  static const _items = [
    NavItem(Icons.menu_book_rounded, 'Learn'),
    NavItem(Icons.sports_esports_rounded, 'Games'),
    NavItem(Icons.quiz_rounded, 'Quiz'),
    NavItem(Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const _LearnTab(),
      const _ComingSoonTab(label: 'Games'),
      const _QuizSubjectsTab(),
      const _ProfileTab(),
    ];
    return ResponsiveShell(
      title: 'Student',
      items: _items,
      currentIndex: _index,
      onTap: (i) => setState(() => _index = i),
      body: tabs[_index],
    );
  }
}

int _totalXpFrom(List<dynamic> attempts) =>
    attempts.fold<int>(0, (sum, a) => sum + ((a['xp_earned'] as int?) ?? 0));

class _ComingSoonTab extends StatelessWidget {
  final String label;
  const _ComingSoonTab({required this.label});

  @override
  Widget build(BuildContext context) {
    return EmptyState(icon: Icons.construction_rounded, message: '$label are coming in a later sprint.');
  }
}

class _QuizSubjectsTab extends StatefulWidget {
  const _QuizSubjectsTab();

  @override
  State<_QuizSubjectsTab> createState() => _QuizSubjectsTabState();
}

class _QuizSubjectsTabState extends State<_QuizSubjectsTab> {
  List<dynamic>? _subjects;
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
      final res = await Api.authedGet('/subjects');
      if (res.statusCode != 200) {
        setState(() => _error = 'Could not load subjects.');
        return;
      }
      setState(() => _subjects = Api.decodeList(res));
    } catch (_) {
      setState(() => _error = 'Could not load subjects. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _subjects == null) {
      return ListView(padding: const EdgeInsets.all(Spacing.lg), children: const [LoadingSkeleton(height: 160)]);
    }
    if (_error != null && _subjects == null) {
      return ErrorState(message: _error!, onRetry: _load);
    }
    final subjects = _subjects ?? [];
    if (subjects.isEmpty) {
      return const EmptyState(icon: Icons.quiz_rounded, message: 'No subjects yet.');
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text('Pick a subject to see its quizzes', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = (constraints.maxWidth / 180).floor().clamp(2, 5);
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: Spacing.md,
                  crossAxisSpacing: Spacing.md,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, i) {
                  final s = subjects[i] as Map<String, dynamic>;
                  return SubjectCard(
                    name: s['name']?.toString() ?? '',
                    subtitle: 'Tap to see quizzes',
                    onTap: () => context.push('/student/quizzes/${s['id']}', extra: s['name']),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LearnTab extends StatefulWidget {
  const _LearnTab();

  @override
  State<_LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<_LearnTab> {
  Map<String, dynamic>? _dashboard;
  String _name = '';
  int _totalXp = 0;
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
      final results = await Future.wait([
        Api.authedGet('/users/me'),
        Api.authedGet('/dashboard/student'),
        Api.authedGet('/quizzes/history/me'),
      ]);
      final me = results[0];
      final dash = results[1];
      final history = results[2];
      if (me.statusCode != 200 || dash.statusCode != 200) {
        setState(() => _error = 'Could not load your dashboard.');
        return;
      }
      final attempts = history.statusCode == 200 ? Api.decodeList(history) : [];
      setState(() {
        _name = (Api.decode(me)['name'] as String?) ?? 'Student';
        _dashboard = Api.decode(dash);
        _totalXp = _totalXpFrom(attempts);
      });
    } catch (_) {
      setState(() => _error = 'Could not load your dashboard. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _dashboard == null) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: const [
          LoadingSkeleton(height: 90),
          SizedBox(height: Spacing.lg),
          LoadingSkeleton(height: 160),
        ],
      );
    }
    if (_error != null && _dashboard == null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    final subjects = (_dashboard?['subjects'] as List?) ?? [];
    final recent = (_dashboard?['recent_content'] as List?) ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text('Hi, $_name 👋', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: Spacing.lg),
          LevelProgress(xp: _totalXp),
          const SizedBox(height: Spacing.xl),
          if (recent.isNotEmpty) ...[
            Text('Continue learning', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recent.length,
                separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
                itemBuilder: (context, i) {
                  final c = recent[i] as Map<String, dynamic>;
                  return SizedBox(
                    width: 220,
                    child: AppCard(
                      onTap: () => context.push('/student/content', extra: c),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            c['title']?.toString() ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: Spacing.xs),
                          Text(
                            (c['type']?.toString() ?? '').toUpperCase(),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: Spacing.xl),
          ],
          Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          if (subjects.isEmpty)
            const EmptyState(icon: Icons.menu_book_rounded, message: 'No subjects yet. Check back soon!')
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = (constraints.maxWidth / 180).floor().clamp(2, 5);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: Spacing.md,
                    crossAxisSpacing: Spacing.md,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (context, i) {
                    final s = subjects[i] as Map<String, dynamic>;
                    return SubjectCard(
                      name: s['name']?.toString() ?? '',
                      contentCount: (s['content_count'] as int?) ?? 0,
                      onTap: () => context.push('/student/subject/${s['id']}', extra: s['name']),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  Map<String, dynamic>? _me;
  List<dynamic> _attempts = [];
  bool _loading = true;
  String? _error;
  bool _editing = false;

  final _nameController = TextEditingController();
  final _schoolController = TextEditingController();
  int _grade = 1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _schoolController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await Api.authedGet('/users/me');
      if (res.statusCode != 200) {
        setState(() => _error = 'Could not load your profile.');
        return;
      }
      final me = Api.decode(res);
      final history = await Api.authedGet('/quizzes/history/me');
      setState(() {
        _me = me;
        _nameController.text = (me['name'] as String?) ?? '';
        _schoolController.text = (me['school'] as String?) ?? '';
        _grade = int.tryParse(me['grade']?.toString() ?? '') ?? 1;
        _attempts = history.statusCode == 200 ? Api.decodeList(history) : [];
      });
    } catch (_) {
      setState(() => _error = 'Could not load your profile.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final res = await Api.authedPatch('/users/me', {
      'name': _nameController.text.trim(),
      'grade': '$_grade',
      'school': _schoolController.text.trim(),
    });
    if (!mounted) return;
    if (res.statusCode == 200) {
      setState(() {
        _me = Api.decode(res);
        _editing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update profile')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _me == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _me == null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    final name = (_me?['name'] as String?) ?? '';
    final grade = _me?['grade'];
    final school = _me?['school'] as String?;
    final totalXp = _totalXpFrom(_attempts);

    return ListView(
      padding: const EdgeInsets.all(Spacing.lg),
      children: [
        Center(
          child: CircleAvatar(
            radius: 40,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
            ),
          ),
        ),
        const SizedBox(height: Spacing.lg),
        if (!_editing) ...[
          Center(child: Text(name, style: Theme.of(context).textTheme.titleLarge)),
          const SizedBox(height: Spacing.xs),
          if (grade != null) Center(child: Text('Class $grade', style: Theme.of(context).textTheme.bodyLarge)),
          if (school != null && school.isNotEmpty)
            Center(
              child: Text(school, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600)),
            ),
          const SizedBox(height: Spacing.lg),
          LevelProgress(xp: totalXp),
          const SizedBox(height: Spacing.xl),
          PrimaryButton(label: 'Edit profile', onPressed: () => setState(() => _editing = true)),
          const SizedBox(height: Spacing.xl),
          Text('Recent attempts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          if (_attempts.isEmpty)
            const EmptyState(icon: Icons.history_rounded, message: 'No quiz attempts yet.')
          else
            for (final a in _attempts.take(5)) ...[
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        a['quiz_title']?.toString() ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text('${a['score']}/${a['total']}', style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.sm),
            ],
        ] else ...[
          AppTextField(label: 'Name', controller: _nameController),
          const SizedBox(height: Spacing.md),
          DropdownButtonFormField<int>(
            initialValue: _grade,
            decoration: const InputDecoration(labelText: 'Class / Grade'),
            items: [for (var g = 1; g <= 12; g++) DropdownMenuItem(value: g, child: Text('Class $g'))],
            onChanged: (v) => setState(() => _grade = v ?? _grade),
          ),
          const SizedBox(height: Spacing.md),
          AppTextField(label: 'School', controller: _schoolController),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(child: OutlinedButton(onPressed: () => setState(() => _editing = false), child: const Text('Cancel'))),
              const SizedBox(width: Spacing.md),
              Expanded(child: PrimaryButton(label: 'Save', onPressed: _save)),
            ],
          ),
        ],
        const SizedBox(height: Spacing.xxl),
        PrimaryButton(label: 'Logout', onPressed: () => TokenStorage.logout(context)),
      ],
    );
  }
}
