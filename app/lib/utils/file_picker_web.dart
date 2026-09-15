// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
// This app targets Flutter Web only (see CLAUDE.md); dart:html keeps file
// picking / new-tab links dependency-free instead of adding file_picker + url_launcher.
import 'dart:html' as html;
import 'dart:typed_data';

class PickedFile {
  final Uint8List bytes;
  final String name;
  final String mimeType;
  const PickedFile({required this.bytes, required this.name, required this.mimeType});
}

/// Opens the browser's native file picker. No `file_picker` package needed:
/// this app only targets Flutter Web, so a plain HTML file input is enough.
Future<PickedFile?> pickFile(String accept) async {
  final input = html.FileUploadInputElement()..accept = accept;
  input.click();
  await input.onChange.first;
  if (input.files == null || input.files!.isEmpty) return null;
  final file = input.files!.first;

  final reader = html.FileReader();
  reader.readAsArrayBuffer(file);
  await reader.onLoad.first;
  return PickedFile(bytes: reader.result as Uint8List, name: file.name, mimeType: file.type);
}

void openInNewTab(String url) => html.window.open(url, '_blank');
