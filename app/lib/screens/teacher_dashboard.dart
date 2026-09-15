import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../services/api.dart';
import '../services/token_storage.dart';
import '../theme.dart';
import '../utils/file_picker.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/responsive_shell.dart';
import '../widgets/widgets.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  Map<String, dynamic>? _dashboard;
  List<dynamic> _subjects = [];
  List<Map<String, dynamic>> _quizzes = [];
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
      // /dashboard/student is open to any authenticated role; it gives us a
      // ready-made subjects+content-count overview without a teacher-only endpoint.
      final dash = await Api.authedGet('/dashboard/student');
      final subjects = await Api.authedGet('/subjects');
      if (dash.statusCode != 200 || subjects.statusCode != 200) {
        setState(() => _error = 'Could not load dashboard.');
        return;
      }
      final subjectList = Api.decodeList(subjects);

      // No "all my quizzes" endpoint exists, so fetch per subject and flatten --
      // tag each with its subject name since the quiz list screen needs it for navigation.
      final quizzes = <Map<String, dynamic>>[];
      for (final s in subjectList) {
        final res = await Api.authedGet('/quizzes?subject_id=${s['id']}');
        if (res.statusCode == 200) {
          for (final q in Api.decodeList(res)) {
            quizzes.add({...q as Map<String, dynamic>, 'subject_name': s['name']});
          }
        }
      }

      setState(() {
        _dashboard = Api.decode(dash);
        _subjects = subjectList;
        _quizzes = quizzes;
      });
    } catch (_) {
      setState(() => _error = 'Could not load dashboard. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _togglePublish(Map<String, dynamic> quiz) async {
    final newState = !(quiz['published'] as bool);
    try {
      final res = await Api.authedPatch('/quizzes/${quiz['id']}/publish?published=$newState', {});
      if (!mounted) return;
      if (res.statusCode == 200) {
        setState(() => quiz['published'] = newState);
        return;
      }
    } catch (_) {
      // fall through to the shared error snackbar below
    }
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update quiz')));
  }

  Future<void> _deleteQuiz(Map<String, dynamic> quiz) async {
    try {
      final res = await Api.authedDelete('/quizzes/${quiz['id']}');
      if (!mounted) return;
      if (res.statusCode == 204) {
        _load();
        return;
      }
    } catch (_) {
      // fall through to the shared error snackbar below
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete quiz (it may already have student attempts)')),
      );
    }
  }

  Future<void> _createQuiz() async {
    final created = await context.push<bool>('/teacher/quiz-create', extra: _subjects);
    if (created == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveShell(
      title: 'Teacher',
      items: const [NavItem(Icons.dashboard_rounded, 'Home')],
      currentIndex: 0,
      onTap: (_) {},
      actions: [IconButton(icon: const Icon(Icons.logout), onPressed: () => TokenStorage.logout(context))],
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading && _dashboard == null) {
      return ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: const [LoadingSkeleton(height: 90), SizedBox(height: Spacing.lg), LoadingSkeleton(height: 220)],
      );
    }
    if (_error != null && _dashboard == null) {
      return ErrorState(message: _error!, onRetry: _load);
    }

    final subjectsWithCount = (_dashboard?['subjects'] as List?) ?? [];
    final totalContent = subjectsWithCount.fold<int>(0, (sum, s) => sum + ((s['content_count'] as int?) ?? 0));

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(Spacing.lg),
        children: [
          Text('Teacher Dashboard', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: Spacing.lg),
          Row(
            children: [
              Expanded(
                child: StatCard(label: 'Subjects', value: '${subjectsWithCount.length}', icon: Icons.menu_book_rounded),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: StatCard(
                  label: 'Content items',
                  value: '$totalContent',
                  icon: Icons.description_rounded,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.xxl),
          Text('Upload material', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Spacing.md),
          AppCard(child: _UploadForm(subjects: _subjects, onUploaded: _load)),
          const SizedBox(height: Spacing.xxl),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quizzes', style: Theme.of(context).textTheme.titleLarge),
              IconButton(icon: const Icon(Icons.add_circle_rounded), onPressed: _subjects.isEmpty ? null : _createQuiz),
            ],
          ),
          const SizedBox(height: Spacing.md),
          if (_quizzes.isEmpty)
            const EmptyState(icon: Icons.quiz_rounded, message: 'No quizzes yet. Create one above.')
          else
            for (final q in _quizzes) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(q['title']?.toString() ?? '', style: Theme.of(context).textTheme.titleMedium),
                              Text(
                                '${q['subject_name']} • ${q['question_count']} questions',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        Switch(value: q['published'] as bool, onChanged: (_) => _togglePublish(q)),
                      ],
                    ),
                    const SizedBox(height: Spacing.sm),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => context.push('/teacher/quiz-results/${q['id']}', extra: q['title']),
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Results'),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                          onPressed: () => _deleteQuiz(q),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
        ],
      ),
    );
  }
}

