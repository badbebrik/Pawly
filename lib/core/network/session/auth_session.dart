class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.locale,
  });

  final String accessToken;
  final String refreshToken;
  final String userId;
  final String locale;

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? locale,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      locale: locale ?? this.locale,
    );
  }
}
