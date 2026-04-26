import '../../../core/network/models/profile_models.dart';

class SettingsProfile {
  const SettingsProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.avatarDownloadUrl,
    required this.locale,
    required this.timeZone,
  });

  factory SettingsProfile.fromResponse(ProfileResponse response) {
    return SettingsProfile(
      userId: response.userId,
      firstName: response.firstName,
      lastName: response.lastName,
      avatarDownloadUrl: response.avatarDownloadUrl,
      locale: response.locale,
      timeZone: response.timeZone,
    );
  }

  final String userId;
  final String? firstName;
  final String? lastName;
  final String? avatarDownloadUrl;
  final String locale;
  final String timeZone;

  bool get hasAvatar => (avatarDownloadUrl ?? '').isNotEmpty;
}
