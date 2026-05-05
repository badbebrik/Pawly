import 'package:flutter/foundation.dart';

import '../models/reminder_models.dart';

@immutable
class RemindersState {
  const RemindersState({
    required this.active,
    required this.past,
  });

  final List<ReminderEntry> active;
  final List<ReminderEntry> past;

  bool get isEmpty => active.isEmpty && past.isEmpty;
}

@immutable
class ReminderEntry {
  const ReminderEntry({
    required this.item,
    this.nextOccurrenceAt,
  });

  final ReminderListItem item;
  final DateTime? nextOccurrenceAt;

  DateTime? get displayAt => nextOccurrenceAt ?? item.startsAt;
}
