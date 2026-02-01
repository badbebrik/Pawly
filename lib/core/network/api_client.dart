import 'package:dio/dio.dart';

import 'api_context.dart';
import 'api_error_mapper.dart';
import 'api_exception.dart';
import 'api_result.dart';

typedef ApiDecoder<T> = T Function(Object? data);

class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions requestOptions = const ApiRequestOptions(),
    required ApiDecoder<T> decoder,
  }) async {
    return _request(
      path,
      method: 'GET',
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      decoder: decoder,
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions requestOptions = const ApiRequestOptions(),
    required ApiDecoder<T> decoder,
  }) async {
    return _request(
      path,
      method: 'POST',
      data: data,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      decoder: decoder,
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions requestOptions = const ApiRequestOptions(),
    required ApiDecoder<T> decoder,
  }) async {
    return _request(
      path,
      method: 'PUT',
      data: data,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      decoder: decoder,
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions requestOptions = const ApiRequestOptions(),
    required ApiDecoder<T> decoder,
  }) async {
    return _request(
      path,
      method: 'PATCH',
      data: data,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      decoder: decoder,
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    ApiRequestOptions requestOptions = const ApiRequestOptions(),
    required ApiDecoder<T> decoder,
  }) async {
    return _request(
      path,
      method: 'DELETE',
      data: data,
      queryParameters: queryParameters,
      requestOptions: requestOptions,
      decoder: decoder,
    );
  }

  Future<ApiResult<T>> safe<T>(Future<T> Function() action) async {
    try {
      final data = await action();
      return ApiSuccess<T>(data);
    } on ApiException catch (exception) {
      return ApiFailure<T>(exception.error);
    } catch (error) {
      return ApiFailure<T>(ApiErrorMapper.fromUnknown(error));
    }
  }

  Future<T> _request<T>(
    String path, {
    required String method,
    Object? data,
    Map<String, dynamic>? queryParameters,
    required ApiRequestOptions requestOptions,
    required ApiDecoder<T> decoder,
  }) async {
    try {
      final response = await _dio.request<Object?>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          extra: requestOptions.toExtra(),
        ),
      );

      return decoder(response.data);
    } on DioException catch (exception) {
      throw ApiException(ApiErrorMapper.fromDioException(exception));
    } catch (error) {
      throw ApiException(ApiErrorMapper.fromUnknown(error));
    }
  }
}
