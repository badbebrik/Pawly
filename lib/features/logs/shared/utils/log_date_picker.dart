import 'package:flutter/material.dart';

Future<DateTime?> pickLogDateTime(
  BuildContext context, {
  required DateTime initialValue,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialValue,
    firstDate: DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 365)),
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
