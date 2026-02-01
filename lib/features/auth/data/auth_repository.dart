import '../../../core/network/api_exception.dart';
import '../../../core/network/clients/auth_api_client.dart';
import '../../../core/network/models/auth_models.dart';
import '../../../core/network/session/auth_session.dart';
import '../../../core/network/session/auth_session_store.dart';

class AuthRepository {
  AuthRepository({
    required AuthApiClient authApiClient,
    required AuthSessionStore authSessionStore,
  })  : _authApiClient = authApiClient,
        _authSessionStore = authSessionStore;

  final AuthApiClient _authApiClient;
  final AuthSessionStore _authSessionStore;

  Future<bool> tryRestoreSession() async {
    final existingSession = await _authSessionStore.read();
    if (existingSession == null || existingSession.refreshToken.isEmpty) {
      return false;
    }

    try {
      final refreshed = await _authApiClient.refresh(
        RefreshTokenPayload(refreshToken: existingSession.refreshToken),
      );

      await _persistTokens(
        refreshed,
        locale: existingSession.locale,
      );

      return true;
    } on ApiException {
      await _authSessionStore.clear();
      return false;
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final tokens = await _authApiClient.loginByEmail(
      LoginEmailRequest(email: email, password: password),
    );

    await _persistTokens(tokens);
  }

  Future<void> loginWithGoogle({required String idToken}) async {
    final tokens = await _authApiClient.loginByOAuth(
      LoginOAuthRequest(provider: 'google', idToken: idToken),
    );

    await _persistTokens(tokens);
  }

  Future<RegisterEmailResponse> registerWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) {
    return _authApiClient.registerByEmail(
      RegisterEmailRequest(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final tokens = await _authApiClient.verifyEmail(
      VerifyEmailRequest(email: email, code: code),
    );

    await _persistTokens(tokens);
  }

  Future<void> logout() async {
    try {
      await _authApiClient.logout();
    } catch (_) {
      // Clear local session even if backend logout fails.
    }

    await _authSessionStore.clear();
  }

  Future<void> _persistTokens(
    AuthTokensResponse tokens, {
    String locale = 'ru',
  }) {
    return _authSessionStore.write(
      AuthSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        locale: locale,
      ),
    );
  }
}
