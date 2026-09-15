import 'dart:convert';
import 'package:http/http.dart' as http;

import 'token_storage.dart';

class Api {
  static const serverRoot = 'http://localhost:8000';
  static const baseUrl = '$serverRoot/api/v1';

  /// Resolves a backend-relative file path (e.g. "/uploads/x.pdf") to a full
  /// URL; leaves already-absolute links (external video URLs) untouched.
  static String fileUrl(String path) => path.startsWith('/') ? '$serverRoot$path' : path;

  static Future<http.Response> get(String path, {String? token}) {
    return http.get(Uri.parse('$baseUrl$path'), headers: _headers(token));
  }

  static Future<http.Response> post(String path, Map<String, dynamic> body, {String? token}) {
    return http.post(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
  }

  static Future<http.Response> patch(String path, Map<String, dynamic> body, {String? token}) {
    return http.patch(Uri.parse('$baseUrl$path'), headers: _headers(token), body: jsonEncode(body));
  }

  static Future<http.Response> delete(String path, {String? token}) {
    return http.delete(Uri.parse('$baseUrl$path'), headers: _headers(token));
  }

  /// Multipart POST, used for content uploads (form fields + an optional file).
  static Future<http.Response> postMultipart(
    String path, {
    required Map<String, String> fields,
    http.MultipartFile? file,
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$path'))..fields.addAll(fields);
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (file != null) request.files.add(file);
    final streamed = await request.send();
    return http.Response.fromStream(streamed);
  }

  // Convenience wrappers that read the stored JWT, since almost every screen
  // after login needs an authenticated call.
  static Future<http.Response> authedGet(String path) async => get(path, token: await TokenStorage.readToken());

  static Future<http.Response> authedPost(String path, Map<String, dynamic> body) async =>
      post(path, body, token: await TokenStorage.readToken());

  static Future<http.Response> authedPatch(String path, Map<String, dynamic> body) async =>
      patch(path, body, token: await TokenStorage.readToken());

  static Future<http.Response> authedDelete(String path) async => delete(path, token: await TokenStorage.readToken());

  static Future<http.Response> authedPostMultipart(String path, {required Map<String, String> fields, http.MultipartFile? file}) async =>
      postMultipart(path, fields: fields, file: file, token: await TokenStorage.readToken());

  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Map<String, dynamic> decode(http.Response res) => jsonDecode(res.body) as Map<String, dynamic>;
  static List<dynamic> decodeList(http.Response res) => jsonDecode(res.body) as List<dynamic>;
}
