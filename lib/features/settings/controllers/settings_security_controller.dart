import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/controllers/auth_dependencies.dart';
import '../../pets/controllers/active_pet_controller.dart';
import '../../pets/controllers/active_pet_details_controller.dart';
import '../../pets/controllers/pets_controller.dart';
import '../states/settings_security_state.dart';
import 'settings_profile_controller.dart';

final settingsSecurityControllerProvider =
    NotifierProvider<SettingsSecurityController, SettingsSecurityState>(
  SettingsSecurityController.new,
);

class SettingsSecurityController extends Notifier<SettingsSecurityState> {
  @override
  SettingsSecurityState build() {
    return SettingsSecurityState.initial();
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    if (state.isChangingPassword) {
      return;
    }

    state = state.copyWith(isChangingPassword: true);

    try {
      await ref.read(settingsRepositoryProvider).changePassword(
            oldPassword: oldPassword,
            newPassword: newPassword,
          );
      _resetSessionState();
      state = state.copyWith(isChangingPassword: false);
    } catch (_) {
      state = state.copyWith(isChangingPassword: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    if (state.isLoggingOut) {
      return;
    }

    state = state.copyWith(isLoggingOut: true);

    try {
      await ref.read(settingsRepositoryProvider).logout();
      _resetSessionState();
      state = state.copyWith(isLoggingOut: false);
    } catch (_) {
      state = state.copyWith(isLoggingOut: false);
      rethrow;
    }
  }

  void _resetSessionState() {
    ref.invalidate(appLaunchProvider);
    ref.invalidate(currentUserIdProvider);
    ref.invalidate(activePetControllerProvider);
    ref.invalidate(activePetDetailsControllerProvider);
    ref.invalidate(petsControllerProvider);
  }
}
