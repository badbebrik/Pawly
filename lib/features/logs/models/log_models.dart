import 'log_constants.dart';

class LogMetricItem {
  const LogMetricItem({
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
}

class LogAttachmentItem {
  const LogAttachmentItem({
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
}

class LogTypeMetricRequirementItem {
  const LogTypeMetricRequirementItem({
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
}

class LogTypeItem {
  const LogTypeItem({
    required this.id,
    required this.scope,
    this.petId,
    this.code,
    required this.name,
    required this.metricRequirements,
    this.rowVersion,
    required this.isArchived,
  });

  final String id;
  final String scope;
  final String? petId;
  final String? code;
  final String name;
  final List<LogTypeMetricRequirementItem> metricRequirements;
  final int? rowVersion;
  final bool isArchived;
}

class LogSourceFacetItem {
  const LogSourceFacetItem({required this.value, required this.count});

  final String value;
  final int count;
}

class LogTypeFacetItem {
  const LogTypeFacetItem({
    required this.id,
    required this.name,
    required this.scope,
    required this.count,
  });

  final String id;
  final String name;
  final String scope;
  final int count;
}

class LogsFacets {
  const LogsFacets({
    required this.sources,
    required this.types,
    required this.hasAttachmentsCount,
    required this.hasMetricsCount,
  });

  final List<LogSourceFacetItem> sources;
  final List<LogTypeFacetItem> types;
  final int hasAttachmentsCount;
  final int hasMetricsCount;
}

class LogsBootstrap {
  const LogsBootstrap({
    required this.canRead,
    required this.canWrite,
    required this.recentLogTypes,
    required this.systemLogTypes,
    required this.customLogTypes,
    required this.systemMetrics,
    required this.customMetrics,
  });

  final bool canRead;
  final bool canWrite;
  final List<LogTypeItem> recentLogTypes;
  final List<LogTypeItem> systemLogTypes;
  final List<LogTypeItem> customLogTypes;
  final List<LogMetricCatalogItem> systemMetrics;
  final List<LogMetricCatalogItem> customMetrics;
}

class LogMetricCatalogItem {
  const LogMetricCatalogItem({
    required this.id,
    required this.scope,
    this.petId,
    this.code,
    required this.name,
    required this.inputKind,
    this.unitCode,
    this.minValue,
    this.maxValue,
    this.rowVersion,
    required this.isArchived,
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
  final int? rowVersion;
  final bool isArchived;
}

class LogListItem {
  const LogListItem({
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
  final List<LogMetricItem> metricValuesPreview;
  final int attachmentsCount;
  final bool hasAttachments;
  final String createdByUserId;
  final String createdByDisplayName;
}

class LogDetails {
  const LogDetails({
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
  final List<LogMetricItem> metricValues;
  final List<LogAttachmentItem> attachments;
  final int rowVersion;
  final DateTime? createdAt;
  final String createdByUserId;
  final String createdByDisplayName;
  final DateTime? updatedAt;
  final String updatedByUserId;
  final String updatedByDisplayName;
  final bool canEdit;
  final bool canDelete;
}

class LogsQuery {
  const LogsQuery({
    this.cursor,
    this.limit = 30,
    this.searchQuery,
    this.dateFrom,
    this.dateTo,
    this.typeIds = const <String>[],
    this.source,
    this.hasAttachments,
    this.hasMetrics,
    this.sort = LogSort.occurredAtDesc,
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

class LogsPageResult {
  const LogsPageResult({
    required this.items,
    this.nextCursor,
    this.facets,
  });

  final List<LogListItem> items;
  final String? nextCursor;
  final LogsFacets? facets;
}
