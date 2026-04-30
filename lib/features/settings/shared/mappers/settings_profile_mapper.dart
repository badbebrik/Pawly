import '../../../../core/network/models/profile_models.dart';
import '../../models/settings_profile.dart';

SettingsProfile settingsProfileFromResponse(ProfileResponse response) {
  return SettingsProfile(
    userId: response.userId,
    firstName: response.firstName,
    lastName: response.lastName,
    avatarDownloadUrl: response.avatarDownloadUrl,
    locale: response.locale,
    timeZone: response.timeZone,
  );
}
