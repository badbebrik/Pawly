import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

import '../api_context.dart';
import '../session/auth_session_store.dart';

class ApiContextInterceptor extends Interceptor {
  ApiContextInterceptor(this._sessionStore);

  final AuthSessionStore _sessionStore;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final session = await _sessionStore.read();
    final extra = options.extra;

    final includeLocale = extra[ApiContextKeys.includeLocale] != false;
    final includeAcceptLanguage =
        extra[ApiContextKeys.includeAcceptLanguage] == true;
    final requiresUserId = extra[ApiContextKeys.requiresUserId] == true;
    final requiresAccessToken =
        extra[ApiContextKeys.requiresAccessToken] == true;

    if (includeLocale && session?.locale.isNotEmpty == true) {
      options.headers['X-Locale'] = session!.locale;
    }

    if (includeAcceptLanguage && session?.locale.isNotEmpty == true) {
      options.headers['Accept-Language'] = session!.locale;
    }

    if (requiresUserId) {
      final userId = session?.userId;
      if (userId == null || userId.isEmpty) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: StateError('X-User-ID is required for this request'),
          ),
        );
      }
      options.headers['X-User-ID'] = userId;
    }

    final accessToken = session?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers.putIfAbsent('Authorization', () => 'Bearer $accessToken');
    } else if (requiresAccessToken) {
      _logBootstrapRequest(
        options,
        sessionAvailable: session != null,
        userIdPresent: session?.userId.isNotEmpty == true,
        accessTokenPresent: false,
      );
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('Access token is required for this request'),
        ),
      );
    }

    _logBootstrapRequest(
      options,
      sessionAvailable: session != null,
      userIdPresent: session?.userId.isNotEmpty == true,
      accessTokenPresent: accessToken?.isNotEmpty == true,
    );

    handler.next(options);
  }

  void _logBootstrapRequest(
    RequestOptions options, {
    required bool sessionAvailable,
    required bool userIdPresent,
    required bool accessTokenPresent,
  }) {
    if (!_isLogsBootstrapRequest(options.path)) {
      return;
    }

    final authorization = options.headers['Authorization']?.toString();
    final userId = options.headers['X-User-ID']?.toString();
    debugPrint(
      '[HealthBootstrap][onRequest] ${options.method} ${options.path} '
      'session=$sessionAvailable '
      'sessionUserId=$userIdPresent '
      'sessionAccessToken=$accessTokenPresent '
      'requiresUserId=${options.extra[ApiContextKeys.requiresUserId] == true} '
      'requiresAccessToken=${options.extra[ApiContextKeys.requiresAccessToken] == true} '
      'authHeader=${authorization != null} '
      'authBearer=${authorization?.startsWith('Bearer ') == true} '
      'authPreview=${_maskAuthorization(authorization)} '
      'xUserIdHeader=${userId != null && userId.isNotEmpty} '
      'headerKeys=${options.headers.keys.toList()}',
    );
  }

  bool _isLogsBootstrapRequest(String path) => path.contains('/logs/bootstrap');

  String _maskAuthorization(String? authorization) {
    if (authorization == null || authorization.isEmpty) {
      return '<none>';
    }
    if (!authorization.startsWith('Bearer ')) {
      return authorization;
    }

    final token = authorization.substring('Bearer '.length);
    final visible = token.length <= 10 ? token : '${token.substring(0, 10)}...';
    return 'Bearer $visible';
  }
}
