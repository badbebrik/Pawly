class SettingsProfile {
  const SettingsProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.avatarDownloadUrl,
    required this.locale,
    required this.timeZone,
  });

  final String userId;
  final String? firstName;
  final String? lastName;
  final String? avatarDownloadUrl;
  final String locale;
  final String timeZone;

  bool get hasAvatar => (avatarDownloadUrl ?? '').isNotEmpty;
}
