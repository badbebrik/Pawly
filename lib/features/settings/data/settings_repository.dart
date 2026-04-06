import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/clients/profile_api_client.dart';
import '../../../core/network/models/profile_models.dart';
import '../../../core/network/session/auth_session_store.dart';
import '../../../core/storage/shared_preferences_service.dart';

class SettingsRepository {
  SettingsRepository({
    required ProfileApiClient profileApiClient,
    required Dio uploadDio,
    required AuthSessionStore authSessionStore,
    required SharedPreferencesService sharedPreferencesService,
  })  : _profileApiClient = profileApiClient,
        _uploadDio = uploadDio,
        _authSessionStore = authSessionStore,
        _sharedPreferencesService = sharedPreferencesService;

  final ProfileApiClient _profileApiClient;
  final Dio _uploadDio;
  final AuthSessionStore _authSessionStore;
  final SharedPreferencesService _sharedPreferencesService;

  Future<ProfileResponse> getProfile() {
    return _profileApiClient.getMe();
  }

  Future<ProfileResponse> updateProfile({
    required String firstName,
    required String lastName,
  }) {
    return _profileApiClient.updateMe(
      UpdateProfilePayload(
        firstName: firstName,
        lastName: lastName,
      ),
    );
  }

  Future<ProfileResponse> updatePreferences({
    String? locale,
    String? timeZone,
  }) async {
    final profile = await _profileApiClient.updatePreferences(
      UpdateProfilePreferencesPayload(
        locale: locale,
        timeZone: timeZone,
      ),
    );
    await syncStoredPreferences(
      locale: profile.locale,
      timeZone: profile.timeZone,
    );
    return profile;
  }

  Future<void> syncStoredPreferences({
    required String locale,
    required String timeZone,
  }) async {
    await _sharedPreferencesService.saveProfilePreferences(
      locale: locale,
      timeZone: timeZone,
    );
    await _authSessionStore.updateLocale(locale);
  }

  Future<ProfileResponse> uploadAvatar({required XFile file}) async {
    final mimeType = _resolveImageMimeType(file.path);
    if (mimeType == null) {
      throw StateError('Поддерживаются только JPG и PNG изображения.');
    }

    final bytes = await file.readAsBytes();
    final initResponse = await _profileApiClient.initAvatarUpload(
      InitAvatarUploadPayload(
        mimeType: mimeType,
        expectedSizeBytes: bytes.length,
      ),
    );

    await _uploadDio.request<Object?>(
      _normalizeStorageUrl(initResponse.upload.url),
      data: bytes,
      options: Options(
        method: initResponse.upload.method,
        contentType: mimeType,
        headers: <String, dynamic>{
          ...initResponse.upload.headers,
          Headers.contentLengthHeader: bytes.length,
          if (!initResponse.upload.headers.containsKey('Content-Type'))
            'Content-Type': mimeType,
        },
        responseType: ResponseType.plain,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final confirmResponse = await _profileApiClient.confirmAvatarUpload(
      ConfirmAvatarUploadPayload(
        fileId: initResponse.fileId,
        sizeBytes: bytes.length,
      ),
    );

    final profile = confirmResponse.profile;
    await syncStoredPreferences(
      locale: profile.locale,
      timeZone: profile.timeZone,
    );
    return profile;
  }

  String _normalizeStorageUrl(String url) {
    final uri = Uri.tryParse(url);
    final apiUri = Uri.tryParse(ApiConstants.baseUrl);
    if (uri == null || apiUri == null || uri.host != 'minio') {
      return url;
    }

    return uri.replace(host: apiUri.host).toString();
  }

  String? _resolveImageMimeType(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    return null;
  }
}
