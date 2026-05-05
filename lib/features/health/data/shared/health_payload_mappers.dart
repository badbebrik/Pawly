import '../../../../core/network/models/common_models.dart';
import '../../../../core/network/models/health_models.dart';
import '../../../shared/attachments/data/attachment_input.dart';
import '../../models/medical_records/medical_record_inputs.dart';
import '../../models/procedures/procedure_inputs.dart';
import '../../models/shared/health_inputs.dart';
import '../../models/vaccinations/vaccination_inputs.dart';
import '../../models/vet_visits/vet_visit_inputs.dart';

UpsertVetVisitPayload toUpsertVetVisitPayload(UpsertVetVisitInput input) {
  return UpsertVetVisitPayload(
    status: input.status,
    visitType: input.visitType,
    title: emptyToNull(input.title),
    scheduledAt: parseDateTime(input.scheduledAtIso),
    completedAt: parseDateTime(input.completedAtIso),
    reasonText: input.reasonText,
    resultText: input.resultText,
    clinicName: input.clinicName,
    vetName: input.vetName,
    attachments: toAttachmentPayloads(input.attachments),
    attachmentFileIds: input.attachmentFileIds,
    reminder: toHealthEntityReminderPayload(input.reminder),
    rowVersion: input.rowVersion,
  );
}

UpsertVaccinationPayload toUpsertVaccinationPayload(
  UpsertVaccinationInput input,
) {
  return UpsertVaccinationPayload(
    status: input.status,
    vaccineName: input.vaccineName,
    catalogMedicationId: input.catalogMedicationId,
    targets: toHealthDictionaryRefPayloads(input.targets),
    scheduledAt: parseDateTime(input.scheduledAtIso),
    administeredAt: parseDateTime(input.administeredAtIso),
    nextDueAt: parseDateTime(input.nextDueAtIso),
    vetVisitId: input.vetVisitId,
    clinicName: input.clinicName,
    vetName: input.vetName,
    notes: input.notes,
    attachments: toAttachmentPayloads(input.attachments),
    attachmentFileIds: input.attachmentFileIds,
    reminder: toHealthEntityReminderPayload(input.reminder),
    rowVersion: input.rowVersion,
  );
}

UpsertProcedurePayload toUpsertProcedurePayload(UpsertProcedureInput input) {
  return UpsertProcedurePayload(
    status: input.status,
    procedureTypeId: input.procedureTypeId,
    procedureTypeName: emptyToNull(input.procedureTypeName),
    title: input.title,
    description: input.description,
    catalogMedicationId: input.catalogMedicationId,
    productName: input.productName,
    scheduledAt: parseDateTime(input.scheduledAtIso),
    performedAt: parseDateTime(input.performedAtIso),
    nextDueAt: parseDateTime(input.nextDueAtIso),
    vetVisitId: input.vetVisitId,
    notes: input.notes,
    attachments: toAttachmentPayloads(input.attachments),
    attachmentFileIds: input.attachmentFileIds,
    reminder: toHealthEntityReminderPayload(input.reminder),
    rowVersion: input.rowVersion,
  );
}

UpsertMedicalRecordPayload toUpsertMedicalRecordPayload(
  UpsertMedicalRecordInput input,
) {
  return UpsertMedicalRecordPayload(
    recordTypeId: input.recordTypeId,
    recordTypeName: emptyToNull(input.recordTypeName),
    status: input.status,
    title: input.title,
    description: input.description,
    startedAt: parseDateTime(input.startedAtIso),
    resolvedAt: parseDateTime(input.resolvedAtIso),
    attachments: toAttachmentPayloads(input.attachments),
    attachmentFileIds: input.attachmentFileIds,
    rowVersion: input.rowVersion,
  );
}

List<AttachmentPayload>? toAttachmentPayloads(
  List<AttachmentInput>? attachments,
) {
  return attachments
      ?.map(
        (item) => AttachmentPayload(
          fileId: item.fileId,
          fileName: emptyToNull(item.fileName),
        ),
      )
      .toList(growable: false);
}

List<HealthDictionaryRefPayload>? toHealthDictionaryRefPayloads(
  List<HealthDictionaryRefInput>? refs,
) {
  return refs
      ?.map(
        (item) => HealthDictionaryRefPayload(
          id: emptyToNull(item.id),
          name: emptyToNull(item.name),
        ),
      )
      .where((item) => item.id != null || item.name != null)
      .toList(growable: false);
}

String? emptyToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? parseDateTime(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  return DateTime.parse(value);
}

HealthEntityReminderPayload? toHealthEntityReminderPayload(
  HealthEntityReminderInput? input,
) {
  if (input == null) {
    return null;
  }
  return HealthEntityReminderPayload(
    pushEnabled: input.pushEnabled,
    remindOffsetMinutes: input.remindOffsetMinutes,
  );
}
