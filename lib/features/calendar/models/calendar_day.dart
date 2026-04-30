class CalendarDay {
  const CalendarDay({
    required this.items,
  });

  final List<CalendarOccurrence> items;

  bool get isEmpty => items.isEmpty;
}

class CalendarOccurrence {
  const CalendarOccurrence({
    required this.petId,
    required this.scheduledItemId,
    required this.scheduledFor,
    required this.title,
    required this.note,
    required this.sourceType,
    required this.sourceId,
  });

  final String petId;
  final String scheduledItemId;
  final DateTime? scheduledFor;
  final String title;
  final String? note;
  final String sourceType;
  final String? sourceId;
}

class CalendarMarker {
  const CalendarMarker({
    required this.hasEvents,
    required this.plannedCount,
  });

  final bool hasEvents;
  final int plannedCount;
}
