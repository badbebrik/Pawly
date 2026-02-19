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

class Metric {
  const Metric({
    required this.id,
    required this.scope,
    this.petId,
    this.code,
    required this.name,
    required this.inputKind,
    this.unitCode,
    this.minValue,
    this.maxValue,
    this.createdAt,
    this.createdByUserId,
    this.updatedAt,
    this.updatedByUserId,
    required this.isArchived,
    this.usage,
  });

  final String id;
  final String scope;
  final String? petId;
  final String? code;
  final String name;
  final String inputKind;
  final String? unitCode;
  final double? minValue;
  final double? maxValue;
  final DateTime? createdAt;
  final String? createdByUserId;
  final DateTime? updatedAt;
  final String? updatedByUserId;
  final bool isArchived;
  final MetricUsage? usage;

  factory Metric.fromJson(Object? data) {
    final json = asJsonMap(data);
    return Metric(
      id: asString(json['id']),
      scope: asString(json['scope']),
      petId: asNullableString(json['pet_id']),
      code: asNullableString(json['code']),
      name: asString(json['name']),
      inputKind: asString(json['input_kind']),
      unitCode: asNullableString(json['unit_code']),
      minValue: (json['min_value'] as num?)?.toDouble(),
      maxValue: (json['max_value'] as num?)?.toDouble(),
      createdAt: asDateTime(json['created_at']),
      createdByUserId: asNullableString(json['created_by_user_id']),
      updatedAt: asDateTime(json['updated_at']),
      updatedByUserId: asNullableString(json['updated_by_user_id']),
      isArchived: asBool(json['is_archived']),
      usage: json['usage'] == null ? null : MetricUsage.fromJson(json['usage']),
    );
  }
}

class LogSourceFacet {
  const LogSourceFacet({
    required this.value,
    required this.count,
  });

  final String value;
  final int count;

  factory LogSourceFacet.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogSourceFacet(
      value: asString(json['value']),
      count: asInt(json['count']),
    );
  }
}

class LogTypeFacet {
  const LogTypeFacet({
    required this.id,
    required this.name,
    required this.scope,
    required this.count,
  });

  final String id;
  final String name;
  final String scope;
  final int count;

  factory LogTypeFacet.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogTypeFacet(
      id: asString(json['id']),
      name: asString(json['name']),
      scope: asString(json['scope']),
      count: asInt(json['count']),
    );
  }
}

class LogListFacets {
  const LogListFacets({
    required this.sources,
    required this.types,
    required this.hasAttachmentsCount,
    required this.hasMetricsCount,
  });

  final List<LogSourceFacet> sources;
  final List<LogTypeFacet> types;
  final int hasAttachmentsCount;
  final int hasMetricsCount;

  factory LogListFacets.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawSources = json['sources'];
    final rawTypes = json['types'];
    return LogListFacets(
      sources: rawSources is List
          ? rawSources.map(LogSourceFacet.fromJson).toList(growable: false)
          : const <LogSourceFacet>[],
      types: rawTypes is List
          ? rawTypes.map(LogTypeFacet.fromJson).toList(growable: false)
          : const <LogTypeFacet>[],
      hasAttachmentsCount: asInt(json['has_attachments_count']),
      hasMetricsCount: asInt(json['has_metrics_count']),
    );
  }
}

class LogListResponse {
  const LogListResponse({
    required this.items,
    this.nextCursor,
    this.facets,
  });

  final List<LogCard> items;
  final String? nextCursor;
  final LogListFacets? facets;

  factory LogListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawItems = json['items'];
    return LogListResponse(
      items: rawItems is List
          ? rawItems.map(LogCard.fromJson).toList(growable: false)
          : const <LogCard>[],
      nextCursor: asNullableString(json['next_cursor']),
      facets: json['facets'] == null ? null : LogListFacets.fromJson(json['facets']),
    );
  }
}

class LogPermissionSet {
  const LogPermissionSet({
    required this.logRead,
    required this.logWrite,
  });

  final bool logRead;
  final bool logWrite;

  factory LogPermissionSet.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogPermissionSet(
      logRead: asBool(json['log_read']),
      logWrite: asBool(json['log_write']),
    );
  }
}

class LogComposerBootstrapResponse {
  const LogComposerBootstrapResponse({
    required this.permissions,
    required this.recentLogTypes,
    required this.systemLogTypes,
    required this.customLogTypes,
    required this.systemMetrics,
    required this.customMetrics,
  });

  final LogPermissionSet permissions;
  final List<LogType> recentLogTypes;
  final List<LogType> systemLogTypes;
  final List<LogType> customLogTypes;
  final List<Metric> systemMetrics;
  final List<Metric> customMetrics;

