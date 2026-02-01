enum ApiErrorType {
  cancelled,
  timeout,
  network,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  conflict,
  unprocessable,
  tooManyRequests,
  server,
  unknown,
}

class ApiError {
  const ApiError({
    required this.type,
    required this.message,
    this.statusCode,
    this.code,
    this.details,
  });

  final ApiErrorType type;
  final String message;
  final int? statusCode;
  final String? code;
  final Map<String, dynamic>? details;
}
