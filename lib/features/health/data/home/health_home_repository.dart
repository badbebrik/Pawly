import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/health_models.dart';

class HealthHomeRepository {
  const HealthHomeRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<HealthBootstrapResponse> getHealthBootstrap(String petId) {
    return _healthApiClient.getHealthBootstrap(petId);
  }

  Future<HealthDayResponse> getHealthDay(
    String petId, {
    required String date,
  }) {
    return _healthApiClient.getHealthDay(petId, date: date);
  }

  Future<ScheduledDayResponse> getPetScheduleDay(
    String petId, {
    required String date,
  }) {
    return _healthApiClient.getPetScheduleDay(petId, date: date);
  }
}
