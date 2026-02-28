import '../../../core/network/api_exception.dart';
import '../../../core/network/clients/auth_api_client.dart';
import '../../../core/network/models/auth_models.dart';
import '../../../core/network/models/common_models.dart';
import '../../../core/network/session/auth_session.dart';
import '../../../core/network/session/auth_session_store.dart';
import '../../../core/services/device_preferences_service.dart';
import '../../../core/services/google_sign_in_service.dart';
import '../../../core/storage/shared_preferences_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthApiClient authApiClient,
    required AuthSessionStore authSessionStore,
    required DevicePreferencesService devicePreferencesService,
    required GoogleSignInService googleSignInService,
    required SharedPreferencesService sharedPreferencesService,
  })  : _authApiClient = authApiClient,
        _authSessionStore = authSessionStore,
        _devicePreferencesService = devicePreferencesService,
        _googleSignInService = googleSignInService,
        _sharedPreferencesService = sharedPreferencesService;

  final AuthApiClient _authApiClient;
  final AuthSessionStore _authSessionStore;
  final DevicePreferencesService _devicePreferencesService;
  final GoogleSignInService _googleSignInService;
  final SharedPreferencesService _sharedPreferencesService;

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
    final devicePreferences = await _devicePreferencesService.read();
    final tokens = await _authApiClient.loginByEmail(
      LoginEmailRequest(email: email, password: password),
    );

    await _persistTokens(tokens, locale: devicePreferences.locale);
  }

  Future<void> loginWithGoogle({required String idToken}) async {
    final devicePreferences = await _devicePreferencesService.read();
    final tokens = await _authApiClient.loginByOAuth(
      LoginOAuthRequest(provider: 'google', idToken: idToken),
    );

    await _persistTokens(tokens, locale: devicePreferences.locale);
  }

  Future<RegisterEmailResponse> registerWithEmail({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    final devicePreferences = await _devicePreferencesService.read();
    return _authApiClient.registerByEmail(
      RegisterEmailRequest(
        email: email,
        password: password,
        locale: devicePreferences.locale,
        timeZone: devicePreferences.timeZone,
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  Future<RegisterEmailResponse> resendEmailVerificationCode({
    required String email,
  }) {
    return _authApiClient.resendEmailVerificationCode(
      ResendEmailVerificationRequest(email: email),
    );
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    final devicePreferences = await _devicePreferencesService.read();
    final tokens = await _authApiClient.verifyEmail(
      VerifyEmailRequest(email: email, code: code),
    );

    await _persistTokens(tokens, locale: devicePreferences.locale);
  }

  Future<StatusResponse> requestPasswordReset({
    required String email,
  }) {
    return _authApiClient.requestPasswordReset(
      PasswordResetRequestPayload(email: email),
    );
  }

  Future<PasswordResetVerifyResponse> verifyPasswordResetCode({
    required String email,
    required String code,
  }) {
    return _authApiClient.verifyPasswordResetCode(
      PasswordResetVerifyPayload(email: email, code: code),
    );
  }

  Future<StatusResponse> confirmPasswordReset({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _authApiClient.confirmPasswordReset(
      PasswordResetConfirmPayload(
        resetToken: resetToken,
        newPassword: newPassword,
      ),
    );

    await _googleSignInService.signOut();
    await _authSessionStore.clear();
    await _sharedPreferencesService.clearProfilePreferences();

    return response;
  }

  Future<StatusResponse> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final response = await _authApiClient.changePassword(
      PasswordChangePayload(
        oldPassword: oldPassword,
        newPassword: newPassword,
      ),
    );

    await _googleSignInService.signOut();
    await _authSessionStore.clear();
    await _sharedPreferencesService.clearProfilePreferences();

    return response;
  }

  Future<void> logout() async {
    try {
      await _authApiClient.logout();
    } catch (_) {}

    await _googleSignInService.signOut();
    await _authSessionStore.clear();
    await _sharedPreferencesService.clearProfilePreferences();
  }

  Future<void> logoutAll() async {
    try {
      await _authApiClient.logoutAll();
    } catch (_) {}

    await _googleSignInService.signOut();
    await _authSessionStore.clear();
    await _sharedPreferencesService.clearProfilePreferences();
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
