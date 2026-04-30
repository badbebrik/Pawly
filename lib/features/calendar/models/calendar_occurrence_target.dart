import 'calendar_day.dart';

enum CalendarOccurrenceTargetKind {
  vetVisitDetails,
  vaccinationDetails,
  procedureDetails,
  logCreate,
  reminderEdit,
  reminders,
}

class CalendarOccurrenceTarget {
  const CalendarOccurrenceTarget._({
    required this.kind,
    required this.petId,
    this.sourceId,
    this.scheduledItemId,
  });

  factory CalendarOccurrenceTarget.fromOccurrence(
    CalendarOccurrence occurrence,
  ) {
    final petId = occurrence.petId;
    final sourceType = occurrence.sourceType;
    final sourceId = occurrence.sourceId;

    if (sourceType == 'VET_VISIT' && _hasValue(sourceId)) {
      return CalendarOccurrenceTarget._(
        kind: CalendarOccurrenceTargetKind.vetVisitDetails,
        petId: petId,
        sourceId: sourceId,
      );
    }

    if (sourceType == 'VACCINATION' && _hasValue(sourceId)) {
      return CalendarOccurrenceTarget._(
        kind: CalendarOccurrenceTargetKind.vaccinationDetails,
        petId: petId,
        sourceId: sourceId,
      );
    }

    if (sourceType == 'PROCEDURE' && _hasValue(sourceId)) {
      return CalendarOccurrenceTarget._(
        kind: CalendarOccurrenceTargetKind.procedureDetails,
        petId: petId,
        sourceId: sourceId,
      );
    }

    if (sourceType == 'LOG_TYPE' && _hasValue(sourceId)) {
      return CalendarOccurrenceTarget._(
        kind: CalendarOccurrenceTargetKind.logCreate,
        petId: petId,
        sourceId: sourceId,
      );
    }

    if (sourceType == 'MANUAL' || sourceType == 'PET_EVENT') {
      return CalendarOccurrenceTarget._(
        kind: CalendarOccurrenceTargetKind.reminderEdit,
        petId: petId,
        scheduledItemId: occurrence.scheduledItemId,
      );
    }

    return CalendarOccurrenceTarget._(
      kind: CalendarOccurrenceTargetKind.reminders,
      petId: petId,
    );
  }

  final CalendarOccurrenceTargetKind kind;
  final String petId;
  final String? sourceId;
  final String? scheduledItemId;
}

bool _hasValue(String? value) {
  return value != null && value.isNotEmpty;
}
