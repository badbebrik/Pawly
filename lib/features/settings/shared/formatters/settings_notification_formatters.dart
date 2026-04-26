import '../../models/settings_notification.dart';

String settingsNotificationStatusLabel(SettingsNotification notification) {
  return switch (notification.status) {
    SettingsNotificationStatus.authorized => 'Разрешены',
    SettingsNotificationStatus.provisional => 'Разрешены частично',
    SettingsNotificationStatus.denied => 'Выключены',
    SettingsNotificationStatus.notDetermined => 'Не настроены',
    SettingsNotificationStatus.unavailable => 'Недоступно на этом устройстве',
  };
}
