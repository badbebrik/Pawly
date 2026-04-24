String? extractInviteToken(Uri? uri) {
  if (uri == null) {
    return null;
  }

  final scheme = uri.scheme.toLowerCase();
  final host = uri.host.toLowerCase();
  final firstPath =
      uri.pathSegments.isEmpty ? '' : uri.pathSegments.first.toLowerCase();

  final isCustomSchemeInvite =
      scheme == 'pawly' && (host == 'invite' || firstPath == 'invite');
  final isUniversalInvite = (scheme == 'https' || scheme == 'http') &&
      (host == 'pawly.app' || host == 'www.pawly.app') &&
      firstPath == 'invite';
  if (!isCustomSchemeInvite && !isUniversalInvite) {
    return null;
  }

  final token = uri.queryParameters['token']?.trim();
  if (token == null || token.isEmpty) {
    return null;
  }

  return token;
}

String describeInviteUri(Uri? uri) {
  if (uri == null) {
    return 'null';
  }

  final token = uri.queryParameters['token'];
  return 'scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}, '
      'hasToken=${token != null && token.isNotEmpty}';
}
