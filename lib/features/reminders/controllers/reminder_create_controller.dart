import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/reminder_form.dart';
import '../states/reminder_create_state.dart';
import 'reminders_controller.dart';
import 'reminders_dependencies.dart';

final reminderCreateControllerProvider = AsyncNotifierProvider.autoDispose
    .family<ReminderCreateController, ReminderCreateState, String>(
  ReminderCreateController.new,
);

class ReminderCreateController extends AsyncNotifier<ReminderCreateState> {
  ReminderCreateController(this._petId);

  final String _petId;

  @override
  Future<ReminderCreateState> build() async {
    return ReminderCreateState.initial();
  }

  Future<bool> submit({required ReminderForm form}) async {
    final current = state.asData?.value ?? ReminderCreateState.initial();
    if (current.isSubmitting) {
      return false;
    }

    state = AsyncData(current.copyWith(isSubmitting: true));
    try {
      await ref.read(remindersRepositoryProvider).createReminder(
            _petId,
            form: form,
          );
      ref.invalidate(petRemindersControllerProvider(_petId));
      state = AsyncData(current.copyWith(isSubmitting: false));
      return true;
    } catch (_) {
      state = AsyncData(current.copyWith(isSubmitting: false));
      rethrow;
    }
  }
}
