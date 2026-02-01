import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService(this._storage);

  static const String accessTokenKey = 'access_token';
  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() {
    return _storage.read(key: accessTokenKey);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: accessTokenKey);
  }
}
