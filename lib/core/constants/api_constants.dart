class ApiConstants {
  const ApiConstants._();

  static const String baseUrl = "http://localhost:8000";
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 20);
}
