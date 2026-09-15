import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/api.dart';
import '../theme.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/widgets.dart';

const _typeIcons = {
  'pdf': Icons.picture_as_pdf_rounded,
  'image': Icons.image_rounded,
  'video': Icons.play_circle_rounded,
  'notes': Icons.notes_rounded,
};

class SubjectScreen extends StatefulWidget {
  final int subjectId;
  final String subjectName;

  const SubjectScreen({super.key, required this.subjectId, required this.subjectName});

  @override
  State<SubjectScreen> createState() => _SubjectScreenState();
}

class _SubjectScreenState extends State<SubjectScreen> {
  List<dynamic>? _content;
  bool _loading = true;
  String? _error;
  String _filter = 'all';

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
      final res = await Api.authedGet('/content?subject_id=${widget.subjectId}&limit=100');
      if (res.statusCode != 200) {
        setState(() => _error = 'Could not load materials.');
        return;
      }
      setState(() => _content = Api.decodeList(res));
    } catch (_) {
      setState(() => _error = 'Could not load materials. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = subjectStyleFor(widget.subjectName);

    Widget body;
    if (_loading && _content == null) {
      body = ListView.separated(
        padding: const EdgeInsets.all(Spacing.lg),
        itemCount: 4,
        separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
        itemBuilder: (_, _) => const LoadingSkeleton(height: 64),
      );
    } else if (_error != null && _content == null) {
      body = ErrorState(message: _error!, onRetry: _load);
    } else {
      final items = _content ?? [];
      final filtered = _filter == 'all' ? items : items.where((c) => c['type'] == _filter).toList();

      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            Wrap(
              spacing: Spacing.sm,
              children: [
                for (final entry in {'all': 'All', 'notes': 'Notes', 'pdf': 'PDF', 'image': 'Image', 'video': 'Video'}.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: _filter == entry.key,
                    onSelected: (_) => setState(() => _filter = entry.key),
                  ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            if (filtered.isEmpty)
              const EmptyState(icon: Icons.folder_open_rounded, message: 'No materials here yet.')
            else
              for (final c in filtered) ...[
                AppCard(
                  onTap: () => context.push('/student/content', extra: c),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(color: style.color.withValues(alpha: 0.15), borderRadius: AppRadius.sm),
                        child: Icon(_typeIcons[c['type']] ?? Icons.description_rounded, color: style.color),
                      ),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Text(
                          c['title']?.toString() ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.md),
              ],
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.subjectName)),
      body: CenteredMaxWidth(child: body),
    );
  }
}
