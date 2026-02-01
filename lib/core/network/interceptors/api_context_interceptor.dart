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

    if (requiresAccessToken) {
      final accessToken = session?.accessToken;
      if (accessToken == null || accessToken.isEmpty) {
        return handler.reject(
          DioException(
            requestOptions: options,
            type: DioExceptionType.unknown,
            error: StateError('Access token is required for this request'),
          ),
        );
      }
      options.headers['Authorization'] = 'Bearer $accessToken';
    }

    handler.next(options);
  }
}
