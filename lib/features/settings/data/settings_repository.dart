import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/clients/profile_api_client.dart';
import '../../../core/network/models/profile_models.dart';
import '../../../core/network/session/auth_session_store.dart';
import '../../../core/services/push_notifications_service.dart';
import '../../../core/services/system_settings_launcher.dart';
import '../../../core/storage/shared_preferences_service.dart';
import '../../auth/data/auth_repository.dart';
import '../models/settings_notification.dart';
import '../models/settings_profile.dart';
import '../shared/mappers/settings_notification_mapper.dart';
import '../shared/mappers/settings_profile_mapper.dart';
import '../shared/utils/settings_storage_url.dart';

class SettingsRepository {
  SettingsRepository({
    required ProfileApiClient profileApiClient,
    required Dio uploadDio,
    required AuthSessionStore authSessionStore,
    required SharedPreferencesService sharedPreferencesService,
    required PushNotificationsService pushNotificationsService,
    required SystemSettingsLauncher systemSettingsLauncher,
    required AuthRepository authRepository,
  })  : _profileApiClient = profileApiClient,
        _uploadDio = uploadDio,
        _authSessionStore = authSessionStore,
        _sharedPreferencesService = sharedPreferencesService,
        _pushNotificationsService = pushNotificationsService,
        _systemSettingsLauncher = systemSettingsLauncher,
        _authRepository = authRepository;

  final ProfileApiClient _profileApiClient;
  final Dio _uploadDio;
  final AuthSessionStore _authSessionStore;
  final SharedPreferencesService _sharedPreferencesService;
  final PushNotificationsService _pushNotificationsService;
  final SystemSettingsLauncher _systemSettingsLauncher;
  final AuthRepository _authRepository;

  Future<SettingsProfile> getProfile() async {
    final profile = await _profileApiClient.getMe();
    return settingsProfileFromResponse(profile);
  }

  Future<SettingsProfile> updateProfile({
    required String firstName,
    required String lastName,
  }) async {
    final profile = await _profileApiClient.updateMe(
      UpdateProfilePayload(
        firstName: firstName,
        lastName: lastName,
      ),
    );
    return settingsProfileFromResponse(profile);
  }

  Future<SettingsProfile> updatePreferences({
    required String locale,
    required String timeZone,
  }) async {
    final profile = await _profileApiClient.updatePreferences(
      UpdateProfilePreferencesPayload(
        locale: locale,
        timeZone: timeZone,
      ),
    );
    await syncStoredPreferences(timeZone: profile.timeZone);
    await _authSessionStore.updateLocale(profile.locale);
    return settingsProfileFromResponse(profile);
  }

  Future<void> syncStoredPreferences({
    required String timeZone,
  }) async {
    await _sharedPreferencesService.saveProfilePreferences(
      timeZone: timeZone,
    );
    await _authSessionStore.updateLocale('ru');
  }

  Future<SettingsProfile> uploadAvatar({required XFile file}) async {
    final mimeType = _resolveImageMimeType(file.path);
    if (mimeType == null) {
      throw StateError('Поддерживаются только JPG и PNG изображения.');
    }

    final sizeBytes = await file.length();
    final initResponse = await _profileApiClient.initAvatarUpload(
      InitAvatarUploadPayload(
        mimeType: mimeType,
        expectedSizeBytes: sizeBytes,
      ),
    );

    await _uploadDio.request<Object?>(
      normalizeSettingsStorageUrl(initResponse.upload.url),
      data: file.openRead(),
      options: Options(
        method: initResponse.upload.method,
        contentType: mimeType,
        headers: <String, dynamic>{
          ...initResponse.upload.headers,
          Headers.contentLengthHeader: sizeBytes,
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
        sizeBytes: sizeBytes,
      ),
    );

    final profile = confirmResponse.profile;
    await syncStoredPreferences(
      timeZone: profile.timeZone,
    );
    return settingsProfileFromResponse(profile);
  }

  Future<void> deleteAvatar() {
    return _profileApiClient.deleteAvatar();
  }

  Future<SettingsNotification> getNotificationSettings() async {
    final settings = await _pushNotificationsService.getNotificationSettings();
    return settingsNotificationFromFirebase(settings);
  }

  Future<SettingsNotification> requestNotificationPermissions() async {
    final granted =
        await _pushNotificationsService.requestPermissionsIfNeeded();
    if (granted) {
      await _pushNotificationsService.syncTokenForCurrentSession();
    }
    return getNotificationSettings();
  }

  Future<bool> openNotificationSettings() {
    return _systemSettingsLauncher.openNotificationSettings();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _authRepository.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<void> logout() {
    return _authRepository.logout();
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
