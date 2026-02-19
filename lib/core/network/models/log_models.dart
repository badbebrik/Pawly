import 'json_map.dart';
import 'json_parsers.dart';

class LogMetricValue {
  const LogMetricValue({
    required this.metricId,
    required this.metricName,
    required this.inputKind,
    this.unitCode,
    required this.valueNum,
  });

  final String metricId;
  final String metricName;
  final String inputKind;
  final String? unitCode;
  final double valueNum;

  factory LogMetricValue.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogMetricValue(
      metricId: asString(json['metric_id']),
      metricName: asString(json['metric_name']),
      inputKind: asString(json['input_kind']),
      unitCode: asNullableString(json['unit_code']),
      valueNum: (json['value_num'] as num?)?.toDouble() ?? 0,
    );
  }

  JsonMap toJson() => <String, dynamic>{
        'metric_id': metricId,
        'value_num': valueNum,
      };
}

class LogAttachment {
  const LogAttachment({
    required this.id,
    required this.fileId,
    required this.fileName,
    required this.fileType,
    this.downloadUrl,
    this.previewUrl,
    this.addedAt,
    this.addedByUserId,
  });

  final String id;
  final String fileId;
  final String fileName;
  final String fileType;
  final String? downloadUrl;
  final String? previewUrl;
  final DateTime? addedAt;
  final String? addedByUserId;

  factory LogAttachment.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogAttachment(
      id: asString(json['id']),
      fileId: asString(json['file_id']),
      fileName: asString(json['file_name']),
      fileType: asString(json['file_type']),
      downloadUrl: asNullableString(json['download_url']),
      previewUrl: asNullableString(json['preview_url']),
      addedAt: asDateTime(json['added_at']),
      addedByUserId: asNullableString(json['added_by_user_id']),
    );
  }
}

class LogCard {
  const LogCard({
    required this.id,
    required this.petId,
    required this.occurredAt,
    this.logTypeId,
    this.logTypeName,
    this.logTypeScope,
    required this.descriptionPreview,
    required this.source,
    this.sourceEntityType,
    this.sourceEntityId,
    this.sourceLabel,
    required this.metricValuesPreview,
    required this.attachmentsCount,
    required this.hasAttachments,
    required this.createdByUserId,
    required this.createdByDisplayName,
  });

  final String id;
  final String petId;
  final DateTime? occurredAt;
  final String? logTypeId;
  final String? logTypeName;
  final String? logTypeScope;
  final String descriptionPreview;
  final String source;
  final String? sourceEntityType;
  final String? sourceEntityId;
  final String? sourceLabel;
  final List<LogMetricValue> metricValuesPreview;
  final int attachmentsCount;
  final bool hasAttachments;
  final String createdByUserId;
  final String createdByDisplayName;

  factory LogCard.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawMetricValues = json['metric_values_preview'];
    return LogCard(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      occurredAt: asDateTime(json['occurred_at']),
      logTypeId: asNullableString(json['log_type_id']),
      logTypeName: asNullableString(json['log_type_name']),
      logTypeScope: asNullableString(json['log_type_scope']),
      descriptionPreview: asString(json['description_preview']),
      source: asString(json['source']),
      sourceEntityType: asNullableString(json['source_entity_type']),
      sourceEntityId: asNullableString(json['source_entity_id']),
      sourceLabel: asNullableString(json['source_label']),
      metricValuesPreview: rawMetricValues is List
          ? rawMetricValues.map(LogMetricValue.fromJson).toList(growable: false)
          : const <LogMetricValue>[],
      attachmentsCount: asInt(json['attachments_count']),
      hasAttachments: asBool(json['has_attachments']),
      createdByUserId: asString(json['created_by_user_id']),
      createdByDisplayName: asString(json['created_by_display_name']),
    );
  }
}

class LogEntry {
  const LogEntry({
    required this.id,
    required this.petId,
    this.occurredAt,
    this.logTypeId,
    this.logTypeName,
    this.logTypeScope,
    required this.description,
    required this.source,
    this.sourceEntityType,
    this.sourceEntityId,
    this.sourceLabel,
    required this.metricValues,
    required this.attachments,
    required this.rowVersion,
    this.createdAt,
    required this.createdByUserId,
    required this.createdByDisplayName,
    this.updatedAt,
    required this.updatedByUserId,
    required this.updatedByDisplayName,
    required this.canEdit,
    required this.canDelete,
  });

