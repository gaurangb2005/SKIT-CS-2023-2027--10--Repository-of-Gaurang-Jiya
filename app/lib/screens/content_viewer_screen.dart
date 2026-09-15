import 'package:flutter/material.dart';

import '../services/api.dart';
import '../theme.dart';
import '../utils/file_picker.dart';
import '../widgets/learning_widgets.dart';
import '../widgets/widgets.dart';

class ContentViewerScreen extends StatelessWidget {
  final Map<String, dynamic> content;

  const ContentViewerScreen({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final type = content['type']?.toString() ?? 'notes';
    final title = content['title']?.toString() ?? '';
    final fileUrl = content['file_url']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: CenteredMaxWidth(
        maxWidth: 800,
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: switch (type) {
            'notes' => _NotesView(text: fileUrl),
            'image' => _ImageView(url: Api.fileUrl(fileUrl)),
            'pdf' => _LinkView(label: 'Open PDF', icon: Icons.picture_as_pdf_rounded, url: Api.fileUrl(fileUrl)),
            'video' => _LinkView(label: 'Open video', icon: Icons.play_circle_rounded, url: fileUrl),
            _ => const EmptyState(icon: Icons.description_rounded, message: 'This content type is not supported yet.'),
          },
        ),
      ),
    );
  }
}

class _NotesView extends StatelessWidget {
  final String text;
  const _NotesView({required this.text});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: AppCard(
        padding: const EdgeInsets.all(Spacing.xl),
        child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}

class _ImageView extends StatelessWidget {
  final String url;
  const _ImageView({required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InteractiveViewer(
        maxScale: 4,
        child: Image.network(
          url,
          errorBuilder: (context, error, stack) =>
              const ErrorState(message: 'Could not load this image.', onRetry: _noop),
        ),
      ),
    );
  }

  static void _noop() {}
}

class _LinkView extends StatelessWidget {
  final String label;
  final IconData icon;
  final String url;
  const _LinkView({required this.label, required this.icon, required this.url});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: Spacing.lg),
          PrimaryButton(label: label, onPressed: () => openInNewTab(url)),
        ],
      ),
    );
  }
}
