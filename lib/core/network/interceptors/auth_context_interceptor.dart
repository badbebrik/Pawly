import 'package:dio/dio.dart';

import '../api_context.dart';
import '../session/auth_session_store.dart';

class AuthContextInterceptor extends Interceptor {
  AuthContextInterceptor(this._sessionStore);

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
    final requiresAccessToken =
        extra[ApiContextKeys.requiresAccessToken] == true;

    if (includeLocale && session?.locale.isNotEmpty == true) {
      options.headers['X-Locale'] = session!.locale;
    }

    if (includeAcceptLanguage && session?.locale.isNotEmpty == true) {
      options.headers['Accept-Language'] = session!.locale;
    }

    final accessToken = session?.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      options.headers.putIfAbsent('Authorization', () => 'Bearer $accessToken');
    } else if (requiresAccessToken) {
      return handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.unknown,
          error: StateError('Access token is required for this request'),
        ),
      );
    }

    handler.next(options);
  }
}
