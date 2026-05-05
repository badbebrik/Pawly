import '../../../../core/network/models/health_models.dart' as api;
import '../../models/health_models.dart';

HealthPermissionSet mapHealthPermissionSet(api.HealthPermissionSet item) {
  return HealthPermissionSet(
    healthRead: item.healthRead,
    healthWrite: item.healthWrite,
    logRead: item.logRead,
  );
}

HealthDictionaryItem mapHealthDictionaryItem(api.HealthDictionaryItem item) {
  return HealthDictionaryItem(
    id: item.id,
    kind: item.kind,
    petId: item.petId,
    code: item.code,
    name: item.name,
    isSystem: item.isSystem,
    isArchived: item.isArchived,
  );
}

HealthBootstrapEnums mapHealthBootstrapEnums(api.HealthBootstrapEnums enums) {
  return HealthBootstrapEnums(
    vetVisitStatuses: enums.vetVisitStatuses,
    vetVisitTypes: enums.vetVisitTypes,
    vaccinationStatuses: enums.vaccinationStatuses,
    vaccinationTargets: enums.vaccinationTargets
        .map(mapHealthDictionaryItem)
        .toList(growable: false),
    procedureStatuses: enums.procedureStatuses,
    procedureTypeItems: enums.procedureTypeItems
        .map(mapHealthDictionaryItem)
        .toList(growable: false),
    medicalRecordTypeItems: enums.medicalRecordTypeItems
        .map(mapHealthDictionaryItem)
        .toList(growable: false),
    medicalRecordStatuses: enums.medicalRecordStatuses,
  );
}

HealthBootstrapResponse mapHealthBootstrap(api.HealthBootstrapResponse item) {
  return HealthBootstrapResponse(
    permissions: mapHealthPermissionSet(item.permissions),
    enums: mapHealthBootstrapEnums(item.enums),
  );
}

HealthAttachment mapHealthAttachment(api.HealthAttachment item) {
  return HealthAttachment(
    id: item.id,
    fileId: item.fileId,
    fileName: item.fileName,
    fileType: item.fileType,
    downloadUrl: item.downloadUrl,
    previewUrl: item.previewUrl,
    addedByUserId: item.addedByUserId,
    addedAt: item.addedAt,
  );
}

RelatedLog mapRelatedLog(api.RelatedLog item) {
  return RelatedLog(
    id: item.id,
    occurredAt: item.occurredAt,
    logTypeName: item.logTypeName,
    descriptionPreview: item.descriptionPreview,
    source: item.source,
  );
}

VetVisitCard mapVetVisitCard(api.VetVisitCard item) {
  return VetVisitCard(
    id: item.id,
    petId: item.petId,
    status: item.status,
    visitType: item.visitType,
    title: item.title,
    scheduledAt: item.scheduledAt,
    completedAt: item.completedAt,
    reasonText: item.reasonText,
    resultText: item.resultText,
    clinicName: item.clinicName,
    vetName: item.vetName,
    relatedLogsCount: item.relatedLogsCount,
    attachmentsCount: item.attachmentsCount,
    rowVersion: item.rowVersion,
  );
}

VetVisit mapVetVisit(api.VetVisit item) {
  return VetVisit(
    id: item.id,
    petId: item.petId,
    status: item.status,
    visitType: item.visitType,
    title: item.title,
    scheduledAt: item.scheduledAt,
    completedAt: item.completedAt,
    reasonText: item.reasonText,
    resultText: item.resultText,
    clinicName: item.clinicName,
    vetName: item.vetName,
    relatedLogs: item.relatedLogs.map(mapRelatedLog).toList(growable: false),
    attachments: item.attachments.map(mapHealthAttachment).toList(
          growable: false,
        ),
    rowVersion: item.rowVersion,
    canEdit: item.canEdit,
    canDelete: item.canDelete,
  );
}

