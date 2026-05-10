import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import 'interceptors/auth_context_interceptor.dart';
import 'interceptors/auth_refresh_interceptor.dart';
import 'session/auth_session_store.dart';

class DioBundle {
  const DioBundle({required this.dio, required this.refreshDio});

  final Dio dio;
  final Dio refreshDio;
}

class DioFactory {
  const DioFactory._();

  static DioBundle create({required AuthSessionStore sessionStore}) {
    final baseOptions = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: ApiConstants.connectTimeout,
      receiveTimeout: ApiConstants.receiveTimeout,
      sendTimeout: ApiConstants.sendTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

    final dio = Dio(baseOptions);
    final refreshDio = Dio(baseOptions);

    dio.interceptors.add(AuthContextInterceptor(sessionStore));
    dio.interceptors.add(
      AuthRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        sessionStore: sessionStore,
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestBody: false,
          requestHeader: false,
          responseBody: false,
          responseHeader: false,
        ),
      );
    }

    refreshDio.interceptors.add(AuthContextInterceptor(sessionStore));

    return DioBundle(dio: dio, refreshDio: refreshDio);
  }

  static Dio createUploadDio() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        responseType: ResponseType.plain,
      ),
    );
    return dio;
  }
}
