import 'package:dio/dio.dart';

import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/common_models.dart';
import '../models/profile_models.dart';

class ProfileApiClient {
  ProfileApiClient(this._apiClient);

  final ApiClient _apiClient;

  Future<ProfileResponse> getMe() {
    return _apiClient.get<ProfileResponse>(
      ApiEndpoints.profileMe,
      requestOptions: const ApiRequestOptions(requiresUserId: true),
      decoder: ProfileResponse.fromJson,
    );
  }

  Future<ProfileResponse> updateMe(UpdateProfilePayload payload) {
    return _apiClient.put<ProfileResponse>(
      ApiEndpoints.profileMe,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(requiresUserId: true),
      decoder: ProfileResponse.fromJson,
    );
  }

  Future<InitUploadResponse> initAvatarUpload(InitAvatarUploadPayload payload) {
    return _apiClient.post<InitUploadResponse>(
      ApiEndpoints.profileAvatarInitUpload,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(requiresUserId: true),
      decoder: InitUploadResponse.fromJson,
    );
  }

  Future<ConfirmAvatarUploadResponse> confirmAvatarUpload(
    ConfirmAvatarUploadPayload payload,
  ) {
    return _apiClient.post<ConfirmAvatarUploadResponse>(
      ApiEndpoints.profileAvatarConfirmUpload,
      data: payload.toJson(),
      requestOptions: const ApiRequestOptions(requiresUserId: true),
      decoder: ConfirmAvatarUploadResponse.fromJson,
    );
  }

  Future<ConfirmAvatarUploadResponse> testAvatarUpload({
    required MultipartFile file,
  }) {
    final formData = FormData.fromMap(<String, dynamic>{'file': file});

    return _apiClient.post<ConfirmAvatarUploadResponse>(
      ApiEndpoints.profileAvatarTestUpload,
      data: formData,
      requestOptions: const ApiRequestOptions(requiresUserId: true),
      decoder: ConfirmAvatarUploadResponse.fromJson,
    );
  }
}
