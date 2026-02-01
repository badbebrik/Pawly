import 'package:dio/dio.dart';

import 'api_error.dart';

class ApiErrorMapper {
  const ApiErrorMapper._();

  static ApiError fromDioException(DioException exception) {
    final response = exception.response;

    if (exception.type == DioExceptionType.cancel) {
      return const ApiError(
        type: ApiErrorType.cancelled,
        message: 'Request was cancelled.',
      );
    }

    if (exception.type == DioExceptionType.connectionTimeout ||
        exception.type == DioExceptionType.sendTimeout ||
        exception.type == DioExceptionType.receiveTimeout) {
      return const ApiError(
        type: ApiErrorType.timeout,
        message: 'Request timeout. Please try again.',
      );
    }

    if (exception.type == DioExceptionType.connectionError ||
        exception.type == DioExceptionType.badCertificate) {
      return const ApiError(
        type: ApiErrorType.network,
        message: 'Network connection error.',
      );
    }

    final int? statusCode = response?.statusCode;
    final _BodyError bodyError = _parseBodyError(response?.data);

    return ApiError(
      type: _mapStatusToType(statusCode),
      statusCode: statusCode,
      code: bodyError.code,
      message: bodyError.message ?? _defaultMessage(statusCode),
      details: bodyError.details,
    );
  }

  static ApiError fromUnknown(Object error) {
    return ApiError(
      type: ApiErrorType.unknown,
      message: error.toString(),
    );
  }

  static ApiErrorType _mapStatusToType(int? statusCode) {
    switch (statusCode) {
      case 400:
        return ApiErrorType.badRequest;
      case 401:
        return ApiErrorType.unauthorized;
      case 403:
        return ApiErrorType.forbidden;
      case 404:
        return ApiErrorType.notFound;
      case 409:
        return ApiErrorType.conflict;
      case 422:
        return ApiErrorType.unprocessable;
      case 429:
        return ApiErrorType.tooManyRequests;
      case 500:
      case 502:
      case 503:
      case 504:
        return ApiErrorType.server;
      default:
        return ApiErrorType.unknown;
    }
  }

  static String _defaultMessage(int? statusCode) {
    if (statusCode == null) {
      return 'Unexpected error';
    }

    return 'Request failed with status code $statusCode';
  }

  static _BodyError _parseBodyError(Object? data) {
    if (data is String && data.trim().isNotEmpty) {
      return _BodyError(message: data.trim());
    }

    if (data is! Map<String, dynamic>) {
      return const _BodyError();
    }

    final nestedError = data['error'];

    if (nestedError is Map<String, dynamic>) {
      return _BodyError(
        code: nestedError['code']?.toString(),
        message: nestedError['message']?.toString(),
        details: data,
      );
    }

    return _BodyError(
      code: data['code']?.toString(),
      message: data['message']?.toString() ?? data['error']?.toString(),
      details: data,
    );
  }
}

class _BodyError {
  const _BodyError({this.code, this.message, this.details});

  final String? code;
  final String? message;
  final Map<String, dynamic>? details;
}
