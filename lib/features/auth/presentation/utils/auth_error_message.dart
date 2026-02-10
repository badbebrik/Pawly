import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_error.dart';
import '../../../../core/services/google_sign_in_service.dart';

String? authErrorMessage(Object error) {
  if (error is GoogleSignInCancelledException) {
    return null;
  }

  if (error is ApiException) {
    final apiError = error.error;
    final code = apiError.code?.trim();
    if (code != null && code.isNotEmpty) {
      final normalizedByCode = _messageByCode(code, apiError.details);
      if (normalizedByCode != null) {
        return normalizedByCode;
      }
    }

    switch (apiError.type) {
      case ApiErrorType.timeout:
        return 'Ошибка сервера. Попробуйте еще раз.';
      case ApiErrorType.network:
        return 'Проверьте подключение к интернету и повторите попытку.';
      case ApiErrorType.unauthorized:
        return 'Сессия истекла. Войдите снова.';
      case ApiErrorType.forbidden:
        return 'У вас нет доступа к этому действию.';
      case ApiErrorType.tooManyRequests:
        return 'Слишком много попыток. Попробуйте позже.';
      case ApiErrorType.server:
        return 'Сервис недоступен. Попробуйте позже.';
      default:
        break;
    }

    final message = apiError.message.trim();
    if (message.isNotEmpty) {
      return message;
    }
  }

  if (error is StateError) {
    final message = error.message.toString().trim();
    if (message.isNotEmpty) {
      return message;
    }
  }

  return 'Произошла ошибка. Попробуйте еще раз.';
}

String? _messageByCode(String code, Map<String, dynamic>? details) {
  switch (code) {
    case 'invalid_json':
    case 'incorrect_format':
      return 'Проверьте корректность введенных данных.';
    case 'invalid_email_or_password':
      return 'Неверный email или пароль.';
    case 'email_not_verified':
      return 'Подтвердите email, чтобы войти в аккаунт.';
    case 'user_blocked':
      return 'Аккаунт заблокирован.';
    case 'oauth_invalid_token':
      return 'Не удалось подтвердить Google-аккаунт. Попробуйте еще раз.';
    case 'oauth_provider_unavailable':
      return 'Вход через Google недоступен.';
    case 'unauthorized':
    case 'refresh_token_mismatch':
    case 'session_not_found':
    case 'session_expired':
    case 'session_revoked':
      return 'Сессия истекла. Войдите снова.';
    case 'cannot_resend_yet':
      final seconds = _resendDelaySeconds(details);
      if (seconds != null && seconds > 0) {
        return 'Повторная отправка будет доступна через $seconds сек.';
      }
      return 'Повторная отправка пока недоступна.';
    case 'internal_error':
      return 'Сервис временно недоступен. Попробуйте позже.';
  }

  return null;
}

int? _resendDelaySeconds(Map<String, dynamic>? details) {
  if (details == null) {
    return null;
  }

  final value =
      details['can_resend_in'] ?? details['can_resend_in_seconds'];

  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}

