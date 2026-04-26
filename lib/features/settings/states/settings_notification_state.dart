import '../models/settings_notification.dart';

const Object _settingsNotificationUnset = Object();

class SettingsNotificationState {
  const SettingsNotificationState({
    required this.notification,
    required this.isRequesting,
    required this.isOpeningSettings,
  });

  final SettingsNotification notification;
  final bool isRequesting;
  final bool isOpeningSettings;

  bool get canRequest {
    return notification.canRequest;
  }

  bool get isGranted {
    return notification.isGranted;
  }

  SettingsNotificationState copyWith({
    Object? notification = _settingsNotificationUnset,
    bool? isRequesting,
    bool? isOpeningSettings,
  }) {
    return SettingsNotificationState(
      notification: identical(notification, _settingsNotificationUnset)
          ? this.notification
          : notification as SettingsNotification,
      isRequesting: isRequesting ?? this.isRequesting,
      isOpeningSettings: isOpeningSettings ?? this.isOpeningSettings,
    );
  }
}
