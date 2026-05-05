import 'package:flutter/material.dart';

Future<DateTime?> pickReminderStartsAt(
  BuildContext context, {
  required DateTime initialValue,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialValue,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );
  if (date == null || !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialValue),
  );
  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

Future<DateTime?> pickReminderUntilDate(
  BuildContext context, {
  required DateTime startsAt,
  required DateTime? initialValue,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialValue ?? startsAt,
    firstDate: startsAt,
    lastDate: DateTime(2100),
  );
  if (date == null) {
    return null;
  }

  return DateTime(date.year, date.month, date.day, 23, 59, 59);
}
