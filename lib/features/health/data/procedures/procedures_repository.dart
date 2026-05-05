import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/common_models.dart';
import '../../../../core/network/models/health_models.dart';
import '../../models/procedures/procedure_inputs.dart';
import '../shared/health_payload_mappers.dart';

class ProceduresRepository {
  const ProceduresRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<ProcedureListResponse> listProcedures(
    String petId, {
    required ProcedureListQuery query,
  }) {
    return _healthApiClient.listProcedures(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      query: query.searchQuery,
      status: query.status,
      bucket: query.bucket,
      procedureTypeId: query.procedureTypeId,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      sort: query.sort,
    );
  }

  Future<Procedure> getProcedure(String petId, String procedureId) {
    return _healthApiClient.getProcedure(petId, procedureId);
  }

  Future<Procedure> createProcedure(
    String petId, {
    required UpsertProcedureInput input,
  }) {
    return _healthApiClient.createProcedure(
      petId,
      toUpsertProcedurePayload(input),
    );
  }

  Future<Procedure> updateProcedure(
    String petId,
    String procedureId, {
    required UpsertProcedureInput input,
  }) {
    return _healthApiClient.updateProcedure(
      petId,
      procedureId,
      toUpsertProcedurePayload(input),
    );
  }

  Future<EmptyResponse> deleteProcedure(
    String petId,
    String procedureId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteProcedure(
      petId,
      procedureId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }
}
