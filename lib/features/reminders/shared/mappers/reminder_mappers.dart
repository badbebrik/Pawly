import '../../../../core/network/models/health_models.dart' as api;
import '../../models/reminder_models.dart';

ReminderRecurrence mapReminderRecurrence(
  api.ScheduledItemRecurrence recurrence,
) {
  return ReminderRecurrence(
    rule: recurrence.rule,
    interval: recurrence.interval,
    until: recurrence.until,
  );
}

ReminderListItem mapScheduledItemCard(api.ScheduledItemCard item) {
  return ReminderListItem(
    id: item.id,
    petId: item.petId,
    sourceType: item.sourceType,
    sourceId: item.sourceId,
    title: item.title,
    notePreview: item.notePreview,
    startsAt: item.startsAt,
    pushEnabled: item.pushEnabled,
    remindOffsetMinutes: item.remindOffsetMinutes,
    recurrence: item.recurrence == null
        ? null
        : mapReminderRecurrence(item.recurrence!),
    rowVersion: item.rowVersion,
  );
}

ReminderDetails mapScheduledItem(api.ScheduledItem item) {
  return ReminderDetails(
    id: item.id,
    petId: item.petId,
    sourceType: item.sourceType,
    sourceId: item.sourceId,
    title: item.title,
    note: item.note,
    startsAt: item.startsAt,
    pushEnabled: item.pushEnabled,
    remindOffsetMinutes: item.remindOffsetMinutes,
    recurrence: item.recurrence == null
        ? null
        : mapReminderRecurrence(item.recurrence!),
    rowVersion: item.rowVersion,
  );
}

ReminderOccurrence mapScheduledItemOccurrence(
  api.ScheduledItemOccurrence occurrence,
) {
  return ReminderOccurrence(
    id: occurrence.id,
    scheduledItemId: occurrence.scheduledItemId,
    petId: occurrence.petId,
    scheduledFor: occurrence.scheduledFor,
  );
}

ReminderPageResult mapScheduledItemsPage(
  api.ScheduledItemListResponse response,
) {
  return ReminderPageResult(
    items: response.items.map(mapScheduledItemCard).toList(growable: false),
    nextCursor: response.nextCursor,
  );
}

ReminderOccurrencePageResult mapScheduledItemOccurrencesPage(
  api.ScheduledItemOccurrenceListResponse response,
) {
  return ReminderOccurrencePageResult(
    items:
        response.items.map(mapScheduledItemOccurrence).toList(growable: false),
    nextCursor: response.nextCursor,
  );
}

ReminderPushSettings mapPetPushSettings(api.PetPushSettings settings) {
  return ReminderPushSettings(
    scheduledItemsEnabled: settings.scheduledItemsEnabled,
  );
}