class _UploadForm extends StatefulWidget {
  final List<dynamic> subjects;
  final VoidCallback onUploaded;
  const _UploadForm({required this.subjects, required this.onUploaded});

  @override
  State<_UploadForm> createState() => _UploadFormState();
}

class _UploadFormState extends State<_UploadForm> {
  int? _subjectId;
  String _type = 'notes';
  final _titleController = TextEditingController();
  final _linkController = TextEditingController();
  PickedFile? _picked;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final accept = _type == 'pdf' ? 'application/pdf' : 'image/*';
    final file = await pickFile(accept);
    if (file != null) setState(() => _picked = file);
  }

  Future<void> _submit() async {
    if (_subjectId == null || _titleController.text.trim().isEmpty) {
      setState(() => _error = 'Pick a subject and enter a title');
      return;
    }
    if ((_type == 'pdf' || _type == 'image') && _picked == null) {
      setState(() => _error = 'Choose a file to upload');
      return;
    }
    if ((_type == 'video' || _type == 'notes') && _linkController.text.trim().isEmpty) {
      setState(() => _error = _type == 'video' ? 'Enter a video link' : 'Enter the notes text');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final res = await Api.authedPostMultipart(
        '/content',
        fields: {
          'subject_id': '$_subjectId',
          'title': _titleController.text.trim(),
          'type': _type,
          if (_linkController.text.trim().isNotEmpty) 'link_or_text': _linkController.text.trim(),
        },
        file: _picked == null
            ? null
            : http.MultipartFile.fromBytes(
                'file',
                _picked!.bytes,
                filename: _picked!.name,
                contentType: MediaType.parse(_picked!.mimeType),
              ),
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        _titleController.clear();
        _linkController.clear();
        setState(() => _picked = null);
        widget.onUploaded();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Material uploaded')));
      } else {
        setState(() => _error = 'Upload failed. Please try again.');
      }
    } catch (_) {
      setState(() => _error = 'Upload failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.subjects.isEmpty) {
      return const Text('No subjects yet — ask an admin to add one first.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _subjectId,
          decoration: const InputDecoration(labelText: 'Subject'),
          items: [for (final s in widget.subjects) DropdownMenuItem(value: s['id'] as int, child: Text(s['name'].toString()))],
          onChanged: (v) => setState(() => _subjectId = v),
        ),
        const SizedBox(height: Spacing.md),
        AppTextField(label: 'Title', controller: _titleController),
        const SizedBox(height: Spacing.md),
        DropdownButtonFormField<String>(
          initialValue: _type,
          decoration: const InputDecoration(labelText: 'Type'),
          items: const [
            DropdownMenuItem(value: 'notes', child: Text('Notes')),
            DropdownMenuItem(value: 'pdf', child: Text('PDF')),
            DropdownMenuItem(value: 'image', child: Text('Image')),
            DropdownMenuItem(value: 'video', child: Text('Video link')),
          ],
          onChanged: (v) => setState(() {
            _type = v ?? _type;
            _picked = null;
          }),
        ),
        const SizedBox(height: Spacing.md),
        if (_type == 'pdf' || _type == 'image')
          OutlinedButton.icon(
            onPressed: _pick,
            icon: const Icon(Icons.upload_file_rounded),
            label: Text(_picked?.name ?? 'Choose file'),
          )
        else
          AppTextField(
            label: _type == 'video' ? 'Video link' : 'Notes text',
            controller: _linkController,
            maxLines: _type == 'notes' ? 4 : 1,
          ),
        if (_error != null) ...[
          const SizedBox(height: Spacing.md),
          Text(_error!, style: const TextStyle(color: AppColors.error)),
        ],
        const SizedBox(height: Spacing.lg),
        PrimaryButton(label: 'Upload', onPressed: _submit, loading: _submitting),
      ],
    );
  }
}
