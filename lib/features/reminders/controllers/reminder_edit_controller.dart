import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_form.dart';
import '../models/reminder_inputs.dart';
import '../models/reminder_ref.dart';
import '../states/reminder_edit_state.dart';
import 'reminders_controller.dart';
import 'reminders_dependencies.dart';

final reminderEditControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReminderEditController, ReminderEditState, ReminderRef>(
  ReminderEditController.new,
);

class ReminderEditController extends AsyncNotifier<ReminderEditState> {
  ReminderEditController(this._reminderRef);

  final ReminderRef _reminderRef;

  @override
  Future<ReminderEditState> build() async {
    return ReminderEditState.initial();
  }

  Future<bool> submitRule({required ReminderForm form}) async {
    final current = state.asData?.value ?? ReminderEditState.initial();
    if (current.isSubmitting) {
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await ref.read(remindersRepositoryProvider).updateReminder(
            _reminderRef.petId,
            _reminderRef.itemId,
            form: form,
          );
      _invalidateReminderProviders();
      state = AsyncData(current.copyWith(isSubmitting: false));
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  Future<bool> submitReminderSettings({
    required bool pushEnabled,
    required int? remindOffsetMinutes,
    required int rowVersion,
  }) async {
    final current = state.asData?.value ?? ReminderEditState.initial();
    if (current.isSubmitting) {
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await ref.read(remindersRepositoryProvider).updateReminderSettings(
            _reminderRef.petId,
            _reminderRef.itemId,
            input: UpdateReminderSettingsInput(
              pushEnabled: pushEnabled,
              remindOffsetMinutes: remindOffsetMinutes,
              rowVersion: rowVersion,
            ),
          );
      _invalidateReminderProviders();
      state = AsyncData(current.copyWith(isSubmitting: false));
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }

  void _invalidateReminderProviders() {
    ref.invalidate(petRemindersControllerProvider(_reminderRef.petId));
    ref.invalidate(reminderDetailsProvider(_reminderRef));
  }
}