VaccinationCard mapVaccinationCard(api.VaccinationCard item) {
  return VaccinationCard(
    id: item.id,
    petId: item.petId,
    status: item.status,
    vaccineName: item.vaccineName,
    catalogMedicationId: item.catalogMedicationId,
    targets: item.targets.map(mapHealthDictionaryItem).toList(growable: false),
    scheduledAt: item.scheduledAt,
    administeredAt: item.administeredAt,
    nextDueAt: item.nextDueAt,
    vetVisitId: item.vetVisitId,
    clinicName: item.clinicName,
    vetName: item.vetName,
    notesPreview: item.notesPreview,
    attachmentsCount: item.attachmentsCount,
    rowVersion: item.rowVersion,
  );
}

Vaccination mapVaccination(api.Vaccination item) {
  return Vaccination(
    id: item.id,
    petId: item.petId,
    status: item.status,
    vaccineName: item.vaccineName,
    catalogMedicationId: item.catalogMedicationId,
    targets: item.targets.map(mapHealthDictionaryItem).toList(growable: false),
    scheduledAt: item.scheduledAt,
    administeredAt: item.administeredAt,
    nextDueAt: item.nextDueAt,
    vetVisitId: item.vetVisitId,
    clinicName: item.clinicName,
    vetName: item.vetName,
    notes: item.notes,
    attachments: item.attachments.map(mapHealthAttachment).toList(
          growable: false,
        ),
    rowVersion: item.rowVersion,
    canEdit: item.canEdit,
    canDelete: item.canDelete,
  );
}

ProcedureCard mapProcedureCard(api.ProcedureCard item) {
  return ProcedureCard(
    id: item.id,
    petId: item.petId,
    status: item.status,
    procedureTypeItem: item.procedureTypeItem == null
        ? null
        : mapHealthDictionaryItem(item.procedureTypeItem!),
    title: item.title,
    descriptionPreview: item.descriptionPreview,
    catalogMedicationId: item.catalogMedicationId,
    productName: item.productName,
    scheduledAt: item.scheduledAt,
    performedAt: item.performedAt,
    nextDueAt: item.nextDueAt,
    vetVisitId: item.vetVisitId,
    notesPreview: item.notesPreview,
    attachmentsCount: item.attachmentsCount,
    rowVersion: item.rowVersion,
  );
}

Procedure mapProcedure(api.Procedure item) {
  return Procedure(
    id: item.id,
    petId: item.petId,
    status: item.status,
    procedureTypeItem: item.procedureTypeItem == null
        ? null
        : mapHealthDictionaryItem(item.procedureTypeItem!),
    title: item.title,
    description: item.description,
    catalogMedicationId: item.catalogMedicationId,
    productName: item.productName,
    scheduledAt: item.scheduledAt,
    performedAt: item.performedAt,
    nextDueAt: item.nextDueAt,
    vetVisitId: item.vetVisitId,
    notes: item.notes,
    attachments: item.attachments.map(mapHealthAttachment).toList(
          growable: false,
        ),
    rowVersion: item.rowVersion,
    canEdit: item.canEdit,
    canDelete: item.canDelete,
  );
}

MedicalRecordCard mapMedicalRecordCard(api.MedicalRecordCard item) {
  return MedicalRecordCard(
    id: item.id,
    petId: item.petId,
    recordTypeItem: item.recordTypeItem == null
        ? null
        : mapHealthDictionaryItem(item.recordTypeItem!),
    status: item.status,
    title: item.title,
    descriptionPreview: item.descriptionPreview,
    startedAt: item.startedAt,
    resolvedAt: item.resolvedAt,
    attachmentsCount: item.attachmentsCount,
    rowVersion: item.rowVersion,
  );
}

MedicalRecord mapMedicalRecord(api.MedicalRecord item) {
  return MedicalRecord(
    id: item.id,
    petId: item.petId,
    recordTypeItem: item.recordTypeItem == null
        ? null
        : mapHealthDictionaryItem(item.recordTypeItem!),
    status: item.status,
    title: item.title,
    description: item.description,
    startedAt: item.startedAt,
    resolvedAt: item.resolvedAt,
    attachments: item.attachments.map(mapHealthAttachment).toList(
          growable: false,
        ),
    rowVersion: item.rowVersion,
    canEdit: item.canEdit,
    canDelete: item.canDelete,
  );
}
