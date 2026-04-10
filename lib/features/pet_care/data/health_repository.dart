import '../../../core/network/clients/health_api_client.dart';
import '../../../core/network/models/common_models.dart';
import '../../../core/network/models/health_models.dart';
import '../../../core/network/models/log_models.dart';
import 'health_repository_models.dart';

class HealthRepository {
  const HealthRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<LogComposerBootstrapResponse> getLogsBootstrap(
    String petId, {
    bool? includeCatalog,
  }) {
    return _healthApiClient.getLogsBootstrap(
      petId,
      includeCatalog: includeCatalog,
    );
  }

  Future<HealthBootstrapResponse> getHealthBootstrap(String petId) {
    return _healthApiClient.getHealthBootstrap(petId);
  }

  Future<InitUploadResponse> initAttachmentUpload(
    String petId, {
    required UploadHealthAttachmentInput input,
  }) {
    return _healthApiClient.initAttachmentUpload(
      petId,
      InitHealthAttachmentUploadPayload(
        mimeType: input.mimeType,
        originalFilename: input.originalFilename,
        expectedSizeBytes: input.expectedSizeBytes,
      ),
    );
  }

  Future<UploadedHealthFile> confirmAttachmentUpload(
    String petId, {
    required String fileId,
    required int sizeBytes,
  }) async {
    final response = await _healthApiClient.confirmAttachmentUpload(
      petId,
      ConfirmHealthAttachmentUploadPayload(
        fileId: fileId,
        sizeBytes: sizeBytes,
      ),
    );
    return response.file;
  }

  Future<PetDocumentsListResponse> listDocuments(
    String petId, {
    PetDocumentsQuery query = const PetDocumentsQuery(),
  }) {
    return _healthApiClient.listDocuments(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      entityType: query.entityType,
      fileType: query.fileType,
    );
  }

  Future<LogListResponse> listLogs(
    String petId, {
    required LogListQuery query,
  }) {
    return _healthApiClient.listLogs(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      query: query.searchQuery,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      typeIds: query.typeIds,
      source: query.source,
      hasAttachments: query.hasAttachments,
      hasMetrics: query.hasMetrics,
      sort: query.sort,
      includeFacets: query.includeFacets,
    );
  }

  Future<LogEntry> getLog(String petId, String logId) {
    return _healthApiClient.getLog(petId, logId);
  }

  Future<LogEntry> createLog(
    String petId, {
    required UpsertLogInput input,
  }) {
    return _healthApiClient.createLog(
      petId,
      _toUpsertLogPayload(input),
    );
  }

  Future<LogEntry> updateLog(
    String petId,
    String logId, {
    required UpsertLogInput input,
  }) {
    return _healthApiClient.updateLog(
      petId,
      logId,
      _toUpsertLogPayload(input),
    );
  }

  Future<EmptyResponse> deleteLog(
    String petId,
    String logId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteLog(
      petId,
      logId,
      DeleteLogPayload(rowVersion: rowVersion),
    );
  }

