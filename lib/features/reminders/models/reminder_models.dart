class ReminderRecurrence {
  const ReminderRecurrence({
    required this.rule,
    required this.interval,
    this.until,
  });

  final String rule;
  final int interval;
  final DateTime? until;
}

class ReminderListItem {
  const ReminderListItem({
    required this.id,
    required this.petId,
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.notePreview,
    this.startsAt,
    required this.pushEnabled,
    this.remindOffsetMinutes,
    this.recurrence,
    required this.rowVersion,
  });

  final String id;
  final String petId;
  final String sourceType;
  final String? sourceId;
  final String title;
  final String? notePreview;
  final DateTime? startsAt;
  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final ReminderRecurrence? recurrence;
  final int rowVersion;
}

class ReminderDetails {
  const ReminderDetails({
    required this.id,
    required this.petId,
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.note,
    this.startsAt,
    required this.pushEnabled,
    this.remindOffsetMinutes,
    this.recurrence,
    required this.rowVersion,
  });

  final String id;
  final String petId;
  final String sourceType;
  final String? sourceId;
  final String title;
  final String? note;
  final DateTime? startsAt;
  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final ReminderRecurrence? recurrence;
  final int rowVersion;
}

class ReminderOccurrence {
  const ReminderOccurrence({
    required this.id,
    required this.scheduledItemId,
    required this.petId,
    this.scheduledFor,
  });

  final String id;
  final String scheduledItemId;
  final String petId;
  final DateTime? scheduledFor;
}

class ReminderPageResult {
  const ReminderPageResult({
    required this.items,
    this.nextCursor,
  });

  final List<ReminderListItem> items;
  final String? nextCursor;
}

class ReminderOccurrencePageResult {
  const ReminderOccurrencePageResult({
    required this.items,
    this.nextCursor,
  });

  final List<ReminderOccurrence> items;
  final String? nextCursor;
}

class ReminderPushSettings {
  const ReminderPushSettings({
    required this.scheduledItemsEnabled,
  });

  final bool scheduledItemsEnabled;
}
