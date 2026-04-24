import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/profile_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/settings_repository.dart';

class SettingsProfileState {
  const SettingsProfileState({
    required this.profile,
    required this.isUploadingPhoto,
  });

  final ProfileResponse profile;
  final bool isUploadingPhoto;

  SettingsProfileState copyWith({
    ProfileResponse? profile,
    bool? isUploadingPhoto,
  }) {
    return SettingsProfileState(
      profile: profile ?? this.profile,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
    );
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final profileApiClient = ref.watch(profileApiClientProvider);
  final uploadDio = ref.watch(uploadDioProvider);
  final authSessionStore = ref.watch(authSessionStoreProvider);
  final sharedPreferencesService = ref.watch(sharedPreferencesServiceProvider);

  return SettingsRepository(
    profileApiClient: profileApiClient,
    uploadDio: uploadDio,
    authSessionStore: authSessionStore,
    sharedPreferencesService: sharedPreferencesService,
  );
});

final settingsProfileControllerProvider = AsyncNotifierProvider.autoDispose<
    SettingsProfileController, SettingsProfileState>(
  SettingsProfileController.new,
);

class SettingsProfileController extends AsyncNotifier<SettingsProfileState> {
  @override
  Future<SettingsProfileState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> uploadPhotoFromGallery() {
    return _uploadPhoto(fromCamera: false);
  }

  Future<void> uploadPhotoFromCamera() {
    return _uploadPhoto(fromCamera: true);
  }

  Future<void> _uploadPhoto({required bool fromCamera}) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final mediaPicker = ref.read(mediaPickerServiceProvider);
    final file = fromCamera
        ? await mediaPicker.takeAvatarPhoto()
        : await mediaPicker.pickAvatarFromGallery();
    if (file == null) {
      return;
    }

    state = AsyncData(current.copyWith(isUploadingPhoto: true));

    try {
      final updatedProfile =
          await ref.read(settingsRepositoryProvider).uploadAvatar(file: file);
      await _setProfile(updatedProfile, isUploadingPhoto: false);
    } catch (_) {
      state = AsyncData(current.copyWith(isUploadingPhoto: false));
      rethrow;
    }
  }

  Future<void> deletePhoto() async {
    final current = state.asData?.value;
    if (current == null || (current.profile.avatarDownloadUrl ?? '').isEmpty) {
      return;
    }

    state = AsyncData(current.copyWith(isUploadingPhoto: true));

    try {
      await ref.read(settingsRepositoryProvider).deleteAvatar();
      final updatedProfile =
          await ref.read(settingsRepositoryProvider).getProfile();
      await _setProfile(updatedProfile, isUploadingPhoto: false);
    } catch (_) {
      state = AsyncData(current.copyWith(isUploadingPhoto: false));
      rethrow;
    }
  }

  Future<ProfileResponse> updateName({
    required String firstName,
    required String lastName,
  }) async {
    final current = state.requireValue;
    final updatedProfile =
        await ref.read(settingsRepositoryProvider).updateProfile(
              firstName: firstName,
              lastName: lastName,
            );
    await _setProfile(
      updatedProfile,
      isUploadingPhoto: current.isUploadingPhoto,
    );
    return updatedProfile;
  }

  Future<SettingsProfileState> _load() async {
    final profile = await ref.read(settingsRepositoryProvider).getProfile();
    await ref.read(settingsRepositoryProvider).syncStoredPreferences(
          timeZone: profile.timeZone,
        );
    return SettingsProfileState(profile: profile, isUploadingPhoto: false);
  }

  Future<void> _setProfile(
    ProfileResponse profile, {
    required bool isUploadingPhoto,
  }) async {
    await ref.read(settingsRepositoryProvider).syncStoredPreferences(
          timeZone: profile.timeZone,
        );
    state = AsyncData(
      SettingsProfileState(
        profile: profile,
        isUploadingPhoto: isUploadingPhoto,
      ),
    );
  }
}
