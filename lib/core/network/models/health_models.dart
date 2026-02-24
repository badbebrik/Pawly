import 'json_map.dart';
import 'json_parsers.dart';

class HealthPermissionSet {
  const HealthPermissionSet({
    required this.healthRead,
    required this.healthWrite,
    required this.logRead,
  });

  final bool healthRead;
  final bool healthWrite;
  final bool logRead;

  factory HealthPermissionSet.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthPermissionSet(
      healthRead: asBool(json['health_read']),
      healthWrite: asBool(json['health_write']),
      logRead: asBool(json['log_read']),
    );
  }
}

class HealthBootstrapEnums {
  const HealthBootstrapEnums({
    required this.vetVisitStatuses,
    required this.vetVisitTypes,
    required this.vaccinationStatuses,
    required this.procedureStatuses,
    required this.procedureTypes,
    required this.medicalRecordTypes,
    required this.medicalRecordStatuses,
  });

  final List<String> vetVisitStatuses;
  final List<String> vetVisitTypes;
  final List<String> vaccinationStatuses;
  final List<String> procedureStatuses;
  final List<String> procedureTypes;
  final List<String> medicalRecordTypes;
  final List<String> medicalRecordStatuses;

  factory HealthBootstrapEnums.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthBootstrapEnums(
      vetVisitStatuses: _decodeStringList(json['vet_visit_statuses']),
      vetVisitTypes: _decodeStringList(json['vet_visit_types']),
      vaccinationStatuses: _decodeStringList(json['vaccination_statuses']),
      procedureStatuses: _decodeStringList(json['procedure_statuses']),
      procedureTypes: _decodeStringList(json['procedure_types']),
      medicalRecordTypes: _decodeStringList(json['medical_record_types']),
      medicalRecordStatuses: _decodeStringList(json['medical_record_statuses']),
    );
  }
}

class HealthBootstrapResponse {
  const HealthBootstrapResponse({
    required this.permissions,
    required this.enums,
  });

  final HealthPermissionSet permissions;
  final HealthBootstrapEnums enums;

  factory HealthBootstrapResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthBootstrapResponse(
      permissions: HealthPermissionSet.fromJson(json['permissions']),
      enums: HealthBootstrapEnums.fromJson(json['enums']),
    );
  }
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

  factory HealthAttachment.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthAttachment(
      id: asString(json['id']),
      fileId: asString(json['file_id']),
      fileName: asNullableString(json['file_name']),
      fileType: asString(json['file_type']),
      downloadUrl: asNullableString(json['download_url']),
      previewUrl: asNullableString(json['preview_url']),
      addedByUserId: asNullableString(json['added_by_user_id']),
      addedAt: asDateTime(json['added_at']),
    );
  }
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

  factory RelatedLog.fromJson(Object? data) {
    final json = asJsonMap(data);
    return RelatedLog(
      id: asString(json['id']),
      occurredAt: asDateTime(json['occurred_at']),
      logTypeName: asNullableString(json['log_type_name']),
      descriptionPreview: asNullableString(json['description_preview']),
      source: asString(json['source']),
    );
  }
}

class HealthDayItemSource {
  const HealthDayItemSource({
    this.visitId,
    this.vaccinationId,
    this.procedureId,
  });

  final String? visitId;
  final String? vaccinationId;
  final String? procedureId;

  factory HealthDayItemSource.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthDayItemSource(
      visitId: asNullableString(json['visit_id']),
      vaccinationId: asNullableString(json['vaccination_id']),
      procedureId: asNullableString(json['procedure_id']),
    );
  }
}

class HealthDayItem {
  const HealthDayItem({
    required this.itemType,
    required this.entityId,
    required this.title,
    this.subtitle,
    this.scheduledFor,
    required this.status,
    required this.source,
  });

  final String itemType;
  final String entityId;
  final String title;
  final String? subtitle;
  final DateTime? scheduledFor;
  final String status;
  final HealthDayItemSource source;

  factory HealthDayItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthDayItem(
      itemType: asString(json['item_type']),
      entityId: asString(json['entity_id']),
      title: asString(json['title']),
      subtitle: asNullableString(json['subtitle']),
      scheduledFor: asDateTime(json['scheduled_for']),
      status: asString(json['status']),
      source: HealthDayItemSource.fromJson(json['source']),
    );
  }
}

