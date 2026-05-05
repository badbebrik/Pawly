import '../../models/reminder_models.dart';

String reminderSecondaryLine(ReminderListItem item) {
  final parts = <String>[
    reminderSourceLabel(item.sourceType),
    reminderRecurrenceLabel(item.recurrence),
    reminderOffsetLabel(
      pushEnabled: item.pushEnabled,
      remindOffsetMinutes: item.remindOffsetMinutes,
    ),
  ].where((value) => value.isNotEmpty).toList(growable: false);

  return parts.join(' • ');
}

String reminderStartLabel(DateTime? value) {
  if (value == null) {
    return 'Дата не задана';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month в $hour:$minute';
}

String reminderRecurrenceLabel(ReminderRecurrence? recurrence) {
  if (recurrence == null) {
    return 'Без повтора';
  }

  return switch (recurrence.rule) {
    'DAILY' => recurrence.interval <= 1
        ? 'Каждый день'
        : 'Каждые ${recurrence.interval} дн.',
    'WEEKLY' => recurrence.interval <= 1
        ? 'Каждую неделю'
        : 'Каждые ${recurrence.interval} нед.',
    'MONTHLY' => recurrence.interval <= 1
        ? 'Каждый месяц'
        : 'Каждые ${recurrence.interval} мес.',
    'YEARLY' => recurrence.interval <= 1
        ? 'Каждый год'
        : 'Каждые ${recurrence.interval} г.',
    _ => 'Повтор ${recurrence.rule}',
  };
}

String reminderOffsetLabel({
  required bool pushEnabled,
  required int? remindOffsetMinutes,
}) {
  if (!pushEnabled) {
    return 'Без уведомления';
  }

  if (remindOffsetMinutes == null || remindOffsetMinutes == 0) {
    return 'В момент события';
  }

  if (remindOffsetMinutes % (60 * 24) == 0) {
    final days = remindOffsetMinutes ~/ (60 * 24);
    return days == 1 ? 'За 1 день' : 'За $days дн.';
  }

  if (remindOffsetMinutes % 60 == 0) {
    final hours = remindOffsetMinutes ~/ 60;
    return hours == 1 ? 'За 1 час' : 'За $hours ч.';
  }

  return 'За $remindOffsetMinutes мин.';
}

String reminderSourceLabel(String sourceType) {
  return switch (sourceType) {
    'MANUAL' => 'Ручное',
    'LOG_TYPE' => 'По типу записи',
    'PET_EVENT' => 'Событие питомца',
    'VET_VISIT' => 'Визит к врачу',
    'VACCINATION' => 'Вакцинация',
    'PROCEDURE' => 'Процедура',
    _ => sourceType,
  };
}
