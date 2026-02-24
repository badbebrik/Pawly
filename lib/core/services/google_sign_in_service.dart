import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../constants/google_auth_constants.dart';

class GoogleSignInCancelledException implements Exception {
  const GoogleSignInCancelledException();
}

abstract class GoogleSignInService {
  Future<String?> getIdToken();
  Future<void> signOut();
}

class AppGoogleSignInService implements GoogleSignInService {
  AppGoogleSignInService({GoogleSignIn? googleSignIn})
      : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final GoogleSignIn _googleSignIn;
  Future<void>? _initializeFuture;

  @override
  Future<String?> getIdToken() async {
    await _ensureInitialized();

    try {
      final GoogleSignInAccount account;

      final cachedAccount =
          await _googleSignIn.attemptLightweightAuthentication(
        reportAllExceptions: false,
      );

      if (cachedAccount != null) {
        account = cachedAccount;
      } else {
        account = await _googleSignIn.authenticate(
          scopeHint: const <String>['email', 'openid'],
        );
      }

      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google не вернул id_token. Проверьте GOOGLE_SERVER_CLIENT_ID и OAuth-конфигурацию.',
        );
      }

      return idToken;
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw const GoogleSignInCancelledException();
      }

      throw StateError(
        error.description ??
            'Google Sign-In настроен некорректно. Проверьте client IDs и SHA-1.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    if (_initializeFuture == null) {
      return;
    }

    try {
      await _ensureInitialized();
      await _googleSignIn.signOut();
    } on GoogleSignInException {
      return;
    }
  }

  Future<void> _ensureInitialized() {
    return _initializeFuture ??= _initialize();
  }

  Future<void> _initialize() async {
    if (kIsWeb) {
      throw StateError(
          'Google Sign-In пока настроен только для мобильных платформ.');
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (!GoogleAuthConstants.hasServerClientId) {
        throw StateError(
          'Для Android Google Sign-In нужен GOOGLE_SERVER_CLIENT_ID (Web OAuth client).',
        );
      }

      await _googleSignIn.initialize(
        serverClientId: GoogleAuthConstants.serverClientId,
      );
      return;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _googleSignIn.initialize(
        clientId: GoogleAuthConstants.iosClientId,
        serverClientId: GoogleAuthConstants.hasServerClientId
            ? GoogleAuthConstants.serverClientId
            : null,
      );
      return;
    }

    throw StateError('Google Sign-In не поддерживается на этой платформе.');
  }
}
