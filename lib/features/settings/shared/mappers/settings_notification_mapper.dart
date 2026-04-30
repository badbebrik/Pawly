import 'package:firebase_messaging/firebase_messaging.dart';

import '../../models/settings_notification.dart';

SettingsNotification settingsNotificationFromFirebase(
  NotificationSettings? settings,
) {
  return SettingsNotification(
    status: settingsNotificationStatusFromFirebase(settings),
  );
}

SettingsNotificationStatus settingsNotificationStatusFromFirebase(
  NotificationSettings? settings,
) {
  if (settings == null) {
    return SettingsNotificationStatus.unavailable;
  }

  return switch (settings.authorizationStatus) {
    AuthorizationStatus.authorized => SettingsNotificationStatus.authorized,
    AuthorizationStatus.provisional => SettingsNotificationStatus.provisional,
    AuthorizationStatus.denied => SettingsNotificationStatus.denied,
    AuthorizationStatus.notDetermined =>
      SettingsNotificationStatus.notDetermined,
  };
}
