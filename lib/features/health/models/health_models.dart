class HealthPermissionSet {
  const HealthPermissionSet({
    required this.healthRead,
    required this.healthWrite,
    required this.logRead,
  });

  final bool healthRead;
  final bool healthWrite;
  final bool logRead;
}

class HealthDictionaryItem {
  const HealthDictionaryItem({
    required this.id,
    required this.kind,
    this.petId,
    this.code,
    required this.name,
    required this.isSystem,
    required this.isArchived,
  });

  final String id;
  final String kind;
  final String? petId;
  final String? code;
  final String name;
  final bool isSystem;
  final bool isArchived;
}

class HealthBootstrapEnums {
  const HealthBootstrapEnums({
    required this.vetVisitStatuses,
    required this.vetVisitTypes,
    required this.vaccinationStatuses,
    required this.vaccinationTargets,
    required this.procedureStatuses,
    required this.procedureTypeItems,
    required this.medicalRecordTypeItems,
    required this.medicalRecordStatuses,
  });

  final List<String> vetVisitStatuses;
  final List<String> vetVisitTypes;
  final List<String> vaccinationStatuses;
  final List<HealthDictionaryItem> vaccinationTargets;
  final List<String> procedureStatuses;
  final List<HealthDictionaryItem> procedureTypeItems;
  final List<HealthDictionaryItem> medicalRecordTypeItems;
  final List<String> medicalRecordStatuses;
}

class HealthBootstrapResponse {
  const HealthBootstrapResponse({
    required this.permissions,
    required this.enums,
  });

  final HealthPermissionSet permissions;
  final HealthBootstrapEnums enums;
}

class HealthAttachment {
  const HealthAttachment({
    required this.id,
    required this.fileId,
    this.fileName,
    required this.fileType,
    this.downloadUrl,
    this.previewUrl,
    this.addedByUserId,
    this.addedAt,
  });

  final String id;
  final String fileId;
  final String? fileName;
  final String fileType;
  final String? downloadUrl;
  final String? previewUrl;
  final String? addedByUserId;
  final DateTime? addedAt;
}

class RelatedLog {
  const RelatedLog({
    required this.id,
    this.occurredAt,
    this.logTypeName,
    this.descriptionPreview,
    required this.source,
  });

  final String id;
  final DateTime? occurredAt;
  final String? logTypeName;
  final String? descriptionPreview;
  final String source;
}

class VetVisitCard {
  const VetVisitCard({
    required this.id,
    required this.petId,
    required this.status,
    required this.visitType,
    this.title,
    this.scheduledAt,
    this.completedAt,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    required this.relatedLogsCount,
    required this.attachmentsCount,
    required this.rowVersion,
  });

  final String id;
  final String petId;
  final String status;
  final String visitType;
  final String? title;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final int relatedLogsCount;
  final int attachmentsCount;
  final int rowVersion;
}

class VetVisit {
  const VetVisit({
    required this.id,
    required this.petId,
    required this.status,
    required this.visitType,
    this.title,
    this.scheduledAt,
    this.completedAt,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    required this.relatedLogs,
    required this.attachments,
    required this.rowVersion,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String status;
  final String visitType;
  final String? title;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final List<RelatedLog> relatedLogs;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final bool canEdit;
  final bool canDelete;
}

class VaccinationCard {
  const VaccinationCard({
    required this.id,
    required this.petId,
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.targets = const <HealthDictionaryItem>[],
    this.scheduledAt,
    this.administeredAt,
    this.nextDueAt,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notesPreview,
    required this.attachmentsCount,
    required this.rowVersion,
  });

  final String id;
  final String petId;
  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final List<HealthDictionaryItem> targets;
  final DateTime? scheduledAt;
  final DateTime? administeredAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notesPreview;
  final int attachmentsCount;
  final int rowVersion;
}

class Vaccination {
  const Vaccination({
    required this.id,
    required this.petId,
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.targets = const <HealthDictionaryItem>[],
    this.scheduledAt,
    this.administeredAt,
    this.nextDueAt,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notes,
    required this.attachments,
    required this.rowVersion,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final List<HealthDictionaryItem> targets;
  final DateTime? scheduledAt;
  final DateTime? administeredAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notes;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final bool canEdit;
  final bool canDelete;
}

class ProcedureCard {
  const ProcedureCard({
    required this.id,
    required this.petId,
    required this.status,
    this.procedureTypeItem,
    required this.title,
    this.descriptionPreview,
    this.catalogMedicationId,
    this.productName,
    this.scheduledAt,
    this.performedAt,
    this.nextDueAt,
    this.vetVisitId,
    this.notesPreview,
    required this.attachmentsCount,
    required this.rowVersion,
  });

  final String id;
  final String petId;
  final String status;
  final HealthDictionaryItem? procedureTypeItem;
  final String title;
  final String? descriptionPreview;
  final String? catalogMedicationId;
  final String? productName;
  final DateTime? scheduledAt;
  final DateTime? performedAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? notesPreview;
  final int attachmentsCount;
  final int rowVersion;
}

class Procedure {
  const Procedure({
    required this.id,
    required this.petId,
    required this.status,
    this.procedureTypeItem,
    required this.title,
    this.description,
    this.catalogMedicationId,
    this.productName,
    this.scheduledAt,
    this.performedAt,
    this.nextDueAt,
    this.vetVisitId,
    this.notes,
    required this.attachments,
    required this.rowVersion,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String status;
  final HealthDictionaryItem? procedureTypeItem;
  final String title;
  final String? description;
  final String? catalogMedicationId;
  final String? productName;
  final DateTime? scheduledAt;
  final DateTime? performedAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? notes;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final bool canEdit;
  final bool canDelete;
}

class MedicalRecordCard {
  const MedicalRecordCard({
    required this.id,
    required this.petId,
    this.recordTypeItem,
    required this.status,
    required this.title,
    this.descriptionPreview,
    this.startedAt,
    this.resolvedAt,
    required this.attachmentsCount,
    required this.rowVersion,
  });

  final String id;
  final String petId;
  final HealthDictionaryItem? recordTypeItem;
  final String status;
  final String title;
  final String? descriptionPreview;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final int attachmentsCount;
  final int rowVersion;
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.petId,
    this.recordTypeItem,
    required this.status,
    required this.title,
    this.description,
    this.startedAt,
    this.resolvedAt,
    required this.attachments,
    required this.rowVersion,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final HealthDictionaryItem? recordTypeItem;
  final String status;
  final String title;
  final String? description;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final bool canEdit;
  final bool canDelete;
}
