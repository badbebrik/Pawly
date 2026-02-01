abstract class GoogleSignInService {
  Future<String?> getIdToken();
}

class FallbackGoogleSignInService implements GoogleSignInService {
  @override
  Future<String?> getIdToken() async {
    // TODO(v1): connect google_sign_in package and return real id_token.
    return null;
  }
}
