import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/auth_models.dart';
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

    _logBootstrap401(
      err,
      requiresToken: requiresToken,
      skipRefresh: skipRefresh,
    );

    if (responseStatus != 401 || !requiresToken || skipRefresh) {
      return handler.next(err);
    }

    final refreshFuture = _refreshInFlight ??= _refreshAccessToken();
    final bool refreshed;
    try {
      refreshed = await refreshFuture;
    } finally {
      if (identical(_refreshInFlight, refreshFuture)) {
        _refreshInFlight = null;
      }
    }

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

      _logBootstrapRetry(
          requestOptions, options.headers ?? const <String, dynamic>{});

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
      final tokens = AuthTokensResponse.fromJson(data);

      await _sessionStore.updateTokens(
        accessToken: tokens.accessToken,
        refreshToken: tokens.refreshToken,
      );

      return true;
    } on Object {
      return false;
    }
  }

  void _logBootstrap401(
    DioException err, {
    required bool requiresToken,
    required bool skipRefresh,
  }) {
    final requestOptions = err.requestOptions;
    if (!_isLogsBootstrapRequest(requestOptions.path)) {
      return;
    }

    final authorization = requestOptions.headers['Authorization']?.toString();
    debugPrint(
      '[HealthBootstrap][onError] status=${err.response?.statusCode} '
      'path=${requestOptions.path} '
      'requiresToken=$requiresToken '
      'skipRefresh=$skipRefresh '
      'authHeader=${authorization != null} '
      'authBearer=${authorization?.startsWith('Bearer ') == true} '
      'authPreview=${_maskAuthorization(authorization)} '
      'error=${err.response?.data ?? err.error}',
    );
  }

  void _logBootstrapRetry(
    RequestOptions requestOptions,
    Map<String, dynamic> headers,
  ) {
    if (!_isLogsBootstrapRequest(requestOptions.path)) {
      return;
    }

    final authorization = headers['Authorization']?.toString();
    debugPrint(
      '[HealthBootstrap][retry] ${requestOptions.method} ${requestOptions.path} '
      'authHeader=${authorization != null} '
      'authBearer=${authorization?.startsWith('Bearer ') == true} '
      'authPreview=${_maskAuthorization(authorization)} '
      'headerKeys=${headers.keys.toList()}',
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
