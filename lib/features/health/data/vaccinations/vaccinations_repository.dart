import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/common_models.dart';
import '../../../../core/network/models/health_models.dart';
import '../../models/vaccinations/vaccination_inputs.dart';
import '../shared/health_payload_mappers.dart';

class VaccinationsRepository {
  const VaccinationsRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<VaccinationListResponse> listVaccinations(
    String petId, {
    required VaccinationListQuery query,
  }) {
    return _healthApiClient.listVaccinations(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      query: query.searchQuery,
      status: query.status,
      bucket: query.bucket,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      sort: query.sort,
    );
  }

  Future<Vaccination> getVaccination(String petId, String vaccinationId) {
    return _healthApiClient.getVaccination(petId, vaccinationId);
  }

  Future<Vaccination> createVaccination(
    String petId, {
    required UpsertVaccinationInput input,
  }) {
    return _healthApiClient.createVaccination(
      petId,
      toUpsertVaccinationPayload(input),
    );
  }

  Future<Vaccination> updateVaccination(
    String petId,
    String vaccinationId, {
    required UpsertVaccinationInput input,
  }) {
    return _healthApiClient.updateVaccination(
      petId,
      vaccinationId,
      toUpsertVaccinationPayload(input),
    );
  }

  Future<EmptyResponse> deleteVaccination(
    String petId,
    String vaccinationId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteVaccination(
      petId,
      vaccinationId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }
}