  factory LogComposerBootstrapResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogComposerBootstrapResponse(
      permissions: LogPermissionSet.fromJson(json['permissions']),
      recentLogTypes: _decodeLogTypeList(json['recent_log_types']),
      systemLogTypes: _decodeLogTypeList(json['system_log_types']),
      customLogTypes: _decodeLogTypeList(json['custom_log_types']),
      systemMetrics: _decodeMetricList(json['system_metrics']),
      customMetrics: _decodeMetricList(json['custom_metrics']),
    );
  }
}

class LogTypeListResponse {
  const LogTypeListResponse({
    required this.items,
  });

  final List<LogType> items;

  factory LogTypeListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return LogTypeListResponse(items: _decodeLogTypeList(json['items']));
  }
}

class MetricListResponse {
  const MetricListResponse({
    required this.items,
  });

  final List<Metric> items;

  factory MetricListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MetricListResponse(items: _decodeMetricList(json['items']));
  }
}

class LogTypeMetricRequirementPayload {
  const LogTypeMetricRequirementPayload({
    required this.metricId,
    required this.isRequired,
  });

  final String metricId;
  final bool isRequired;

  JsonMap toJson() => <String, dynamic>{
        'metric_id': metricId,
        'is_required': isRequired,
      };
}

class UpsertLogPayload {
  const UpsertLogPayload({
    required this.occurredAt,
    this.logTypeId,
    this.description,
    this.metricValues = const <LogMetricValue>[],
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final DateTime occurredAt;
  final String? logTypeId;
  final String? description;
  final List<LogMetricValue> metricValues;
  final List<String> attachmentFileIds;
  final int? rowVersion;

  JsonMap toJson() => <String, dynamic>{
        'occurred_at': occurredAt.toUtc().toIso8601String(),
        'log_type_id': logTypeId,
        'description': description,
        'metric_values': metricValues.map((item) => item.toJson()).toList(growable: false),
        'attachment_file_ids': attachmentFileIds,
        'row_version': rowVersion,
      }..removeWhere((_, dynamic value) => value == null);
}

class DeleteLogPayload {
  const DeleteLogPayload({required this.rowVersion});

  final int rowVersion;

  JsonMap toJson() => <String, dynamic>{'row_version': rowVersion};
}

class CreateLogTypePayload {
  const CreateLogTypePayload({
    required this.name,
    required this.metricRequirements,
  });

  final String name;
  final List<LogTypeMetricRequirementPayload> metricRequirements;

  JsonMap toJson() => <String, dynamic>{
        'name': name,
        'metric_requirements':
            metricRequirements.map((item) => item.toJson()).toList(growable: false),
      };
}

class UpdateLogTypePayload extends CreateLogTypePayload {
  const UpdateLogTypePayload({
    required super.name,
    required super.metricRequirements,
    required this.rowVersion,
  });

  final int rowVersion;

  @override
  JsonMap toJson() => <String, dynamic>{
        ...super.toJson(),
        'row_version': rowVersion,
      };
}

class CreateMetricPayload {
  const CreateMetricPayload({
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

  JsonMap toJson() => <String, dynamic>{
        'name': name,
        'input_kind': inputKind,
        'unit_code': unitCode,
        'min_value': minValue,
        'max_value': maxValue,
      }..removeWhere((_, dynamic value) => value == null);
}

class UpdateMetricPayload extends CreateMetricPayload {
  const UpdateMetricPayload({
    required super.name,
    required super.inputKind,
    super.unitCode,
    super.minValue,
    super.maxValue,
    required this.rowVersion,
  });

  final int rowVersion;

  @override
  JsonMap toJson() => <String, dynamic>{
        ...super.toJson(),
        'row_version': rowVersion,
      };
}

class DeleteEntityPayload {
  const DeleteEntityPayload({required this.rowVersion});

  final int rowVersion;

  JsonMap toJson() => <String, dynamic>{'row_version': rowVersion};
}

class AnalyticsMetricLogTypeRef {
  const AnalyticsMetricLogTypeRef({
    required this.logTypeId,
    required this.logTypeName,
  });

  final String logTypeId;
  final String logTypeName;

  factory AnalyticsMetricLogTypeRef.fromJson(Object? data) {
    final json = asJsonMap(data);
    return AnalyticsMetricLogTypeRef(
      logTypeId: asString(json['log_type_id']),
      logTypeName: asString(json['log_type_name']),
    );
  }
}

class AnalyticsMetricSummary {
  const AnalyticsMetricSummary({
    required this.metricId,
    required this.metricName,
    required this.metricScope,
    required this.inputKind,
    this.unitCode,
    required this.pointsCount,
    this.firstOccurredAt,
    this.lastOccurredAt,
    this.lastValueNum,
    required this.usedInLogTypes,
  });

  final String metricId;
  final String metricName;
  final String metricScope;
  final String inputKind;
  final String? unitCode;
  final int pointsCount;
  final DateTime? firstOccurredAt;
  final DateTime? lastOccurredAt;
  final double? lastValueNum;
  final List<AnalyticsMetricLogTypeRef> usedInLogTypes;

  factory AnalyticsMetricSummary.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawTypes = json['used_in_log_types'];
    return AnalyticsMetricSummary(
      metricId: asString(json['metric_id']),
      metricName: asString(json['metric_name']),
      metricScope: asString(json['metric_scope']),
      inputKind: asString(json['input_kind']),
      unitCode: asNullableString(json['unit_code']),
      pointsCount: asInt(json['points_count']),
      firstOccurredAt: asDateTime(json['first_occurred_at']),
      lastOccurredAt: asDateTime(json['last_occurred_at']),
      lastValueNum: (json['last_value_num'] as num?)?.toDouble(),
      usedInLogTypes: rawTypes is List
          ? rawTypes
              .map(AnalyticsMetricLogTypeRef.fromJson)
              .toList(growable: false)
          : const <AnalyticsMetricLogTypeRef>[],
    );
  }
}

class AnalyticsMetricSummaryListResponse {
  const AnalyticsMetricSummaryListResponse({
    required this.items,
  });

  final List<AnalyticsMetricSummary> items;

  factory AnalyticsMetricSummaryListResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawItems = json['items'];
    return AnalyticsMetricSummaryListResponse(
      items: rawItems is List
          ? rawItems
              .map(AnalyticsMetricSummary.fromJson)
              .toList(growable: false)
          : const <AnalyticsMetricSummary>[],
    );
  }
}

class MetricSeriesPoint {
  const MetricSeriesPoint({
    this.occurredAt,
    required this.valueNum,
    required this.logId,
    this.logTypeId,
    this.logTypeName,
    required this.source,
  });

  final DateTime? occurredAt;
  final double valueNum;
  final String logId;
  final String? logTypeId;
  final String? logTypeName;
  final String source;

  factory MetricSeriesPoint.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MetricSeriesPoint(
      occurredAt: asDateTime(json['occurred_at']),
      valueNum: (json['value_num'] as num?)?.toDouble() ?? 0,
      logId: asString(json['log_id']),
      logTypeId: asNullableString(json['log_type_id']),
      logTypeName: asNullableString(json['log_type_name']),
      source: asString(json['source']),
    );
  }
}

class MetricSeriesSummary {
  const MetricSeriesSummary({
    required this.pointsCount,
    this.minValueNum,
    this.maxValueNum,
    this.lastValueNum,
    this.avgValueNum,
    this.deltaFromFirstNum,
  });

