import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/auth_models.dart';
import '../models/common_models.dart';

class AuthApiClient {
  AuthApiClient(this._apiClient);

  final ApiClient _apiClient;

  Future<RegisterEmailResponse> registerByEmail(RegisterEmailRequest payload) {
    return _apiClient.post<RegisterEmailResponse>(
      ApiEndpoints.authRegisterEmail,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(includeLocale: true),
      decoder: RegisterEmailResponse.fromJson,
    );
  }

  Future<AuthTokensResponse> verifyEmail(VerifyEmailRequest payload) {
    return _apiClient.post<AuthTokensResponse>(
      ApiEndpoints.authVerifyEmail,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(includeLocale: true),
      decoder: AuthTokensResponse.fromJson,
    );
  }

  Future<AuthTokensResponse> loginByEmail(LoginEmailRequest payload) {
    return _apiClient.post<AuthTokensResponse>(
      ApiEndpoints.authLoginEmail,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(includeLocale: true),
      decoder: AuthTokensResponse.fromJson,
    );
  }

  Future<AuthTokensResponse> loginByOAuth(LoginOAuthRequest payload) {
    return _apiClient.post<AuthTokensResponse>(
      ApiEndpoints.authLoginOAuth,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(includeLocale: true),
      decoder: AuthTokensResponse.fromJson,
    );
  }

  Future<EmptyResponse> logout() {
    return _apiClient.post<EmptyResponse>(
      ApiEndpoints.authLogout,
      requestOptions: const ApiRequestOptions(requiresAccessToken: true),
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<EmptyResponse> logoutAll() {
    return _apiClient.post<EmptyResponse>(
      ApiEndpoints.authLogoutAll,
      requestOptions: const ApiRequestOptions(requiresAccessToken: true),
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AuthTokensResponse> refresh(RefreshTokenPayload payload) {
    return _apiClient.post<AuthTokensResponse>(
      ApiEndpoints.authRefresh,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(
        skipTokenRefresh: true,
      ),
      decoder: AuthTokensResponse.fromJson,
    );
  }

  Future<StatusResponse> requestPasswordReset(
    PasswordResetRequestPayload payload,
  ) {
    return _apiClient.post<StatusResponse>(
      ApiEndpoints.authPasswordResetRequest,
      data: payload.toJson(),
      decoder: StatusResponse.fromJson,
    );
  }

  Future<PasswordResetVerifyResponse> verifyPasswordResetCode(
    PasswordResetVerifyPayload payload,
  ) {
    return _apiClient.post<PasswordResetVerifyResponse>(
      ApiEndpoints.authPasswordResetVerify,
      data: payload.toJson(),
      decoder: PasswordResetVerifyResponse.fromJson,
    );
  }

  Future<StatusResponse> confirmPasswordReset(
    PasswordResetConfirmPayload payload,
  ) {
    return _apiClient.post<StatusResponse>(
      ApiEndpoints.authPasswordResetConfirm,
      data: payload.toJson(),
      decoder: StatusResponse.fromJson,
    );
  }
}
