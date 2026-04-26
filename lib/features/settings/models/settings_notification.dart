enum SettingsNotificationStatus {
  authorized,
  provisional,
  denied,
  notDetermined,
  unavailable,
}

class SettingsNotification {
  const SettingsNotification({
    required this.status,
  });

  final SettingsNotificationStatus status;

  bool get canRequest => status == SettingsNotificationStatus.notDetermined;

  bool get isGranted {
    return status == SettingsNotificationStatus.authorized ||
        status == SettingsNotificationStatus.provisional;
  }
}
