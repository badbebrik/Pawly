import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'reminders_controller.dart';
import 'reminders_dependencies.dart';

final reminderActionsControllerProvider =
    Provider.autoDispose<ReminderActionsController>(
  ReminderActionsController.new,
);

class ReminderActionsController {
  ReminderActionsController(this._ref);

  final Ref _ref;

  Future<void> deleteReminder(
    String petId,
    String itemId, {
    required int rowVersion,
  }) async {
    await _ref.read(remindersRepositoryProvider).deleteReminder(
          petId,
          itemId,
          rowVersion: rowVersion,
        );
    _ref.invalidate(petRemindersControllerProvider(petId));
  }

  Future<void> updatePushSettings(
    String petId, {
    required bool scheduledItemsEnabled,
  }) async {
    await _ref.read(remindersRepositoryProvider).updateReminderPushSettings(
          petId,
          scheduledItemsEnabled: scheduledItemsEnabled,
        );
    _ref.invalidate(reminderPushSettingsProvider(petId));
  }
}