  final String id;
  final String petId;
  final DateTime? occurredAt;
  final String? logTypeId;
  final String? logTypeName;
  final String? logTypeScope;
  final String description;
  final String source;
  final String? sourceEntityType;
  final String? sourceEntityId;
  final String? sourceLabel;
  final List<LogMetricValue> metricValues;
  final List<LogAttachment> attachments;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final String createdByDisplayName;
  final DateTime? updatedAt;
  final String updatedByUserId;
  final String updatedByDisplayName;
  final bool canEdit;
  final bool canDelete;

  factory LogEntry.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawMetricValues = json['metric_values'];
    final rawAttachments = json['attachments'];
    return LogEntry(
      id: asString(json['id']),
      petId: asString(json['pet_id']),
      occurredAt: asDateTime(json['occurred_at']),
      logTypeId: asNullableString(json['log_type_id']),
      logTypeName: asNullableString(json['log_type_name']),
      logTypeScope: asNullableString(json['log_type_scope']),
      description: asString(json['description']),
      source: asString(json['source']),
      sourceEntityType: asNullableString(json['source_entity_type']),
      sourceEntityId: asNullableString(json['source_entity_id']),
      sourceLabel: asNullableString(json['source_label']),
      metricValues: rawMetricValues is List
          ? rawMetricValues.map(LogMetricValue.fromJson).toList(growable: false)
          : const <LogMetricValue>[],
      attachments: rawAttachments is List
          ? rawAttachments.map(LogAttachment.fromJson).toList(growable: false)
          : const <LogAttachment>[],
      rowVersion: asInt(json['row_version']),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asString(json['created_by_user_id']),
      createdByDisplayName: asString(json['created_by_display_name']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asString(json['updated_by_user_id']),
      updatedByDisplayName: asString(json['updated_by_display_name']),
      canEdit: asBool(json['can_edit']),
      canDelete: asBool(json['can_delete']),
    );
  }
}

class LogTypeMetricRequirement {
  const LogTypeMetricRequirement({
    required this.metricId,
    required this.metricName,
    required this.metricScope,
    required this.inputKind,
    this.unitCode,
    this.minValue,
    this.maxValue,
    required this.isRequired,
  });

  final String metricId;
  final String metricName;
  final String metricScope;
  final String inputKind;
  final String? unitCode;
  final double? minValue;
  final double? maxValue;
  final bool isRequired;

  factory LogTypeMetricRequirement.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogTypeMetricRequirement(
      metricId: asString(json['metric_id']),
      metricName: asString(json['metric_name']),
      metricScope: asString(json['metric_scope']),
      inputKind: asString(json['input_kind']),
      unitCode: asNullableString(json['unit_code']),
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      isRequired: asBool(json['is_required']),
    );
  }
}

class LogType {
  const LogType({
    required this.id,
    required this.scope,
    this.petId,
    this.code,
    required this.name,
    required this.metricRequirements,
    this.createdAt,
    this.createdByUserId,
    this.updatedAt,
    this.updatedByUserId,
    required this.isArchived,
  });

  final String id;
  final String scope;
  final String? petId;
  final String? code;
  final String name;
  final List<LogTypeMetricRequirement> metricRequirements;
  final DateTime? createdAt;
  final String? createdByUserId;
  final DateTime? updatedAt;
  final String? updatedByUserId;
  final bool isArchived;

  factory LogType.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawRequirements = json['metric_requirements'];
    return LogType(
      id: asString(json['id']),
      scope: asString(json['scope']),
      petId: asNullableString(json['pet_id']),
      code: asNullableString(json['code']),
      name: asString(json['name']),
      metricRequirements: rawRequirements is List
          ? rawRequirements
              .map(LogTypeMetricRequirement.fromJson)
              .toList(growable: false)
          : const <LogTypeMetricRequirement>[],
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asNullableString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asNullableString(json['updated_by_user_id']),
      isArchived: asBool(json['is_archived']),
    );
  }
}

class MetricUsage {
  const MetricUsage({
    required this.logTypesCount,
    required this.logsCount,
  });

  final int logTypesCount;
  final int logsCount;

  factory MetricUsage.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MetricUsage(
      logTypesCount: asInt(json['log_types_count']),
      logsCount: asInt(json['logs_count']),
    );
  }
}
