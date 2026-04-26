import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../states/settings_notification_state.dart';
import 'settings_profile_controller.dart';

final settingsNotificationControllerProvider = AsyncNotifierProvider
    .autoDispose<SettingsNotificationController, SettingsNotificationState>(
  SettingsNotificationController.new,
);

class SettingsNotificationController
    extends AsyncNotifier<SettingsNotificationState> {
  @override
  Future<SettingsNotificationState> build() async {
    return _load();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = AsyncData(await _load());
  }

  Future<void> requestNotifications() async {
    final current = state.asData?.value;
    if (current == null || current.isRequesting) {
      return;
    }

    state = AsyncData(current.copyWith(isRequesting: true));

    try {
      final notification = await ref
          .read(settingsRepositoryProvider)
          .requestNotificationPermissions();
      state = AsyncData(
        current.copyWith(
          notification: notification,
          isRequesting: false,
        ),
      );
    } catch (_) {
      state = AsyncData(current.copyWith(isRequesting: false));
      rethrow;
    }
  }

  Future<bool> openDeviceSettings() async {
    final current = state.asData?.value;
    if (current == null || current.isOpeningSettings) {
      return false;
    }

    state = AsyncData(current.copyWith(isOpeningSettings: true));

    try {
      final repository = ref.read(settingsRepositoryProvider);
      final opened = await repository.openNotificationSettings();
      final notification = await repository.getNotificationSettings();
      state = AsyncData(
        current.copyWith(
          notification: notification,
          isOpeningSettings: false,
        ),
      );
      return opened;
    } catch (_) {
      state = AsyncData(current.copyWith(isOpeningSettings: false));
      rethrow;
    }
  }

  Future<SettingsNotificationState> _load() async {
    final notification =
        await ref.read(settingsRepositoryProvider).getNotificationSettings();
    return SettingsNotificationState(
      notification: notification,
      isRequesting: false,
      isOpeningSettings: false,
    );
  }
}
