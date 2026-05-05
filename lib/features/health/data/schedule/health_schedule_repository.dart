import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/health_models.dart';

class HealthScheduleRepository {
  const HealthScheduleRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<ScheduledDayResponse> getScheduleDay({
    required String date,
  }) {
    return _healthApiClient.getScheduleDay(date: date);
  }

  Future<CalendarRangeResponse> getHealthCalendar({
    required String dateFrom,
    required String dateTo,
  }) {
    return _healthApiClient.getHealthCalendar(
      dateFrom: dateFrom,
      dateTo: dateTo,
    );
  }
}
