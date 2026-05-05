import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/common_models.dart';
import '../../../../core/network/models/health_models.dart';
import '../../models/vet_visits/vet_visit_inputs.dart';
import '../shared/health_payload_mappers.dart';

class VetVisitsRepository {
  const VetVisitsRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<VetVisitListResponse> listVetVisits(
    String petId, {
    required VetVisitListQuery query,
  }) {
    return _healthApiClient.listVetVisits(
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

  Future<VetVisit> getVetVisit(String petId, String visitId) {
    return _healthApiClient.getVetVisit(petId, visitId);
  }

  Future<VetVisit> createVetVisit(
    String petId, {
    required UpsertVetVisitInput input,
  }) {
    return _healthApiClient.createVetVisit(
      petId,
      toUpsertVetVisitPayload(input),
    );
  }

  Future<VetVisit> updateVetVisit(
    String petId,
    String visitId, {
    required UpsertVetVisitInput input,
  }) {
    return _healthApiClient.updateVetVisit(
      petId,
      visitId,
      toUpsertVetVisitPayload(input),
    );
  }

  Future<EmptyResponse> deleteVetVisit(
    String petId,
    String visitId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteVetVisit(
      petId,
      visitId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<RelatedLog> linkLogToVetVisit(
    String petId,
    String visitId, {
    required String logId,
  }) {
    return _healthApiClient.linkLogToVetVisit(
      petId,
      visitId,
      LinkVetVisitLogPayload(logId: logId),
    );
  }

  Future<EmptyResponse> unlinkLogFromVetVisit(
    String petId,
    String visitId, {
    required String logId,
  }) {
    return _healthApiClient.unlinkLogFromVetVisit(petId, visitId, logId);
  }
}
