class LogListQuery {
  const LogListQuery({
    this.cursor,
    this.limit = 30,
    this.searchQuery,
    this.dateFrom,
    this.dateTo,
    this.typeIds = const <String>[],
    this.source,
    this.hasAttachments,
    this.hasMetrics,
    this.sort = 'occurred_at_desc',
    this.includeFacets = true,
  });

  final String? cursor;
  final int limit;
  final String? searchQuery;
  final String? dateFrom;
  final String? dateTo;
  final List<String> typeIds;
  final String? source;
  final bool? hasAttachments;
  final bool? hasMetrics;
  final String sort;
  final bool includeFacets;
}

class PetDocumentsQuery {
  const PetDocumentsQuery({
    this.cursor,
    this.limit = 30,
    this.entityType,
    this.fileType,
  });

  final String? cursor;
  final int limit;
  final String? entityType;
  final String? fileType;
}

class LogMetricInput {
  const LogMetricInput({
    required this.metricId,
    required this.valueNum,
  });

  final String metricId;
  final double valueNum;
}

class UpsertLogInput {
  const UpsertLogInput({
    required this.occurredAtIso,
    this.logTypeId,
    this.description,
    this.metricValues = const <LogMetricInput>[],
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String occurredAtIso;
  final String? logTypeId;
  final String? description;
  final List<LogMetricInput> metricValues;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}

class LogTypeMetricRequirementInput {
  const LogTypeMetricRequirementInput({
    required this.metricId,
    required this.isRequired,
  });

  final String metricId;
  final bool isRequired;
}

class CreateLogTypeInput {
  const CreateLogTypeInput({
    required this.name,
    this.metricRequirements = const <LogTypeMetricRequirementInput>[],
  });

  final String name;
  final List<LogTypeMetricRequirementInput> metricRequirements;
}

class UpdateLogTypeInput extends CreateLogTypeInput {
  const UpdateLogTypeInput({
    required super.name,
    super.metricRequirements,
    required this.rowVersion,
  });

  final int rowVersion;
}

class UpsertMetricInput {
  const UpsertMetricInput({
    required this.name,
    required this.inputKind,
    this.unitCode,
    this.minValue,
    this.maxValue,
  });

  final String name;
  final String inputKind;
  final String? unitCode;
  final double? minValue;
  final double? maxValue;
}

class AnalyticsMetricsQuery {
  const AnalyticsMetricsQuery({
    this.query,
    this.dateFrom,
    this.dateTo,
    this.source,
    this.typeIds = const <String>[],
    this.limit,
  });

  final String? query;
  final String? dateFrom;
  final String? dateTo;
  final String? source;
  final List<String> typeIds;
  final int? limit;
}

class UpdateMetricInput extends UpsertMetricInput {
  const UpdateMetricInput({
    required super.name,
    required super.inputKind,
    super.unitCode,
    super.minValue,
    super.maxValue,
    required this.rowVersion,
  });

  final int rowVersion;
}

class AnalyticsSeriesQuery {
  const AnalyticsSeriesQuery({
    this.dateFrom,
    this.dateTo,
    this.source,
    this.typeIds = const <String>[],
    this.sort = 'occurred_at_asc',
    this.includeSummary = true,
  });

  final String? dateFrom;
  final String? dateTo;
  final String? source;
  final List<String> typeIds;
  final String sort;
  final bool includeSummary;
}

class VetVisitListQuery {
  const VetVisitListQuery({
    this.cursor,
    this.limit = 20,
    this.status,
    this.bucket,
    this.dateFrom,
    this.dateTo,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? status;
  final String? bucket;
  final String? dateFrom;
  final String? dateTo;
  final String? sort;
}

class UpsertVetVisitInput {
  const UpsertVetVisitInput({
    required this.status,
    required this.visitType,
    this.scheduledAtIso,
    this.completedAtIso,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String status;
  final String visitType;
  final String? scheduledAtIso;
  final String? completedAtIso;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}

class VaccinationListQuery {
  const VaccinationListQuery({
    this.cursor,
    this.limit = 20,
    this.status,
    this.bucket,
    this.dateFrom,
    this.dateTo,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? status;
  final String? bucket;
  final String? dateFrom;
  final String? dateTo;
  final String? sort;
}

class UpsertVaccinationInput {
  const UpsertVaccinationInput({
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.scheduledAtIso,
    this.administeredAtIso,
    this.nextDueAtIso,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notes,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final String? scheduledAtIso;
  final String? administeredAtIso;
  final String? nextDueAtIso;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notes;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}

class ProcedureListQuery {
  const ProcedureListQuery({
    this.cursor,
    this.limit = 20,
    this.status,
    this.bucket,
    this.procedureType,
    this.dateFrom,
    this.dateTo,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? status;
  final String? bucket;
  final String? procedureType;
  final String? dateFrom;
  final String? dateTo;
  final String? sort;
}

class UpsertProcedureInput {
  const UpsertProcedureInput({
    required this.status,
    required this.procedureType,
    required this.title,
    this.description,
    this.catalogMedicationId,
    this.productName,
    this.scheduledAtIso,
    this.performedAtIso,
    this.nextDueAtIso,
    this.vetVisitId,
    this.notes,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String status;
  final String procedureType;
  final String title;
  final String? description;
  final String? catalogMedicationId;
  final String? productName;
  final String? scheduledAtIso;
  final String? performedAtIso;
  final String? nextDueAtIso;
  final String? vetVisitId;
  final String? notes;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}

class MedicalRecordListQuery {
  const MedicalRecordListQuery({
    this.cursor,
    this.limit = 20,
    this.status,
    this.bucket,
    this.recordType,
    this.sort,
  });

  final String? cursor;
  final int limit;
  final String? status;
  final String? bucket;
  final String? recordType;
  final String? sort;
}

class UpsertMedicalRecordInput {
  const UpsertMedicalRecordInput({
    required this.recordType,
    required this.status,
    required this.title,
    this.description,
    this.startedAtIso,
    this.resolvedAtIso,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String recordType;
  final String status;
  final String title;
  final String? description;
  final String? startedAtIso;
  final String? resolvedAtIso;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}

class UploadHealthAttachmentInput {
  const UploadHealthAttachmentInput({
    required this.mimeType,
    required this.originalFilename,
    required this.expectedSizeBytes,
  });

  final String mimeType;
  final String originalFilename;
  final int expectedSizeBytes;
}

class ScheduledItemsQuery {
  const ScheduledItemsQuery({
    this.cursor,
    this.limit = 30,
    this.sourceType,
    this.dateFrom,
    this.dateTo,
    this.includePast,
  });

  final String? cursor;
  final int limit;
  final String? sourceType;
  final String? dateFrom;
  final String? dateTo;
  final bool? includePast;
}

class ScheduledItemOccurrencesQuery {
  const ScheduledItemOccurrencesQuery({
    this.cursor,
    this.limit = 30,
    this.sourceType,
    this.dateFrom,
    this.dateTo,
  });

  final String? cursor;
  final int limit;
  final String? sourceType;
  final String? dateFrom;
  final String? dateTo;
}

class ScheduledItemRecurrenceInput {
  const ScheduledItemRecurrenceInput({
    required this.rule,
    required this.interval,
    this.untilIso,
  });

  final String rule;
  final int interval;
  final String? untilIso;
}

class UpsertScheduledItemInput {
  const UpsertScheduledItemInput({
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.note,
    required this.startsAtIso,
    this.recurrence,
    this.rowVersion,
  });

  final String sourceType;
  final String? sourceId;
  final String title;
  final String? note;
  final String startsAtIso;
  final ScheduledItemRecurrenceInput? recurrence;
  final int? rowVersion;
}

class RegisterPushDeviceInput {
  const RegisterPushDeviceInput({
    required this.deviceId,
    required this.platform,
    required this.pushToken,
  });

  final String deviceId;
  final String platform;
  final String pushToken;
}
