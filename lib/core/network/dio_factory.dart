import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import 'interceptors/api_context_interceptor.dart';
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

    dio.interceptors.add(ApiContextInterceptor(sessionStore));
    dio.interceptors.add(
      AuthRefreshInterceptor(
        dio: dio,
        refreshDio: refreshDio,
        sessionStore: sessionStore,
      ),
    );
    dio.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );

    refreshDio.interceptors.add(ApiContextInterceptor(sessionStore));

    return DioBundle(dio: dio, refreshDio: refreshDio);
  }

  static Dio createUploadDio() {
    return Dio(
      BaseOptions(
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        sendTimeout: ApiConstants.sendTimeout,
        responseType: ResponseType.plain,
      ),
    );
  }
}