  Future<LogTypeListResponse> listLogTypes(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithMetrics,
  }) {
    return _healthApiClient.listLogTypes(
      petId,
      scope: scope,
      query: query,
      includeArchived: includeArchived,
      onlyWithMetrics: onlyWithMetrics,
    );
  }

  Future<LogType> createLogType(
    String petId, {
    required CreateLogTypeInput input,
  }) {
    return _healthApiClient.createLogType(
      petId,
      CreateLogTypePayload(
        name: input.name,
        metricRequirements: input.metricRequirements
            .map(_toLogTypeMetricRequirementPayload)
            .toList(growable: false),
      ),
    );
  }

  Future<LogType> updateLogType(
    String petId,
    String logTypeId, {
    required UpdateLogTypeInput input,
  }) {
    return _healthApiClient.updateLogType(
      petId,
      logTypeId,
      UpdateLogTypePayload(
        name: input.name,
        metricRequirements: input.metricRequirements
            .map(_toLogTypeMetricRequirementPayload)
            .toList(growable: false),
        rowVersion: input.rowVersion,
      ),
    );
  }

  Future<EmptyResponse> deleteLogType(
    String petId,
    String logTypeId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteLogType(
      petId,
      logTypeId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<MetricListResponse> listMetrics(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithData,
    bool? onlyWithUsage,
  }) {
    return _healthApiClient.listMetrics(
      petId,
      scope: scope,
      query: query,
      includeArchived: includeArchived,
      onlyWithData: onlyWithData,
      onlyWithUsage: onlyWithUsage,
    );
  }

  Future<Metric> createMetric(
    String petId, {
    required UpsertMetricInput input,
  }) {
    return _healthApiClient.createMetric(
      petId,
      CreateMetricPayload(
        name: input.name,
        inputKind: input.inputKind,
        unitCode: input.unitCode,
        minValue: input.minValue,
        maxValue: input.maxValue,
      ),
    );
  }

  Future<Metric> updateMetric(
    String petId,
    String metricId, {
    required UpdateMetricInput input,
  }) {
    return _healthApiClient.updateMetric(
      petId,
      metricId,
      UpdateMetricPayload(
        name: input.name,
        inputKind: input.inputKind,
        unitCode: input.unitCode,
        minValue: input.minValue,
        maxValue: input.maxValue,
        rowVersion: input.rowVersion,
      ),
    );
  }

  Future<EmptyResponse> deleteMetric(
    String petId,
    String metricId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteMetric(
      petId,
      metricId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<AnalyticsMetricSummaryListResponse> listAnalyticsMetrics(
    String petId, {
    AnalyticsMetricsQuery query = const AnalyticsMetricsQuery(),
  }) {
    return _healthApiClient.listAnalyticsMetrics(
      petId,
      query: query.query,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      source: query.source,
      typeIds: query.typeIds,
      limit: query.limit,
    );
  }

  Future<MetricSeriesResponse> getMetricSeries(
    String petId,
    String metricId, {
    required AnalyticsSeriesQuery query,
  }) {
    return _healthApiClient.getMetricSeries(
      petId,
      metricId,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      source: query.source,
      typeIds: query.typeIds,
      sort: query.sort,
      includeSummary: query.includeSummary,
    );
  }

  Future<VetVisitListResponse> listVetVisits(
    String petId, {
    required VetVisitListQuery query,
  }) {
    return _healthApiClient.listVetVisits(
      petId,
      cursor: query.cursor,
      limit: query.limit,
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
      _toUpsertVetVisitPayload(input),
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
      _toUpsertVetVisitPayload(input),
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

  Future<VaccinationListResponse> listVaccinations(
    String petId, {
    required VaccinationListQuery query,
  }) {
    return _healthApiClient.listVaccinations(
      petId,
      cursor: query.cursor,
      limit: query.limit,
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
      _toUpsertVaccinationPayload(input),
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
      _toUpsertVaccinationPayload(input),
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

  Future<ProcedureListResponse> listProcedures(
    String petId, {
    required ProcedureListQuery query,
  }) {
    return _healthApiClient.listProcedures(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      status: query.status,
      bucket: query.bucket,
      procedureType: query.procedureType,
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
      _toUpsertProcedurePayload(input),
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
      _toUpsertProcedurePayload(input),
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

  Future<MedicalRecordListResponse> listMedicalRecords(
    String petId, {
    required MedicalRecordListQuery query,
  }) {
    return _healthApiClient.listMedicalRecords(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      status: query.status,
      bucket: query.bucket,
      recordType: query.recordType,
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
      _toUpsertMedicalRecordPayload(input),
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
      _toUpsertMedicalRecordPayload(input),
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

  Future<HealthDayResponse> getHealthDay(
    String petId, {
    required String date,
  }) {
    return _healthApiClient.getHealthDay(petId, date: date);
  }

  Future<ScheduledDayResponse> getScheduleDay({
    required String date,
  }) {
    return _healthApiClient.getScheduleDay(date: date);
  }

  Future<ScheduledDayResponse> getPetScheduleDay(
    String petId, {
    required String date,
  }) {
    return _healthApiClient.getPetScheduleDay(petId, date: date);
  }

  Future<ScheduledItemListResponse> listScheduledItems(
    String petId, {
    ScheduledItemsQuery query = const ScheduledItemsQuery(),
  }) {
    return _healthApiClient.listScheduledItems(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      sourceType: query.sourceType,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      includePast: query.includePast,
    );
  }

  Future<ScheduledItem> getScheduledItem(String petId, String itemId) {
    return _healthApiClient.getScheduledItem(petId, itemId);
  }

  Future<ScheduledItem> createScheduledItem(
    String petId, {
    required UpsertScheduledItemInput input,
  }) {
    return _healthApiClient.createScheduledItem(
      petId,
      _toUpsertScheduledItemPayload(input),
    );
  }

  Future<ScheduledItem> updateScheduledItem(
    String petId,
    String itemId, {
    required UpsertScheduledItemInput input,
  }) {
    return _healthApiClient.updateScheduledItem(
      petId,
      itemId,
      _toUpsertScheduledItemPayload(input),
    );
  }

  Future<ScheduledItem> updateScheduledItemReminderSettings(
    String petId,
    String itemId, {
    required UpdateScheduledItemReminderSettingsInput input,
  }) {
    return _healthApiClient.updateScheduledItemReminderSettings(
      petId,
      itemId,
      UpdateScheduledItemReminderSettingsPayload(
        pushEnabled: input.pushEnabled,
        remindOffsetMinutes: input.remindOffsetMinutes,
        rowVersion: input.rowVersion,
      ),
    );
  }

  Future<EmptyResponse> deleteScheduledItem(
    String petId,
    String itemId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteScheduledItem(
      petId,
      itemId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<ScheduledItemOccurrenceListResponse> listScheduledItemOccurrences(
    String petId, {
    ScheduledItemOccurrencesQuery query = const ScheduledItemOccurrencesQuery(),
  }) {
    return _healthApiClient.listScheduledItemOccurrences(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      sourceType: query.sourceType,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
    );
  }

  Future<ScheduledItemOccurrence> getScheduledItemOccurrence(
    String petId,
    String occurrenceId,
  ) {
    return _healthApiClient.getScheduledItemOccurrence(petId, occurrenceId);
  }

  Future<DeviceToken> registerPushDevice({
    required RegisterPushDeviceInput input,
  }) {
    return _healthApiClient.registerPushDevice(
      DeviceTokenPayload(
        deviceId: input.deviceId,
        platform: input.platform,
        pushToken: input.pushToken,
      ),
    );
  }

  Future<EmptyResponse> deletePushDevice(String deviceId) {
    return _healthApiClient.deletePushDevice(deviceId);
  }

  Future<PetPushSettings> getPetPushSettings(String petId) {
    return _healthApiClient.getPetPushSettings(petId);
  }

  Future<PetPushSettings> updatePetPushSettings(
    String petId, {
    required bool scheduledItemsEnabled,
  }) {
    return _healthApiClient.updatePetPushSettings(
      petId,
      UpdatePetPushSettingsPayload(
        scheduledItemsEnabled: scheduledItemsEnabled,
      ),
    );
  }

  UpsertLogPayload _toUpsertLogPayload(UpsertLogInput input) {
    return UpsertLogPayload(
      occurredAt: DateTime.parse(input.occurredAtIso),
      logTypeId: input.logTypeId,
      description: input.description,
      metricValues: input.metricValues
          .map(
            (item) => LogMetricValue(
              metricId: item.metricId,
              metricName: '',
              inputKind: '',
              valueNum: item.valueNum,
            ),
          )
          .toList(growable: false),
      attachmentFileIds: input.attachmentFileIds,
      rowVersion: input.rowVersion,
    );
  }

  UpsertScheduledItemPayload _toUpsertScheduledItemPayload(
    UpsertScheduledItemInput input,
  ) {
    return UpsertScheduledItemPayload(
      sourceType: input.sourceType,
      sourceId: input.sourceId,
      title: input.title,
      note: input.note,
      startsAt: DateTime.parse(input.startsAtIso),
      pushEnabled: input.pushEnabled,
      remindOffsetMinutes: input.remindOffsetMinutes,
      recurrence: input.recurrence == null
          ? null
          : ScheduledItemRecurrence(
              rule: input.recurrence!.rule,
              interval: input.recurrence!.interval,
              until: _parseDateTime(input.recurrence!.untilIso),
            ),
      rowVersion: input.rowVersion,
    );
  }

  UpsertVetVisitPayload _toUpsertVetVisitPayload(UpsertVetVisitInput input) {
    return UpsertVetVisitPayload(
      status: input.status,
      visitType: input.visitType,
      scheduledAt: _parseDateTime(input.scheduledAtIso),
      completedAt: _parseDateTime(input.completedAtIso),
      reasonText: input.reasonText,
      resultText: input.resultText,
      clinicName: input.clinicName,
      vetName: input.vetName,
      attachmentFileIds: input.attachmentFileIds,
      rowVersion: input.rowVersion,
    );
  }

  UpsertVaccinationPayload _toUpsertVaccinationPayload(
    UpsertVaccinationInput input,
  ) {
    return UpsertVaccinationPayload(
      status: input.status,
      vaccineName: input.vaccineName,
      catalogMedicationId: input.catalogMedicationId,
      scheduledAt: _parseDateTime(input.scheduledAtIso),
      administeredAt: _parseDateTime(input.administeredAtIso),
      nextDueAt: _parseDateTime(input.nextDueAtIso),
      vetVisitId: input.vetVisitId,
      clinicName: input.clinicName,
      vetName: input.vetName,
      notes: input.notes,
      attachmentFileIds: input.attachmentFileIds,
      rowVersion: input.rowVersion,
    );
  }

  UpsertProcedurePayload _toUpsertProcedurePayload(
    UpsertProcedureInput input,
  ) {
    return UpsertProcedurePayload(
      status: input.status,
      procedureType: input.procedureType,
      title: input.title,
      description: input.description,
      catalogMedicationId: input.catalogMedicationId,
      productName: input.productName,
      scheduledAt: _parseDateTime(input.scheduledAtIso),
      performedAt: _parseDateTime(input.performedAtIso),
      nextDueAt: _parseDateTime(input.nextDueAtIso),
      vetVisitId: input.vetVisitId,
      notes: input.notes,
      attachmentFileIds: input.attachmentFileIds,
      rowVersion: input.rowVersion,
    );
  }

  UpsertMedicalRecordPayload _toUpsertMedicalRecordPayload(
    UpsertMedicalRecordInput input,
  ) {
    return UpsertMedicalRecordPayload(
      recordType: input.recordType,
      status: input.status,
      title: input.title,
      description: input.description,
      startedAt: _parseDateTime(input.startedAtIso),
      resolvedAt: _parseDateTime(input.resolvedAtIso),
      attachmentFileIds: input.attachmentFileIds,
      rowVersion: input.rowVersion,
    );
  }

  LogTypeMetricRequirementPayload _toLogTypeMetricRequirementPayload(
    LogTypeMetricRequirementInput input,
  ) {
    return LogTypeMetricRequirementPayload(
      metricId: input.metricId,
      isRequired: input.isRequired,
    );
  }

  DateTime? _parseDateTime(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    return DateTime.parse(value);
  }
}
