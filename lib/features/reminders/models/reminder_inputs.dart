class RemindersQuery {
  const RemindersQuery({
    this.cursor,
    this.limit = 30,
    this.sourceType,
    this.dateFrom,
    this.dateTo,
    this.includePast,
  });

  final String? cursor;
  final int limit;
  final String? sourceType;
  final String? dateFrom;
  final String? dateTo;
  final bool? includePast;
}

class ReminderOccurrencesQuery {
  const ReminderOccurrencesQuery({
    this.cursor,
    this.limit = 30,
    this.sourceType,
    this.dateFrom,
    this.dateTo,
  });

  final String? cursor;
  final int limit;
  final String? sourceType;
  final String? dateFrom;
  final String? dateTo;
}

class UpdateReminderSettingsInput {
  const UpdateReminderSettingsInput({
    required this.pushEnabled,
    this.remindOffsetMinutes,
    required this.rowVersion,
  });

  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final int rowVersion;
}
