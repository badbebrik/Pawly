import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/reminders_repository.dart';
import '../models/reminder_inputs.dart';
import '../models/reminder_models.dart';
import '../models/reminder_ref.dart';
import '../shared/utils/reminder_source_utils.dart';
import '../states/reminders_state.dart';
import 'reminders_dependencies.dart';

final petRemindersControllerProvider = FutureProvider.autoDispose
    .family<RemindersState, String>((ref, petId) async {
  final repository = ref.read(remindersRepositoryProvider);
  final now = DateTime.now();
  final reminders = await _loadReminderItems(repository, petId);
  final occurrencesResponse = await repository.listReminderOccurrences(
    petId,
    query: ReminderOccurrencesQuery(
      limit: 100,
      dateFrom: now.toUtc().toIso8601String(),
      dateTo: now.add(const Duration(days: 90)).toUtc().toIso8601String(),
    ),
  );
  final nextOccurrencesByItemId = <String, DateTime>{};
  for (final occurrence in occurrencesResponse.items) {
    final scheduledFor = occurrence.scheduledFor;
    if (scheduledFor == null) {
      continue;
    }
    nextOccurrencesByItemId.putIfAbsent(
      occurrence.scheduledItemId,
      () => scheduledFor,
    );
  }

  final active = <ReminderEntry>[];
  final past = <ReminderEntry>[];
  for (final item in reminders) {
    final nextOccurrenceAt = nextOccurrencesByItemId[item.id];
    final entry = ReminderEntry(
      item: item,
      nextOccurrenceAt: nextOccurrenceAt,
    );
    if (_isReminderActive(item, nextOccurrenceAt, now)) {
      active.add(entry);
    } else {
      past.add(entry);
    }
  }
  active.sort(_compareActiveReminderEntries);
  past.sort(_comparePastReminderEntries);

  return RemindersState(active: active, past: past);
});

final reminderDetailsProvider = FutureProvider.autoDispose
    .family<ReminderDetails, ReminderRef>((ref, args) {
  return ref
      .read(remindersRepositoryProvider)
      .getReminder(args.petId, args.itemId);
});

final reminderPushSettingsProvider = FutureProvider.autoDispose
    .family<ReminderPushSettings, String>((ref, petId) {
  return ref.read(remindersRepositoryProvider).getReminderPushSettings(petId);
});

Future<List<ReminderListItem>> _loadReminderItems(
  RemindersRepository repository,
  String petId,
) async {
  String? cursor;
  final items = <ReminderListItem>[];
  for (var page = 0; page < 5; page++) {
    final response = await repository.listReminders(
      petId,
      query: RemindersQuery(
        cursor: cursor,
        limit: 100,
        includePast: true,
      ),
    );
    items.addAll(response.items);
    final nextCursor = response.nextCursor;
    if (nextCursor == null || nextCursor.isEmpty) {
      break;
    }
    cursor = nextCursor;
  }
  return items;
}

bool _isReminderActive(
  ReminderListItem item,
  DateTime? nextOccurrenceAt,
  DateTime now,
) {
  if (isMedicalReminderSource(item.sourceType)) {
    return true;
  }
  if (nextOccurrenceAt != null && !nextOccurrenceAt.isBefore(now)) {
    return true;
  }
  final startsAt = item.startsAt;
  if (startsAt != null && !startsAt.isBefore(now)) {
    return true;
  }
  final recurrence = item.recurrence;
  if (recurrence == null) {
    return false;
  }
  final until = recurrence.until;
  return until == null || !until.isBefore(now);
}

int _compareActiveReminderEntries(
  ReminderEntry a,
  ReminderEntry b,
) {
  return _compareNullableDateTimesAsc(a.displayAt, b.displayAt);
}

int _comparePastReminderEntries(
  ReminderEntry a,
  ReminderEntry b,
) {
  return _compareNullableDateTimesDesc(a.displayAt, b.displayAt);
}

int _compareNullableDateTimesAsc(DateTime? a, DateTime? b) {
  if (a == null && b == null) {
    return 0;
  }
  if (a == null) {
    return 1;
  }
  if (b == null) {
    return -1;
  }
  return a.compareTo(b);
}

int _compareNullableDateTimesDesc(DateTime? a, DateTime? b) {
  return _compareNullableDateTimesAsc(b, a);
}
