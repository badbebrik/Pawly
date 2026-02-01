class ApiContextKeys {
  const ApiContextKeys._();

  static const String requiresAccessToken = 'requires_access_token';
  static const String requiresUserId = 'requires_user_id';
  static const String includeLocale = 'include_locale';
  static const String includeAcceptLanguage = 'include_accept_language';
  static const String skipTokenRefresh = 'skip_token_refresh';
}

class ApiRequestOptions {
  const ApiRequestOptions({
    this.requiresAccessToken = false,
    this.requiresUserId = false,
    this.includeLocale = true,
    this.includeAcceptLanguage = false,
    this.skipTokenRefresh = false,
  });

  final bool requiresAccessToken;
  final bool requiresUserId;
  final bool includeLocale;
  final bool includeAcceptLanguage;
  final bool skipTokenRefresh;

  Map<String, dynamic> toExtra() {
    return <String, dynamic>{
      ApiContextKeys.requiresAccessToken: requiresAccessToken,
      ApiContextKeys.requiresUserId: requiresUserId,
      ApiContextKeys.includeLocale: includeLocale,
      ApiContextKeys.includeAcceptLanguage: includeAcceptLanguage,
      ApiContextKeys.skipTokenRefresh: skipTokenRefresh,
    };
  }
}
