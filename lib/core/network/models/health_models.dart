import 'common_models.dart';
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

  factory HealthDictionaryItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthDictionaryItem(
      id: asString(json['id']),
      kind: asString(json['kind']),
      petId: asNullableString(json['pet_id']),
      code: asNullableString(json['code']),
      name: asString(json['name']),
      isSystem: asBool(json['is_system']),
      isArchived: asBool(json['is_archived']),
    );
  }
}

class HealthDictionaryRefPayload {
  const HealthDictionaryRefPayload({
    this.id,
    this.name,
  });

  final String? id;
  final String? name;

  JsonMap toJson() => <String, dynamic>{
        'id': id,
        'name': name,
      }..removeWhere((_, dynamic value) => value == null);
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

  factory HealthBootstrapEnums.fromJson(Object? data) {
    final json = asJsonMap(data);
    return HealthBootstrapEnums(
      vetVisitStatuses: _decodeStringList(json['vet_visit_statuses']),
      vetVisitTypes: _decodeStringList(json['vet_visit_types']),
      vaccinationStatuses: _decodeStringList(json['vaccination_statuses']),
      vaccinationTargets: _decodeList(
        json['vaccination_targets'],
        HealthDictionaryItem.fromJson,
      ),
      procedureStatuses: _decodeStringList(json['procedure_statuses']),
      procedureTypeItems: _decodeList(
        json['procedure_type_items'],
        HealthDictionaryItem.fromJson,
      ),
      medicalRecordTypeItems: _decodeList(
        json['medical_record_type_items'],
        HealthDictionaryItem.fromJson,
      ),
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

class InitHealthAttachmentUploadPayload {
  const InitHealthAttachmentUploadPayload({
    required this.mimeType,
    required this.originalFilename,
    required this.expectedSizeBytes,
    required this.entityType,
  });

  final String mimeType;
  final String originalFilename;
  final int expectedSizeBytes;
  final String entityType;

  JsonMap toJson() => <String, dynamic>{
        'mime_type': mimeType,
        'original_filename': originalFilename,
        'expected_size_bytes': expectedSizeBytes,
        'entity_type': entityType,
      };
}

class ConfirmHealthAttachmentUploadPayload {
  const ConfirmHealthAttachmentUploadPayload({
    required this.fileId,
    required this.sizeBytes,
  });

  final String fileId;
  final int sizeBytes;

  JsonMap toJson() => <String, dynamic>{
        'file_id': fileId,
        'size_bytes': sizeBytes,
      };
}

class UploadedHealthFile {
  const UploadedHealthFile({
    required this.id,
    required this.mimeType,
    required this.sizeBytes,
    this.originalFilename,
  });

  final String id;
  final String mimeType;
  final int sizeBytes;
  final String? originalFilename;

  factory UploadedHealthFile.fromJson(Object? data) {
    final json = asJsonMap(data);
    return UploadedHealthFile(
      id: asString(json['id']),
      mimeType: asString(json['mime_type']),
      sizeBytes: asInt(json['size_bytes']),
      originalFilename: asNullableString(json['original_filename']),
    );
  }
}

class ConfirmHealthAttachmentUploadResponse {
  const ConfirmHealthAttachmentUploadResponse({
    required this.file,
  });

  final UploadedHealthFile file;

  factory ConfirmHealthAttachmentUploadResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ConfirmHealthAttachmentUploadResponse(
      file: UploadedHealthFile.fromJson(json['file']),
    );
  }
}

class PetDocument {
  const PetDocument({
    this.id,
    required this.fileId,
    this.fileName,
    required this.fileType,
    this.downloadUrl,
    this.previewUrl,
    this.addedAt,
    this.addedByUserId,
    required this.entityType,
    required this.entityId,
  });

  final String? id;
  final String fileId;
  final String? fileName;
  final String fileType;
  final String? downloadUrl;
  final String? previewUrl;
  final DateTime? addedAt;
  final String? addedByUserId;
  final String entityType;
  final String entityId;

  factory PetDocument.fromJson(Object? data) {
    final json = asJsonMap(data);
    final envelope = json['document'];
    if (envelope != null) {
      return PetDocument.fromJson(envelope);
    }

    return PetDocument(
      id: asNullableString(json['id']) ?? asNullableString(json['document_id']),
      fileId: asString(json['file_id']),
      fileName: asNullableString(json['file_name']),
      fileType: asString(json['file_type']),
      downloadUrl: asNullableString(json['download_url']),
      previewUrl: asNullableString(json['preview_url']),
      addedAt: asDateTime(json['added_at']),
      addedByUserId: asNullableString(json['added_by_user_id']),
      entityType: asString(json['entity_type']),
      entityId: asString(json['entity_id']),
    );
  }
}

class UpdatePetDocumentPayload {
  const UpdatePetDocumentPayload({
    required this.fileName,
    this.rowVersion,
  });

  final String fileName;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'file_name': fileName,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class PetDocumentsListResponse {
  const PetDocumentsListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<PetDocument> items;
  final String? nextCursor;

  factory PetDocumentsListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return PetDocumentsListResponse(
      items: _decodeList(json['items'], PetDocument.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
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

class ScheduledItemRecurrence {
  const ScheduledItemRecurrence({
    required this.rule,
    required this.interval,
    this.until,
  });

  final String rule;
  final int interval;
  final DateTime? until;

  factory ScheduledItemRecurrence.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ScheduledItemRecurrence(
      rule: asString(json['rule']),
      interval: asInt(json['interval']),
      until: asDateTime(json['until']),
    );
  }

  JsonMap toJson() => <String, dynamic>{
        'rule': rule,
        'interval': interval,
        'until': _toIso8601String(until),
      };
}

class ScheduledItem {
  const ScheduledItem({
    required this.id,
    required this.petId,
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.note,
    this.startsAt,
    required this.pushEnabled,
    this.remindOffsetMinutes,
    this.recurrence,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
  });

  final String id;
  final String petId;
  final String sourceType;
  final String? sourceId;
  final String title;
  final String? note;
  final DateTime? startsAt;
  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final ScheduledItemRecurrence? recurrence;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory ScheduledItem.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ScheduledItem(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      sourceType: asString(json['source_type']),
      sourceId: asNullableString(json['source_id']),
      title: asString(json['title']),
      note: asNullableString(json['note']) ??
          asNullableString(json['note_preview']),
      startsAt: asDateTime(json['starts_at']),
      pushEnabled: asBool(json['push_enabled']),
      remindOffsetMinutes: json['remind_offset_minutes'] == null
          ? null
          : asInt(json['remind_offset_minutes']),
      recurrence: json['recurrence'] == null
          ? null
          : ScheduledItemRecurrence.fromJson(json['recurrence']),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
    );
  }
}

class ScheduledItemCard {
  const ScheduledItemCard({
    required this.id,
    required this.petId,
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.notePreview,
    this.startsAt,
    required this.pushEnabled,
    this.remindOffsetMinutes,
    this.recurrence,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
  });

  final String id;
  final String petId;
  final String sourceType;
  final String? sourceId;
  final String title;
  final String? notePreview;
  final DateTime? startsAt;
  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final ScheduledItemRecurrence? recurrence;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory ScheduledItemCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ScheduledItemCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      sourceType: asString(json['source_type']),
      sourceId: asNullableString(json['source_id']),
      title: asString(json['title']),
      notePreview: asNullableString(json['note_preview']),
      startsAt: asDateTime(json['starts_at']),
      pushEnabled: asBool(json['push_enabled']),
      remindOffsetMinutes: json['remind_offset_minutes'] == null
          ? null
          : asInt(json['remind_offset_minutes']),
      recurrence: json['recurrence'] == null
          ? null
          : ScheduledItemRecurrence.fromJson(json['recurrence']),
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
    );
  }
}

class ScheduledItemOccurrence {
  const ScheduledItemOccurrence({
    required this.id,
    required this.scheduledItemId,
    required this.petId,
    this.scheduledFor,
    this.createdAt,
    required this.rule,
  });

  final String id;
  final String scheduledItemId;
  final String petId;
  final DateTime? scheduledFor;
  final DateTime? createdAt;
  final ScheduledItem rule;

  factory ScheduledItemOccurrence.fromJson(Object? data) {
    final json = asJsonMap(data);
    final ruleJson = json['rule'];
    if (ruleJson == null) {
      final itemType = asString(json['item_type']);
      final scheduledItemId = asNullableString(json['scheduled_item_id']) ??
          asString(json['entity_id']);
      final sourceId = asNullableString(json['visit_id']) ??
          asNullableString(json['vaccination_id']) ??
          asNullableString(json['procedure_id']) ??
          asString(json['entity_id']);

      return ScheduledItemOccurrence(
        id: asNullableString(json['scheduled_occurrence_id']) ??
            asString(json['entity_id']),
        scheduledItemId: scheduledItemId,
        petId: asString(json['pet_id']),
        scheduledFor: asDateTime(json['scheduled_for']),
        createdAt: asDateTime(json['created_at']),
        rule: ScheduledItem(
          id: scheduledItemId,
          petId: asString(json['pet_id']),
          sourceType: itemType,
          sourceId: sourceId.isEmpty ? null : sourceId,
          title: asString(json['title']),
          note: asNullableString(json['subtitle']),
          startsAt: asDateTime(json['scheduled_for']),
          pushEnabled: false,
          rowVersion: asInt(json['row_version']),
          createdByUserId: asString(json['created_by_user_id']),
          updatedByUserId: asString(json['updated_by_user_id']),
        ),
      );
    }

    return ScheduledItemOccurrence(
      id: asString(json['id']),
      scheduledItemId: asString(json['scheduled_item_id']),
      petId: asString(json['pet_id']),
      scheduledFor: asDateTime(json['scheduled_for']),
      createdAt: asDateTime(json['created_at']),
      rule: ScheduledItem.fromJson(json['rule']),
    );
  }
}

class ScheduledItemListResponse {
  const ScheduledItemListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<ScheduledItemCard> items;
  final String? nextCursor;

  factory ScheduledItemListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ScheduledItemListResponse(
      items: _decodeList(json['items'], ScheduledItemCard.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class ScheduledItemOccurrenceListResponse {
  const ScheduledItemOccurrenceListResponse({
    required this.items,
    this.nextCursor,
  });

  final List<ScheduledItemOccurrence> items;
  final String? nextCursor;

  factory ScheduledItemOccurrenceListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ScheduledItemOccurrenceListResponse(
      items: _decodeList(json['items'], ScheduledItemOccurrence.fromJson),
      nextCursor: asNullableString(json['next_cursor']),
    );
  }
}

class ScheduledDayResponse {
  const ScheduledDayResponse({
    required this.date,
    required this.items,
  });

  final String date;
  final List<ScheduledItemOccurrence> items;

  factory ScheduledDayResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return ScheduledDayResponse(
      date: asString(json['date']),
      items: _decodeList(json['items'], ScheduledItemOccurrence.fromJson),
    );
  }
}

class CalendarDateMarker {
  const CalendarDateMarker({
    required this.date,
    required this.plannedCount,
    required this.completedCount,
    required this.totalCount,
  });

  final String date;
  final int plannedCount;
  final int completedCount;
  final int totalCount;

  bool get hasEvents => totalCount > 0;

  factory CalendarDateMarker.fromJson(Object? data) {
    final json = asJsonMap(data);
    return CalendarDateMarker(
      date: asString(json['date']),
      plannedCount: asInt(json['planned_count']),
      completedCount: asInt(json['completed_count']),
      totalCount: asInt(json['total_count']),
    );
  }
}

class CalendarRangeResponse {
  const CalendarRangeResponse({
    required this.dateFrom,
    required this.dateTo,
    required this.items,
  });

  final String dateFrom;
  final String dateTo;
  final List<CalendarDateMarker> items;

  Map<String, CalendarDateMarker> get markersByDate =>
      <String, CalendarDateMarker>{
        for (final item in items) item.date: item,
      };

  factory CalendarRangeResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return CalendarRangeResponse(
      dateFrom: asString(json['date_from']),
      dateTo: asString(json['date_to']),
      items: _decodeList(json['items'], CalendarDateMarker.fromJson),
    );
  }
}

class UpsertScheduledItemPayload {
  const UpsertScheduledItemPayload({
    required this.sourceType,
    this.sourceId,
    required this.title,
    this.note,
    required this.startsAt,
    required this.pushEnabled,
    this.remindOffsetMinutes,
    this.recurrence,
    this.rowVersion,
  });

  final String sourceType;
  final String? sourceId;
  final String title;
  final String? note;
  final DateTime startsAt;
  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final ScheduledItemRecurrence? recurrence;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'source_type': sourceType,
        'source_id': sourceId,
        'title': title,
        'note': note,
        'starts_at': _toIso8601String(startsAt),
        'push_enabled': pushEnabled,
        'remind_offset_minutes': remindOffsetMinutes,
        'recurrence': recurrence?.toJson(),
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class UpdateScheduledItemReminderSettingsPayload {
  const UpdateScheduledItemReminderSettingsPayload({
    required this.pushEnabled,
    this.remindOffsetMinutes,
    required this.rowVersion,
  });

  final bool pushEnabled;
  final int? remindOffsetMinutes;
  final int rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'push_enabled': pushEnabled,
        'remind_offset_minutes': remindOffsetMinutes,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class DeviceTokenPayload {
  const DeviceTokenPayload({
    required this.deviceId,
    required this.platform,
    required this.pushToken,
  });

  final String deviceId;
  final String platform;
  final String pushToken;

  JsonMap toJson() => <String, dynamic>{
        'device_id': deviceId,
        'platform': platform,
        'push_token': pushToken,
      };
}

class DeviceToken {
  const DeviceToken({
    required this.id,
    required this.userId,
    required this.deviceId,
    required this.platform,
    required this.pushToken,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String deviceId;
  final String platform;
  final String pushToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory DeviceToken.fromJson(Object? data) {
    final json = asJsonMap(data);
    final item = json['item'];
    if (item != null) {
      return DeviceToken.fromJson(item);
    }

    return DeviceToken(
      id: asString(json['id']),
      userId: asString(json['user_id']),
      deviceId: asString(json['device_id']),
      platform: asString(json['platform']),
      pushToken: asString(json['push_token']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

class PetPushSettings {
  const PetPushSettings({
    required this.petId,
    required this.scheduledItemsEnabled,
    this.createdAt,
    this.updatedAt,
  });

  final String petId;
  final bool scheduledItemsEnabled;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory PetPushSettings.fromJson(Object? data) {
    final json = asJsonMap(data);
    final item = json['item'];
    if (item != null) {
      return PetPushSettings.fromJson(item);
    }

    return PetPushSettings(
      petId: asString(json['pet_id']),
      scheduledItemsEnabled: asBool(json['scheduled_items_enabled']),
      createdAt: asDateTime(json['created_at']),
      updatedAt: asDateTime(json['updated_at']),
    );
  }
}

class UpdatePetPushSettingsPayload {
  const UpdatePetPushSettingsPayload({
    required this.scheduledItemsEnabled,
  });

  final bool scheduledItemsEnabled;

  JsonMap toJson() => <String, dynamic>{
        'scheduled_items_enabled': scheduledItemsEnabled,
      };
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
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
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
      title: asNullableString(json['title']),
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
      title: asNullableString(json['title']),
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
    this.title,
    this.scheduledAt,
    this.completedAt,
    this.reasonText,
    this.resultText,
    this.clinicName,
    this.vetName,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.reminder,
    this.rowVersion,
  });

  final String status;
  final String visitType;
  final String? title;
  final DateTime? scheduledAt;
  final DateTime? completedAt;
  final String? reasonText;
  final String? resultText;
  final String? clinicName;
  final String? vetName;
  final List<AttachmentPayload>? attachments;
  final List<String> attachmentFileIds;
  final HealthEntityReminderPayload? reminder;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'status': status,
        'visit_type': visitType,
        'title': title,
        'scheduled_at': _toIso8601String(scheduledAt),
        'completed_at': _toIso8601String(completedAt),
        'reason_text': reasonText,
        'result_text': resultText,
        'clinic_name': clinicName,
        'vet_name': vetName,
        'attachments': _attachmentPayloadsForJson(
          attachments,
          attachmentFileIds,
        )?.map((item) => item.toJson()).toList(growable: false),
        'reminder': reminder?.toJson(),
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class HealthEntityReminderPayload {
  const HealthEntityReminderPayload({
    required this.pushEnabled,
    this.remindOffsetMinutes,
  });

  final bool pushEnabled;
  final int? remindOffsetMinutes;

  JsonMap toJson() => <String, dynamic>{
        'push_enabled': pushEnabled,
        'remind_offset_minutes': remindOffsetMinutes,
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
      targets: _decodeList(json['targets'], HealthDictionaryItem.fromJson),
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
      targets: _decodeList(json['targets'], HealthDictionaryItem.fromJson),
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
    this.targets,
    this.scheduledAt,
    this.administeredAt,
    this.nextDueAt,
    this.vetVisitId,
    this.clinicName,
    this.vetName,
    this.notes,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.reminder,
    this.rowVersion,
  });

  final String status;
  final String vaccineName;
  final String? catalogMedicationId;
  final List<HealthDictionaryRefPayload>? targets;
  final DateTime? scheduledAt;
  final DateTime? administeredAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? clinicName;
  final String? vetName;
  final String? notes;
  final List<AttachmentPayload>? attachments;
  final List<String> attachmentFileIds;
  final HealthEntityReminderPayload? reminder;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'status': status,
        'vaccine_name': vaccineName,
        'catalog_medication_id': catalogMedicationId,
        'targets':
            targets?.map((item) => item.toJson()).toList(growable: false),
        'scheduled_at': _toIso8601String(scheduledAt),
        'administered_at': _toIso8601String(administeredAt),
        'next_due_at': _toIso8601String(nextDueAt),
        'vet_visit_id': vetVisitId,
        'clinic_name': clinicName,
        'vet_name': vetName,
        'notes': notes,
        'attachments': _attachmentPayloadsForJson(
          attachments,
          attachmentFileIds,
        )?.map((item) => item.toJson()).toList(growable: false),
        'reminder': reminder?.toJson(),
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
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
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
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
      procedureTypeItem: json['procedure_type_item'] == null
          ? null
          : HealthDictionaryItem.fromJson(json['procedure_type_item']),
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
      procedureTypeItem: json['procedure_type_item'] == null
          ? null
          : HealthDictionaryItem.fromJson(json['procedure_type_item']),
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
    this.procedureTypeId,
    this.procedureTypeName,
    required this.title,
    this.description,
    this.catalogMedicationId,
    this.productName,
    this.scheduledAt,
    this.performedAt,
    this.nextDueAt,
    this.vetVisitId,
    this.notes,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.reminder,
    this.rowVersion,
  });

  final String status;
  final String? procedureTypeId;
  final String? procedureTypeName;
  final String title;
  final String? description;
  final String? catalogMedicationId;
  final String? productName;
  final DateTime? scheduledAt;
  final DateTime? performedAt;
  final DateTime? nextDueAt;
  final String? vetVisitId;
  final String? notes;
  final List<AttachmentPayload>? attachments;
  final List<String> attachmentFileIds;
  final HealthEntityReminderPayload? reminder;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'status': status,
        'procedure_type_id': procedureTypeId,
        'procedure_type_name': procedureTypeName,
        'title': title,
        'description': description,
        'catalog_medication_id': catalogMedicationId,
        'product_name': productName,
        'scheduled_at': _toIso8601String(scheduledAt),
        'performed_at': _toIso8601String(performedAt),
        'next_due_at': _toIso8601String(nextDueAt),
        'vet_visit_id': vetVisitId,
        'notes': notes,
        'attachments': _attachmentPayloadsForJson(
          attachments,
          attachmentFileIds,
        )?.map((item) => item.toJson()).toList(growable: false),
        'reminder': reminder?.toJson(),
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
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
    this.createdAt,
    required this.createdByUserId,
    this.updatedAt,
    required this.updatedByUserId,
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
  final DateTime? createdAt;
  final String createdByUserId;
  final DateTime? updatedAt;
  final String updatedByUserId;

  factory MedicalRecordCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MedicalRecordCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      recordTypeItem: json['record_type_item'] == null
          ? null
          : HealthDictionaryItem.fromJson(json['record_type_item']),
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
    this.recordTypeItem,
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
  final HealthDictionaryItem? recordTypeItem;
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
      recordTypeItem: json['record_type_item'] == null
          ? null
          : HealthDictionaryItem.fromJson(json['record_type_item']),
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
    this.recordTypeId,
    this.recordTypeName,
    required this.status,
    required this.title,
    this.description,
    this.startedAt,
    this.resolvedAt,
    this.attachments,
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String? recordTypeId;
  final String? recordTypeName;
  final String status;
  final String title;
  final String? description;
  final DateTime? startedAt;
  final DateTime? resolvedAt;
  final List<AttachmentPayload>? attachments;
  final List<String> attachmentFileIds;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'record_type_id': recordTypeId,
        'record_type_name': recordTypeName,
        'status': status,
        'title': title,
        'description': description,
        'started_at': _toIso8601String(startedAt),
        'resolved_at': _toIso8601String(resolvedAt),
        'attachments': _attachmentPayloadsForJson(
          attachments,
          attachmentFileIds,
        )?.map((item) => item.toJson()).toList(growable: false),
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

List<T> _decodeList<T>(Object? data, T Function(Object? item) decoder) {
  if (data is! List) {
    return <T>[];
  }
  return data.map(decoder).toList(growable: false);
}

List<AttachmentPayload>? _attachmentPayloadsForJson(
  List<AttachmentPayload>? attachments,
  List<String> attachmentFileIds,
) {
  if (attachments != null) {
    return attachments;
  }
  if (attachmentFileIds.isEmpty) {
    return null;
  }
  return attachmentFileIds
      .map((fileId) => AttachmentPayload(fileId: fileId))
      .toList(growable: false);
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
