import 'api_error.dart';

class ApiException implements Exception {
  const ApiException(this.error);

  final ApiError error;

  @override
  String toString() {
    return 'ApiException(type: ${error.type}, status: ${error.statusCode}, message: ${error.message})';
  }
}
