import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'jwt_token';
  static const _roleKey = 'role';

  static Future<void> save(String token, String role) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _roleKey, value: role);
  }

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<String?> readRole() => _storage.read(key: _roleKey);

  static Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
  }

  static Future<void> logout(BuildContext context) async {
    await clear();
    if (context.mounted) context.go('/login');
  }
}
