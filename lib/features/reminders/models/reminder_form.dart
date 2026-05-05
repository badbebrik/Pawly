import 'reminder_form_constants.dart';

class ReminderForm {
  const ReminderForm({
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.note,
    required this.startsAt,
    required this.pushEnabled,
    this.remindOffsetMinutes,
    required this.recurrenceRule,
    required this.recurrenceInterval,
    this.recurrenceUntil,
    this.rowVersion,
  });

  final String sourceType;
  final String? sourceId;
  final String title;
  final String? note;
  final DateTime startsAt;
  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final String recurrenceRule;
  final int recurrenceInterval;
  final DateTime? recurrenceUntil;
  final int? rowVersion;

  bool get hasRecurrence => recurrenceRule != noReminderRecurrenceValue;
}
