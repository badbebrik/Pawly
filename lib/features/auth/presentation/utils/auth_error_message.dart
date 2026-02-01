import '../../../../core/network/api_exception.dart';

String authErrorMessage(Object error) {
  if (error is ApiException) {
    final message = error.error.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }

  if (error is StateError) {
    return error.message;
  }

  return 'Произошла ошибка. Попробуйте еще раз.';
}