  final int pointsCount;
  final double? minValueNum;
  final double? maxValueNum;
  final double? lastValueNum;
  final double? avgValueNum;
  final double? deltaFromFirstNum;

  factory MetricSeriesSummary.fromJson(Object? data) {
    final json = asJsonMap(data);
    return MetricSeriesSummary(
      pointsCount: asInt(json['points_count']),
      minValueNum: (json['min_value_num'] as num?)?.toDouble(),
      maxValueNum: (json['max_value_num'] as num?)?.toDouble(),
      lastValueNum: (json['last_value_num'] as num?)?.toDouble(),
      avgValueNum: (json['avg_value_num'] as num?)?.toDouble(),
      deltaFromFirstNum: (json['delta_from_first_num'] as num?)?.toDouble(),
    );
  }
}

class MetricSeriesResponse {
  const MetricSeriesResponse({
    required this.metric,
    this.summary,
    required this.points,
  });

  final Metric metric;
  final MetricSeriesSummary? summary;
  final List<MetricSeriesPoint> points;

  factory MetricSeriesResponse.fromJson(Object? data) {
    final json = asJsonMap(data);
    final rawPoints = json['points'];
    return MetricSeriesResponse(
      metric: Metric.fromJson(json['metric']),
      summary: json['summary'] == null
          ? null
          : MetricSeriesSummary.fromJson(json['summary']),
      points: rawPoints is List
          ? rawPoints.map(MetricSeriesPoint.fromJson).toList(growable: false)
          : const <MetricSeriesPoint>[],
    );
  }
}

List<LogType> _decodeLogTypeList(Object? data) {
  if (data is! List) {
    return const <LogType>[];
  }
  return data.map(LogType.fromJson).toList(growable: false);
}

List<Metric> _decodeMetricList(Object? data) {
  if (data is! List) {
    return const <Metric>[];
  }
  return data.map(Metric.fromJson).toList(growable: false);
}
