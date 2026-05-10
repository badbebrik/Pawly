import 'dart:async';

import '../../../core/network/api_exception.dart';
import '../../../core/network/clients/auth_api_client.dart';
import '../../../core/network/models/auth_models.dart';
import '../../../core/network/models/common_models.dart';
import '../../../core/network/session/auth_session.dart';
import '../../../core/network/session/auth_session_store.dart';
import '../../../core/services/device_preferences_service.dart';
import '../../../core/services/google_sign_in_service.dart';
import '../../../core/services/push_notifications_service.dart';
import '../../../core/storage/shared_preferences_service.dart';

class AuthRepository {
  AuthRepository({
    required AuthApiClient authApiClient,
    required AuthSessionStore authSessionStore,
    required DevicePreferencesService devicePreferencesService,
    required GoogleSignInService googleSignInService,
    required PushNotificationsService pushNotificationsService,
    required SharedPreferencesService sharedPreferencesService,
  })  : _authApiClient = authApiClient,
        _authSessionStore = authSessionStore,
        _devicePreferencesService = devicePreferencesService,
        _googleSignInService = googleSignInService,
        _pushNotificationsService = pushNotificationsService,
        _sharedPreferencesService = sharedPreferencesService;

  final AuthApiClient _authApiClient;
  final AuthSessionStore _authSessionStore;
  final DevicePreferencesService _devicePreferencesService;
  final GoogleSignInService _googleSignInService;
  final PushNotificationsService _pushNotificationsService;
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
        locale: 'ru',
      );
      _syncPushTokenInBackground();

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
    _syncPushTokenInBackground();
  }

  Future<void> loginWithGoogle() async {
    final devicePreferences = await _devicePreferencesService.read();
    final idToken = await _googleSignInService.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google Sign-In не настроен в этой сборке.');
    }

    final tokens = await _authApiClient.loginByOAuth(
      LoginOAuthRequest(
        provider: 'google',
        idToken: idToken,
        locale: devicePreferences.locale,
        timeZone: devicePreferences.timeZone,
      ),
    );

    await _persistTokens(tokens, locale: devicePreferences.locale);
    _syncPushTokenInBackground();
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
    _syncPushTokenInBackground();
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

    await _pushNotificationsService.unregisterCurrentDevice();
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

    await _pushNotificationsService.unregisterCurrentDevice();
    await _googleSignInService.signOut();
    await _authSessionStore.clear();
    await _sharedPreferencesService.clearProfilePreferences();

    return response;
  }

  Future<void> logout() async {
    await _pushNotificationsService.unregisterCurrentDevice();
    try {
      await _authApiClient.logout();
    } catch (_) {}

    await _googleSignInService.signOut();
    await _authSessionStore.clear();
    await _sharedPreferencesService.clearProfilePreferences();
  }

  Future<void> logoutAll() async {
    await _pushNotificationsService.unregisterCurrentDevice();
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
  }) async {
    await _authSessionStore.write(
      AuthSession(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
        userId: tokens.userId,
        locale: locale,
      ),
    );
  }

  void _syncPushTokenInBackground() {
    unawaited(
      _pushNotificationsService.syncTokenForCurrentSession().catchError((_) {}),
    );
  }
}
