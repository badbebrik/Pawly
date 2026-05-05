import '../../../core/network/clients/health_api_client.dart';
import '../../../core/network/models/common_models.dart';
import '../../../core/network/models/health_models.dart';
import '../models/reminder_form.dart';
import '../models/reminder_inputs.dart';
import '../models/reminder_models.dart';
import '../shared/mappers/reminder_mappers.dart';

class RemindersRepository {
  const RemindersRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<ReminderPageResult> listReminders(
    String petId, {
    RemindersQuery query = const RemindersQuery(),
  }) async {
    final response = await _healthApiClient.listScheduledItems(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      sourceType: query.sourceType,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      includePast: query.includePast,
    );
    return mapScheduledItemsPage(response);
  }

  Future<ReminderDetails> getReminder(String petId, String itemId) async {
    final response = await _healthApiClient.getScheduledItem(petId, itemId);
    return mapScheduledItem(response);
  }

  Future<ReminderDetails> createReminder(
    String petId, {
    required ReminderForm form,
  }) async {
    final response = await _healthApiClient.createScheduledItem(
      petId,
      _toUpsertScheduledItemPayload(form),
    );
    return mapScheduledItem(response);
  }

  Future<ReminderDetails> updateReminder(
    String petId,
    String itemId, {
    required ReminderForm form,
  }) async {
    final response = await _healthApiClient.updateScheduledItem(
      petId,
      itemId,
      _toUpsertScheduledItemPayload(form),
    );
    return mapScheduledItem(response);
  }

  Future<ReminderDetails> updateReminderSettings(
    String petId,
    String itemId, {
    required UpdateReminderSettingsInput input,
  }) async {
    final response = await _healthApiClient.updateScheduledItemReminderSettings(
      petId,
      itemId,
      UpdateScheduledItemReminderSettingsPayload(
        pushEnabled: input.pushEnabled,
        remindOffsetMinutes: input.remindOffsetMinutes,
        rowVersion: input.rowVersion,
      ),
    );
    return mapScheduledItem(response);
  }

  Future<void> deleteReminder(
    String petId,
    String itemId, {
    required int rowVersion,
  }) async {
    await _healthApiClient.deleteScheduledItem(
      petId,
      itemId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<ReminderOccurrencePageResult> listReminderOccurrences(
    String petId, {
    ReminderOccurrencesQuery query = const ReminderOccurrencesQuery(),
  }) async {
    final response = await _healthApiClient.listScheduledItemOccurrences(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      sourceType: query.sourceType,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
    );
    return mapScheduledItemOccurrencesPage(response);
  }

  Future<ReminderOccurrence> getReminderOccurrence(
    String petId,
    String occurrenceId,
  ) async {
    final response = await _healthApiClient.getScheduledItemOccurrence(
      petId,
      occurrenceId,
    );
    return mapScheduledItemOccurrence(response);
  }

  Future<ReminderPushSettings> getReminderPushSettings(String petId) async {
    final response = await _healthApiClient.getPetPushSettings(petId);
    return mapPetPushSettings(response);
  }

  Future<ReminderPushSettings> updateReminderPushSettings(
    String petId, {
    required bool scheduledItemsEnabled,
  }) async {
    final response = await _healthApiClient.updatePetPushSettings(
      petId,
      UpdatePetPushSettingsPayload(
        scheduledItemsEnabled: scheduledItemsEnabled,
      ),
    );
    return mapPetPushSettings(response);
  }

  UpsertScheduledItemPayload _toUpsertScheduledItemPayload(
    ReminderForm form,
  ) {
    return UpsertScheduledItemPayload(
      sourceType: form.sourceType,
      sourceId: form.sourceId,
      title: form.title,
      note: form.note,
      startsAt: form.startsAt.toUtc(),
      pushEnabled: form.pushEnabled,
      remindOffsetMinutes: form.remindOffsetMinutes,
      recurrence: !form.hasRecurrence
          ? null
          : ScheduledItemRecurrence(
              rule: form.recurrenceRule,
              interval: form.recurrenceInterval,
              until: form.recurrenceUntil?.toUtc(),
            ),
      rowVersion: form.rowVersion,
    );
  }
}
