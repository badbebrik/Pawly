import '../../health/data/schedule/health_schedule_repository.dart';
import '../models/calendar_day.dart';
import '../shared/formatters/calendar_date_formatters.dart';
import '../shared/mappers/calendar_mappers.dart';

class CalendarRepository {
  const CalendarRepository({
    required HealthScheduleRepository healthRepository,
  }) : _healthRepository = healthRepository;

  final HealthScheduleRepository _healthRepository;

  Future<CalendarDay> getDay(DateTime date) async {
    final response = await _healthRepository.getScheduleDay(
      date: formatCalendarApiDate(date),
    );
    return calendarDayFromResponse(response);
  }

  Future<Map<String, CalendarMarker>> getMarkers({
    required DateTime dateFrom,
    required DateTime dateTo,
  }) async {
    final response = await _healthRepository.getHealthCalendar(
      dateFrom: formatCalendarApiDate(dateFrom),
      dateTo: formatCalendarApiDate(dateTo),
    );
    return response.markersByDate.map(
      (date, marker) => MapEntry(date, calendarMarkerFromResponse(marker)),
    );
  }
}
