import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';

class DioClient {
  const DioClient._();

  static Dio create({required AuthInterceptor authInterceptor}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    dio.interceptors.add(authInterceptor);
    dio.interceptors.add(
      PrettyDioLogger(
        requestBody: true,
        requestHeader: false,
        responseHeader: false,
      ),
    );

    return dio;
  }
}
