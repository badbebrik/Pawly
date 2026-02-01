import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../network/session/auth_session.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String localeKey = 'locale';

  final FlutterSecureStorage _storage;

  Future<void> saveSession(AuthSession session) async {
    await _storage.write(key: accessTokenKey, value: session.accessToken);
    await _storage.write(key: refreshTokenKey, value: session.refreshToken);
    await _storage.write(key: userIdKey, value: session.userId);
    await _storage.write(key: localeKey, value: session.locale);
  }

  Future<AuthSession?> readSession() async {
    final values = await _storage.readAll();
    final accessToken = values[accessTokenKey];
    final refreshToken = values[refreshTokenKey];
    final userId = values[userIdKey];

    if (accessToken == null || refreshToken == null || userId == null) {
      return null;
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      locale: values[localeKey] ?? 'ru',
    );
  }

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) {
    return _storage.write(key: refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() {
    return _storage.read(key: refreshTokenKey);
  }

  Future<void> saveUserId(String userId) {
    return _storage.write(key: userIdKey, value: userId);
  }

  Future<String?> getUserId() {
    return _storage.read(key: userIdKey);
  }

  Future<void> saveLocale(String locale) {
    return _storage.write(key: localeKey, value: locale);
  }

  Future<String?> getLocale() {
    return _storage.read(key: localeKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
    await _storage.delete(key: refreshTokenKey);
    await _storage.delete(key: userIdKey);
    await _storage.delete(key: localeKey);
  }

  Future<void> writeJson(String key, Map<String, dynamic> payload) {
    return _storage.write(key: key, value: jsonEncode(payload));
  }

  Future<Map<String, dynamic>?> readJson(String key) async {
    final raw = await _storage.read(key: key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return null;
  }
}
