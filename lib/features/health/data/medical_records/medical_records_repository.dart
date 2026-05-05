import '../../../../core/network/clients/health_api_client.dart';
import '../../../../core/network/models/common_models.dart';
import '../../../../core/network/models/health_models.dart';
import '../../models/medical_records/medical_record_inputs.dart';
import '../shared/health_payload_mappers.dart';

class MedicalRecordsRepository {
  const MedicalRecordsRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<MedicalRecordListResponse> listMedicalRecords(
    String petId, {
    required MedicalRecordListQuery query,
  }) {
    return _healthApiClient.listMedicalRecords(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      query: query.searchQuery,
      status: query.status,
      bucket: query.bucket,
      recordTypeId: query.recordTypeId,
      sort: query.sort,
    );
  }

  Future<MedicalRecord> getMedicalRecord(String petId, String recordId) {
    return _healthApiClient.getMedicalRecord(petId, recordId);
  }

  Future<MedicalRecord> createMedicalRecord(
    String petId, {
    required UpsertMedicalRecordInput input,
  }) {
    return _healthApiClient.createMedicalRecord(
      petId,
      toUpsertMedicalRecordPayload(input),
    );
  }

  Future<MedicalRecord> updateMedicalRecord(
    String petId,
    String recordId, {
    required UpsertMedicalRecordInput input,
  }) {
    return _healthApiClient.updateMedicalRecord(
      petId,
      recordId,
      toUpsertMedicalRecordPayload(input),
    );
  }

  Future<EmptyResponse> deleteMedicalRecord(
    String petId,
    String recordId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteMedicalRecord(
      petId,
      recordId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }
}
