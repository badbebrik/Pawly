import 'package:dio/dio.dart';

import '../api_context.dart';
import '../api_endpoints.dart';
import '../session/auth_session_store.dart';

class AuthRefreshInterceptor extends Interceptor {
  AuthRefreshInterceptor({
    required Dio dio,
    required Dio refreshDio,
    required AuthSessionStore sessionStore,
  })  : _dio = dio,
        _refreshDio = refreshDio,
        _sessionStore = sessionStore;

  final Dio _dio;
  final Dio _refreshDio;
  final AuthSessionStore _sessionStore;

  Future<bool>? _refreshInFlight;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final responseStatus = err.response?.statusCode;
    final requiresToken =
        err.requestOptions.extra[ApiContextKeys.requiresAccessToken] == true;
    final skipRefresh =
        err.requestOptions.extra[ApiContextKeys.skipTokenRefresh] == true;

    if (responseStatus != 401 || !requiresToken || skipRefresh) {
      return handler.next(err);
    }

    final refreshed = await (_refreshInFlight ??= _refreshAccessToken());
    _refreshInFlight = null;

    if (!refreshed) {
      await _sessionStore.clear();
      return handler.next(err);
    }

    try {
      final session = await _sessionStore.read();
      if (session == null) {
        return handler.next(err);
      }

      final requestOptions = err.requestOptions;
      final options = Options(
        method: requestOptions.method,
        headers: Map<String, dynamic>.from(requestOptions.headers)
          ..['Authorization'] = 'Bearer ${session.accessToken}',
        responseType: requestOptions.responseType,
        contentType: requestOptions.contentType,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
        extra: Map<String, dynamic>.from(requestOptions.extra)
          ..[ApiContextKeys.skipTokenRefresh] = true,
      );

      final response = await _dio.request<Object?>(
        requestOptions.path,
        data: requestOptions.data,
        queryParameters: requestOptions.queryParameters,
        options: options,
      );

      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  Future<bool> _refreshAccessToken() async {
    final session = await _sessionStore.read();
    if (session == null || session.refreshToken.isEmpty) {
      return false;
    }

    try {
      final response = await _refreshDio.post<Object?>(
        ApiEndpoints.authRefresh,
        data: <String, dynamic>{'refresh_token': session.refreshToken},
        options: Options(
          extra: const <String, dynamic>{
            ApiContextKeys.skipTokenRefresh: true,
          },
        ),
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return false;
      }

      final accessToken = data['access_token']?.toString();
      final refreshToken = data['refresh_token']?.toString();

      if (accessToken == null || refreshToken == null) {
        return false;
      }

      await _sessionStore.updateTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      return true;
    } on DioException {
      return false;
    }
  }
}
