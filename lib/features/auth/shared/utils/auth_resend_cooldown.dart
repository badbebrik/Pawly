import '../../../../core/network/api_exception.dart';

int? authResendCooldownFromError(Object error) {
  if (error is! ApiException || error.error.code != 'cannot_resend_yet') {
    return null;
  }

  return authResendCooldownFromDetails(error.error.details);
}

int? authResendCooldownFromDetails(Map<String, dynamic>? details) {
  if (details == null) {
    return null;
  }

  final value = details['can_resend_in'] ?? details['can_resend_in_seconds'];
  if (value is int) {
    return value;
  }

  return int.tryParse(value?.toString() ?? '');
}
