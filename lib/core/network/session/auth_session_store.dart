import '../../storage/secure_storage_service.dart';
import 'auth_session.dart';

class AuthSessionStore {
  AuthSessionStore(this._secureStorageService);

  final SecureStorageService _secureStorageService;
  AuthSession? _cachedSession;

  Future<AuthSession?> read() async {
    if (_cachedSession != null) {
      return _cachedSession;
    }

    _cachedSession = await _secureStorageService.readSession();
    return _cachedSession;
  }

  Future<void> write(AuthSession session) async {
    _cachedSession = session;
    await _secureStorageService.saveSession(session);
  }

  Future<void> clear() async {
    final userId =
        _cachedSession?.userId ?? await _secureStorageService.getUserId();
    _cachedSession = null;
    await _secureStorageService.clearSession();
    if (userId != null && userId.isNotEmpty) {
      await _secureStorageService.clearActivePetId(userId);
    }
  }

  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final current = await read();
    if (current == null) {
      return;
    }

    await write(
      current.copyWith(
        accessToken: accessToken,
        refreshToken: refreshToken,
      ),
    );
  }

  Future<void> updateLocale(String locale) async {
    final current = await read();
    if (current == null) {
      return;
    }

    await write(current.copyWith(locale: locale));
  }
}