class HealthDayResponse {
  const HealthDayResponse({
    required this.date,
    required this.items,
  });

  final String date;
  final List<HealthDayItem> items;

  factory HealthDayResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthDayResponse(
      date: asString(json['date']),
      items: _decodeList(json['items'], HealthDayItem.fromJson),
    );
  }
}

class VetVisitCard {
  const VetVisitCard({
    required this.id,
    required this.petId,
    required this.status,
    required this.visitType,
    this.scheduledAt,
    this.completedAt,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    required this.relatedLogsCount,
    required this.attachmentsCount,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
  });

  final String id;
  final String petId;
  final String status;
  final String visitType;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final int relatedLogsCount;
  final int attachmentsCount;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory VetVisitCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    return VetVisitCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      visitType: asString(json['visit_type']),
      scheduledAt: asDateTime(json['scheduled_at']),
      completedAt: asDateTime(json['completed_at']),
      reasonText: asNullableString(json['reason_text']),
      resultText: asNullableString(json['result_text']),
      clinicName: asNullableString(json['clinic_name']),
      vetName: asNullableString(json['vet_name']),
      relatedLogsCount: asInt(json['related_logs_count']),
      attachmentsCount: asInt(json['attachments_count']),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
    );
  }
}

class VetVisit {
  const VetVisit({
    required this.id,
    required this.petId,
    required this.status,
    required this.visitType,
    this.scheduledAt,
    this.completedAt,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    required this.relatedLogs,
    required this.attachments,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String status;
  final String visitType;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final List<RelatedLog> relatedLogs;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;
  final bool canEdit;
  final bool canDelete;

  factory VetVisit.fromJson(Object? data) {
    final json = asJsonMap(data);
    return VetVisit(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      visitType: asString(json['visit_type']),
      scheduledAt: asDateTime(json['scheduled_at']),
      completedAt: asDateTime(json['completed_at']),
      reasonText: asNullableString(json['reason_text']),
      resultText: asNullableString(json['result_text']),
      clinicName: asNullableString(json['clinic_name']),
      vetName: asNullableString(json['vet_name']),
      relatedLogs: _decodeList(json['related_logs'], RelatedLog.fromJson),
      attachments: _decodeList(json['attachments'], HealthAttachment.fromJson),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
      canEdit: asBool(json['can_edit']),
      canDelete: asBool(json['can_delete']),
    );
  }
}

class VetVisitListResponse {
  const VetVisitListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<VetVisitCard> items;
  final String? nextCursor;

  factory VetVisitListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return VetVisitListResponse(
      items: _decodeList(json['items'], VetVisitCard.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class UpsertVetVisitPayload {
  const UpsertVetVisitPayload({
    required this.status,
    required this.visitType,
    this.scheduledAt,
    this.completedAt,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String status;
  final String visitType;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final List<String> attachmentFileIds;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'status': status,
        'visit_type': visitType,
        'scheduled_at': _toIso8601String(scheduledAt),
        'completed_at': _toIso8601String(completedAt),
        'reason_text': reasonText,
        'result_text': resultText,
        'clinic_name': clinicName,
        'vet_name': vetName,
        'attachment_file_ids': attachmentFileIds,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class LinkVetVisitLogPayload {
  const LinkVetVisitLogPayload({
    required this.logId,
  });

  final String logId;

  JsonMap toJson() => <String, dynamic>{'log_id': logId};
}

class VaccinationCard {
  const VaccinationCard({
    required this.id,
    required this.petId,
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.scheduledAt,
    this.administeredAt,
    this.nextDueAt,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notesPreview,
    required this.attachmentsCount,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
  });

  final String id;
  final String petId;
  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final DateTime? scheduledAt;
  final DateTime? administeredAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notesPreview;
  final int attachmentsCount;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory VaccinationCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    return VaccinationCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      vaccineName: asString(json['vaccine_name']),
      catalogMedicationId: asNullableString(json['catalog_medication_id']),
      scheduledAt: asDateTime(json['scheduled_at']),
      administeredAt: asDateTime(json['administered_at']),
      nextDueAt: asDateTime(json['next_due_at']),
      vetVisitId: asNullableString(json['vet_visit_id']),
      clinicName: asNullableString(json['clinic_name']),
      vetName: asNullableString(json['vet_name']),
      notesPreview: asNullableString(json['notes_preview']),
      attachmentsCount: asInt(json['attachments_count']),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
    );
  }
}

class Vaccination {
  const Vaccination({
    required this.id,
    required this.petId,
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.scheduledAt,
    this.administeredAt,
    this.nextDueAt,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notes,
    required this.attachments,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final DateTime? scheduledAt;
  final DateTime? administeredAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notes;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;
  final bool canEdit;
  final bool canDelete;

  factory Vaccination.fromJson(Object? data) {
    final json = asJsonMap(data);
    return Vaccination(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      vaccineName: asString(json['vaccine_name']),
      catalogMedicationId: asNullableString(json['catalog_medication_id']),
      scheduledAt: asDateTime(json['scheduled_at']),
      administeredAt: asDateTime(json['administered_at']),
      nextDueAt: asDateTime(json['next_due_at']),
      vetVisitId: asNullableString(json['vet_visit_id']),
      clinicName: asNullableString(json['clinic_name']),
      vetName: asNullableString(json['vet_name']),
      notes: asNullableString(json['notes']),
      attachments: _decodeList(json['attachments'], HealthAttachment.fromJson),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
      canEdit: asBool(json['can_edit']),
      canDelete: asBool(json['can_delete']),
    );
  }
}

class VaccinationListResponse {
  const VaccinationListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<VaccinationCard> items;
  final String? nextCursor;

  factory VaccinationListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return VaccinationListResponse(
      items: _decodeList(json['items'], VaccinationCard.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class UpsertVaccinationPayload {
  const UpsertVaccinationPayload({
    required this.status,
    required this.vaccineName,
    this.catalogMedicationId,
    this.scheduledAt,
    this.administeredAt,
    this.nextDueAt,
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
  final DateTime? scheduledAt;
  final DateTime? administeredAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notes;
  final List<String> attachmentFileIds;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'status': status,
        'vaccine_name': vaccineName,
        'catalog_medication_id': catalogMedicationId,
        'scheduled_at': _toIso8601String(scheduledAt),
        'administered_at': _toIso8601String(administeredAt),
        'next_due_at': _toIso8601String(nextDueAt),
        'vet_visit_id': vetVisitId,
        'clinic_name': clinicName,
        'vet_name': vetName,
        'notes': notes,
        'attachment_file_ids': attachmentFileIds,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class ProcedureCard {
  const ProcedureCard({
    required this.id,
    required this.petId,
    required this.status,
    required this.procedureType,
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
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
  });

  final String id;
  final String petId;
  final String status;
  final String procedureType;
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
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory ProcedureCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ProcedureCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      procedureType: asString(json['procedure_type']),
      title: asString(json['title']),
      descriptionPreview: asNullableString(json['description_preview']),
      catalogMedicationId: asNullableString(json['catalog_medication_id']),
      productName: asNullableString(json['product_name']),
      scheduledAt: asDateTime(json['scheduled_at']),
      performedAt: asDateTime(json['performed_at']),
      nextDueAt: asDateTime(json['next_due_at']),
      vetVisitId: asNullableString(json['vet_visit_id']),
      notesPreview: asNullableString(json['notes_preview']),
      attachmentsCount: asInt(json['attachments_count']),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
    );
  }
}

class Procedure {
  const Procedure({
    required this.id,
    required this.petId,
    required this.status,
    required this.procedureType,
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
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String status;
  final String procedureType;
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
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;
  final bool canEdit;
  final bool canDelete;

  factory Procedure.fromJson(Object? data) {
    final json = asJsonMap(data);
    return Procedure(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      status: asString(json['status']),
      procedureType: asString(json['procedure_type']),
      title: asString(json['title']),
      description: asNullableString(json['description']),
      catalogMedicationId: asNullableString(json['catalog_medication_id']),
      productName: asNullableString(json['product_name']),
      scheduledAt: asDateTime(json['scheduled_at']),
      performedAt: asDateTime(json['performed_at']),
      nextDueAt: asDateTime(json['next_due_at']),
      vetVisitId: asNullableString(json['vet_visit_id']),
      notes: asNullableString(json['notes']),
      attachments: _decodeList(json['attachments'], HealthAttachment.fromJson),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
      canEdit: asBool(json['can_edit']),
      canDelete: asBool(json['can_delete']),
    );
  }
}

class ProcedureListResponse {
  const ProcedureListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<ProcedureCard> items;
  final String? nextCursor;

  factory ProcedureListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ProcedureListResponse(
      items: _decodeList(json['items'], ProcedureCard.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class UpsertProcedurePayload {
  const UpsertProcedurePayload({
    required this.status,
    required this.procedureType,
    required this.title,
    this.description,
    this.catalogMedicationId,
    this.productName,
    this.scheduledAt,
    this.performedAt,
    this.nextDueAt,
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
  final DateTime? scheduledAt;
  final DateTime? performedAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? notes;
  final List<String> attachmentFileIds;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'status': status,
        'procedure_type': procedureType,
        'title': title,
        'description': description,
        'catalog_medication_id': catalogMedicationId,
        'product_name': productName,
        'scheduled_at': _toIso8601String(scheduledAt),
        'performed_at': _toIso8601String(performedAt),
        'next_due_at': _toIso8601String(nextDueAt),
        'vet_visit_id': vetVisitId,
        'notes': notes,
        'attachment_file_ids': attachmentFileIds,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class MedicalRecordCard {
  const MedicalRecordCard({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.status,
    required this.title,
    this.descriptionPreview,
    this.startedAt,
    this.resolvedAt,
    required this.attachmentsCount,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
  });

  final String id;
  final String petId;
  final String recordType;
  final String status;
  final String title;
  final String? descriptionPreview;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final int attachmentsCount;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory MedicalRecordCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MedicalRecordCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      recordType: asString(json['record_type']),
      status: asString(json['status']),
      title: asString(json['title']),
      descriptionPreview: asNullableString(json['description_preview']),
      startedAt: asDateTime(json['started_at']),
      resolvedAt: asDateTime(json['resolved_at']),
      attachmentsCount: asInt(json['attachments_count']),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
    );
  }
}

class MedicalRecord {
  const MedicalRecord({
    required this.id,
    required this.petId,
    required this.recordType,
    required this.status,
    required this.title,
    this.description,
    this.startedAt,
    this.resolvedAt,
    required this.attachments,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final String recordType;
  final String status;
  final String title;
  final String? description;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final List<HealthAttachment> attachments;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;
  final bool canEdit;
  final bool canDelete;

  factory MedicalRecord.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MedicalRecord(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      recordType: asString(json['record_type']),
      status: asString(json['status']),
      title: asString(json['title']),
      description: asNullableString(json['description']),
      startedAt: asDateTime(json['started_at']),
      resolvedAt: asDateTime(json['resolved_at']),
      attachments: _decodeList(json['attachments'], HealthAttachment.fromJson),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
      canEdit: asBool(json['can_edit']),
      canDelete: asBool(json['can_delete']),
    );
  }
}

class MedicalRecordListResponse {
  const MedicalRecordListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<MedicalRecordCard> items;
  final String? nextCursor;

  factory MedicalRecordListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MedicalRecordListResponse(
      items: _decodeList(json['items'], MedicalRecordCard.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class UpsertMedicalRecordPayload {
  const UpsertMedicalRecordPayload({
    required this.recordType,
    required this.status,
    required this.title,
    this.description,
    this.startedAt,
    this.resolvedAt,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String recordType;
  final String status;
  final String title;
  final String? description;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final List<String> attachmentFileIds;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'record_type': recordType,
        'status': status,
        'title': title,
        'description': description,
        'started_at': _toIso8601String(startedAt),
        'resolved_at': _toIso8601String(resolvedAt),
        'attachment_file_ids': attachmentFileIds,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

List<T> _decodeList<T>(Object? data, T Function(Object? item) decoder) {
  if (data is! List) {
    return <T>[];
  }
  return data.map(decoder).toList(growable: false);
}

List<String> _decodeStringList(Object? data) {
  if (data is! List) {
    return const <String>[];
  }
  return data.map((Object? item) => asString(item)).toList(growable: false);
}

String? _toIso8601String(DateTime? value) {
  return value?.toUtc().toIso8601String();
}
