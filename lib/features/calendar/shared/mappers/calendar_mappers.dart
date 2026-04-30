import '../../../../core/network/models/health_models.dart';
import '../../models/calendar_day.dart';

CalendarDay calendarDayFromResponse(ScheduledDayResponse response) {
  return CalendarDay(
    items: response.items
        .map(calendarOccurrenceFromResponse)
        .toList(growable: false),
  );
}

CalendarOccurrence calendarOccurrenceFromResponse(
  ScheduledItemOccurrence response,
) {
  final rule = response.rule;
  return CalendarOccurrence(
    petId: response.petId,
    scheduledItemId: response.scheduledItemId,
    scheduledFor: response.scheduledFor,
    title: rule.title,
    note: rule.note,
    sourceType: rule.sourceType,
    sourceId: rule.sourceId,
  );
}

CalendarMarker calendarMarkerFromResponse(CalendarDateMarker response) {
  return CalendarMarker(
    hasEvents: response.hasEvents,
    plannedCount: response.plannedCount,
  );
}
