import 'dart:typed_data';

/// Non-web fallback so `flutter test` (which runs on the Dart VM, not Web)
/// can still compile code that references these APIs. Never actually called
/// outside a browser — see file_picker.dart for the conditional export.
class PickedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;
  const PickedFile({required this.bytes, required this.name, required this.mimeType});
}

Future<PickedFile?> pickFile(String accept) async {
  throw UnsupportedError('File picking is only available on Flutter Web.');
}

void openInNewTab(String url) {
  throw UnsupportedError('Opening links is only available on Flutter Web.');
}
