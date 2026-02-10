import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

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
  final uploadDio = ref.watch(dioProvider);

  return SettingsRepository(
    profileApiClient: profileApiClient,
    uploadDio: uploadDio,
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

  Future<void> uploadPhoto(ImageSource source) async {
    final current = state.asData?.value;
    if (current == null) {
      return;
    }

    final file = await ref.read(mediaPickerServiceProvider).pickImage(
          source: source,
        );
    if (file == null) {
      return;
    }

    state = AsyncData(current.copyWith(isUploadingPhoto: true));

    try {
      final updatedProfile =
          await ref.read(settingsRepositoryProvider).uploadAvatar(file: file);

      state = AsyncData(
        current.copyWith(
          profile: updatedProfile,
          isUploadingPhoto: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isUploadingPhoto: false));
      rethrow;
    }
  }

  Future<SettingsProfileState> _load() async {
    final profile = await ref.read(settingsRepositoryProvider).getProfile();
    return SettingsProfileState(
      profile: profile,
      isUploadingPhoto: false,
    );
  }
}
