import '../../../../core/network/models/log_models.dart' as api;
import '../../models/analytics_models.dart';
import '../../models/log_models.dart';

LogMetricItem mapLogMetricValue(api.LogMetricValue value) {
  return LogMetricItem(
    metricId: value.metricId,
    metricName: value.metricName,
    inputKind: value.inputKind,
    unitCode: value.unitCode,
    valueNum: value.valueNum,
  );
}

LogAttachmentItem mapLogAttachment(api.LogAttachment attachment) {
  return LogAttachmentItem(
    id: attachment.id,
    fileId: attachment.fileId,
    fileName: attachment.fileName,
    fileType: attachment.fileType,
    downloadUrl: attachment.downloadUrl,
    previewUrl: attachment.previewUrl,
    addedAt: attachment.addedAt,
    addedByUserId: attachment.addedByUserId,
  );
}

LogTypeMetricRequirementItem mapLogTypeMetricRequirement(
  api.LogTypeMetricRequirement requirement,
) {
  return LogTypeMetricRequirementItem(
    metricId: requirement.metricId,
    metricName: requirement.metricName,
    metricScope: requirement.metricScope,
    inputKind: requirement.inputKind,
    unitCode: requirement.unitCode,
    minValue: requirement.minValue,
    maxValue: requirement.maxValue,
    isRequired: requirement.isRequired,
  );
}

LogTypeItem mapLogType(api.LogType type) {
  return LogTypeItem(
    id: type.id,
    scope: type.scope,
    petId: type.petId,
    code: type.code,
    name: type.name,
    metricRequirements: type.metricRequirements
        .map(mapLogTypeMetricRequirement)
        .toList(growable: false),
    rowVersion: type.rowVersion,
    isArchived: type.isArchived,
  );
}

LogMetricCatalogItem mapMetric(api.Metric metric) {
  return LogMetricCatalogItem(
    id: metric.id,
    scope: metric.scope,
    petId: metric.petId,
    code: metric.code,
    name: metric.name,
    inputKind: metric.inputKind,
    unitCode: metric.unitCode,
    minValue: metric.minValue,
    maxValue: metric.maxValue,
    rowVersion: metric.rowVersion,
    isArchived: metric.isArchived,
  );
}

LogListItem mapLogCard(api.LogCard log) {
  return LogListItem(
    id: log.id,
    petId: log.petId,
    occurredAt: log.occurredAt,
    logTypeId: log.logTypeId,
    logTypeName: log.logTypeName,
    logTypeScope: log.logTypeScope,
    descriptionPreview: log.descriptionPreview,
    source: log.source,
    sourceEntityType: log.sourceEntityType,
    sourceEntityId: log.sourceEntityId,
    sourceLabel: log.sourceLabel,
    metricValuesPreview:
        log.metricValuesPreview.map(mapLogMetricValue).toList(growable: false),
    attachmentsCount: log.attachmentsCount,
    hasAttachments: log.hasAttachments,
    createdByUserId: log.createdByUserId,
    createdByDisplayName: log.createdByDisplayName,
  );
}

LogDetails mapLogEntry(api.LogEntry log) {
  return LogDetails(
    id: log.id,
    petId: log.petId,
    occurredAt: log.occurredAt,
    logTypeId: log.logTypeId,
    logTypeName: log.logTypeName,
    logTypeScope: log.logTypeScope,
    description: log.description,
    source: log.source,
    sourceEntityType: log.sourceEntityType,
    sourceEntityId: log.sourceEntityId,
    sourceLabel: log.sourceLabel,
    metricValues:
        log.metricValues.map(mapLogMetricValue).toList(growable: false),
    attachments: log.attachments.map(mapLogAttachment).toList(growable: false),
    rowVersion: log.rowVersion,
    createdAt: log.createdAt,
    createdByUserId: log.createdByUserId,
    createdByDisplayName: log.createdByDisplayName,
    updatedAt: log.updatedAt,
    updatedByUserId: log.updatedByUserId,
    updatedByDisplayName: log.updatedByDisplayName,
    canEdit: log.canEdit,
    canDelete: log.canDelete,
  );
}

