import '../../models/reminder_form_constants.dart';

String reminderRecurrenceOptionLabel(String value) {
  return switch (value) {
    noReminderRecurrenceValue => 'Без повтора',
    'DAILY' => 'Каждый день',
    'WEEKLY' => 'Неделя',
    'MONTHLY' => 'Месяц',
    'YEARLY' => 'Год',
    _ => value,
  };
}

String reminderOffsetOptionLabel(int value) {
  return switch (value) {
    0 => 'В момент',
    15 => '15 мин',
    30 => '30 мин',
    60 => '1 час',
    1440 => '1 день',
    _ => '$value мин',
  };
}

String formatReminderDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year в $hour:$minute';
}

String formatReminderDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day.$month.$year';
}
