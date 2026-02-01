import 'json_map.dart';
import 'json_parsers.dart';

class AuthTokensResponse {
  const AuthTokensResponse({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String accessToken;
  final String refreshToken;

  factory AuthTokensResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AuthTokensResponse(
      userId: asString(json['user_id']),
      accessToken: asString(json['access_token']),
      refreshToken: asString(json['refresh_token']),
    );
  }
}

class RegisterEmailRequest {
  const RegisterEmailRequest({
    required this.email,
    required this.password,
    this.firstName,
    this.lastName,
  });

  final String email;
  final String password;
  final String? firstName;
  final String? lastName;

  JsonMap toJson() {
    return <String, dynamic>{
      'email': email,
      'password': password,
      'first_name': firstName,
      'last_name': lastName,
    }..removeWhere((_, dynamic value) => value == null);
  }
}

class RegisterEmailResponse {
  const RegisterEmailResponse({
    required this.userId,
    required this.channel,
    required this.codeTtlSeconds,
    required this.canResendInSeconds,
  });

  final String userId;
  final String channel;
  final int codeTtlSeconds;
  final int canResendInSeconds;

  factory RegisterEmailResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final verification = asJsonMap(json['verification']);

    return RegisterEmailResponse(
      userId: asString(json['user_id']),
      channel: asString(verification['channel']),
      codeTtlSeconds: asInt(verification['code_ttl_seconds']),
      canResendInSeconds: asInt(verification['can_resend_in_seconds']),
    );
  }
}

class VerifyEmailRequest {
  const VerifyEmailRequest({required this.email, required this.code});

  final String email;
  final String code;

  JsonMap toJson() => <String, dynamic>{'email': email, 'code': code};
}

class LoginEmailRequest {
  const LoginEmailRequest({required this.email, required this.password});

  final String email;
  final String password;

  JsonMap toJson() => <String, dynamic>{'email': email, 'password': password};
}

class LoginOAuthRequest {
  const LoginOAuthRequest({required this.provider, required this.idToken});

  final String provider;
  final String idToken;

  JsonMap toJson() => <String, dynamic>{
        'provider': provider,
        'id_token': idToken,
      };
}

class PasswordResetRequestPayload {
  const PasswordResetRequestPayload({required this.email});

  final String email;

  JsonMap toJson() => <String, dynamic>{'email': email};
}

class PasswordResetVerifyPayload {
  const PasswordResetVerifyPayload({required this.email, required this.code});

  final String email;
  final String code;

  JsonMap toJson() => <String, dynamic>{'email': email, 'code': code};
}

class PasswordResetVerifyResponse {
  const PasswordResetVerifyResponse({required this.resetToken});

  final String resetToken;

  factory PasswordResetVerifyResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PasswordResetVerifyResponse(
        resetToken: asString(json['reset_token']));
  }
}

class PasswordResetConfirmPayload {
  const PasswordResetConfirmPayload({
    required this.resetToken,
    required this.newPassword,
  });

  final String resetToken;
  final String newPassword;

  JsonMap toJson() => <String, dynamic>{
        'reset_token': resetToken,
        'new_password': newPassword,
      };
}

class RefreshTokenPayload {
  const RefreshTokenPayload({required this.refreshToken});

  final String refreshToken;

  JsonMap toJson() => <String, dynamic>{'refresh_token': refreshToken};
}