LogsBootstrap mapLogsBootstrap(api.LogComposerBootstrapResponse bootstrap) {
  return LogsBootstrap(
    canRead: bootstrap.permissions.logRead,
    canWrite: bootstrap.permissions.logWrite,
    recentLogTypes:
        bootstrap.recentLogTypes.map(mapLogType).toList(growable: false),
    systemLogTypes:
        bootstrap.systemLogTypes.map(mapLogType).toList(growable: false),
    customLogTypes:
        bootstrap.customLogTypes.map(mapLogType).toList(growable: false),
    systemMetrics:
        bootstrap.systemMetrics.map(mapMetric).toList(growable: false),
    customMetrics:
        bootstrap.customMetrics.map(mapMetric).toList(growable: false),
  );
}

LogsFacets? mapLogsFacets(api.LogListFacets? facets) {
  if (facets == null) {
    return null;
  }

  return LogsFacets(
    sources: facets.sources
        .map(
          (source) => LogSourceFacetItem(
            value: source.value,
            count: source.count,
          ),
        )
        .toList(growable: false),
    types: facets.types
        .map(
          (type) => LogTypeFacetItem(
            id: type.id,
            name: type.name,
            scope: type.scope,
            count: type.count,
          ),
        )
        .toList(growable: false),
    hasAttachmentsCount: facets.hasAttachmentsCount,
    hasMetricsCount: facets.hasMetricsCount,
  );
}

LogsPageResult mapLogsPage(api.LogListResponse response) {
  return LogsPageResult(
    items: response.items.map(mapLogCard).toList(growable: false),
    nextCursor: response.nextCursor,
    facets: mapLogsFacets(response.facets),
  );
}

AnalyticsMetricItem mapAnalyticsMetric(api.AnalyticsMetricSummary metric) {
  return AnalyticsMetricItem(
    metricId: metric.metricId,
    metricName: metric.metricName,
    metricScope: metric.metricScope,
    inputKind: metric.inputKind,
    unitCode: metric.unitCode,
    pointsCount: metric.pointsCount,
    firstOccurredAt: metric.firstOccurredAt,
    lastOccurredAt: metric.lastOccurredAt,
    lastValueNum: metric.lastValueNum,
    usedInLogTypes: metric.usedInLogTypes
        .map(
          (type) => AnalyticsMetricLogTypeItem(
            logTypeId: type.logTypeId,
            logTypeName: type.logTypeName,
          ),
        )
        .toList(growable: false),
  );
}

List<AnalyticsMetricItem> mapAnalyticsMetrics(
  api.AnalyticsMetricSummaryListResponse response,
) {
  return response.items.map(mapAnalyticsMetric).toList(growable: false);
}

MetricSeries mapMetricSeries(api.MetricSeriesResponse response) {
  return MetricSeries(
    metric: MetricSeriesMetric(
      id: response.metric.id,
      scope: response.metric.scope,
      petId: response.metric.petId,
      code: response.metric.code,
      name: response.metric.name,
      inputKind: response.metric.inputKind,
      unitCode: response.metric.unitCode,
      minValue: response.metric.minValue,
      maxValue: response.metric.maxValue,
    ),
    summary: response.summary == null
        ? null
        : MetricSeriesSummaryItem(
            pointsCount: response.summary!.pointsCount,
            minValueNum: response.summary!.minValueNum,
            maxValueNum: response.summary!.maxValueNum,
            lastValueNum: response.summary!.lastValueNum,
            avgValueNum: response.summary!.avgValueNum,
            sumValueNum: response.summary!.sumValueNum,
            deltaFromFirstNum: response.summary!.deltaFromFirstNum,
          ),
    points: response.points
        .map(
          (point) => MetricSeriesPointItem(
            occurredAt: point.occurredAt,
            valueNum: point.valueNum,
            logId: point.logId,
            logTypeId: point.logTypeId,
            logTypeName: point.logTypeName,
            source: point.source,
          ),
        )
        .toList(growable: false),
  );
}
