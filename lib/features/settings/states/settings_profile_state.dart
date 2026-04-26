import '../models/settings_profile.dart';

class SettingsProfileState {
  const SettingsProfileState({
    required this.profile,
    required this.isUploadingPhoto,
    required this.isUpdatingProfile,
  });

  final SettingsProfile profile;
  final bool isUploadingPhoto;
  final bool isUpdatingProfile;

  SettingsProfileState copyWith({
    SettingsProfile? profile,
    bool? isUploadingPhoto,
    bool? isUpdatingProfile,
  }) {
    return SettingsProfileState(
      profile: profile ?? this.profile,
      isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
      isUpdatingProfile: isUpdatingProfile ?? this.isUpdatingProfile,
    );
  }
}
