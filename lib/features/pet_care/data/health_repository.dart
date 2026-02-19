import '../../../core/network/clients/health_api_client.dart';
import '../../../core/network/models/common_models.dart';
import '../../../core/network/models/log_models.dart';
import 'health_repository_models.dart';

class HealthRepository {
  const HealthRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<LogComposerBootstrapResponse> getLogsBootstrap(
    String petId, {
    bool? includeCatalog,
  }) {
    return _healthApiClient.getLogsBootstrap(
      petId,
      includeCatalog: includeCatalog,
    );
  }

  Future<LogListResponse> listLogs(
    String petId, {
    required LogListQuery query,
  }) {
    return _healthApiClient.listLogs(
      petId,
      cursor: query.cursor,
      limit: query.limit,
      query: query.searchQuery,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      typeIds: query.typeIds,
      source: query.source,
      hasAttachments: query.hasAttachments,
      hasMetrics: query.hasMetrics,
      sort: query.sort,
      includeFacets: query.includeFacets,
    );
  }

  Future<LogEntry> getLog(String petId, String logId) {
    return _healthApiClient.getLog(petId, logId);
  }

  Future<LogEntry> createLog(
    String petId, {
    required UpsertLogInput input,
  }) {
    return _healthApiClient.createLog(
      petId,
      _toUpsertLogPayload(input),
    );
  }

  Future<LogEntry> updateLog(
    String petId,
    String logId, {
    required UpsertLogInput input,
  }) {
    return _healthApiClient.updateLog(
      petId,
      logId,
      _toUpsertLogPayload(input),
    );
  }

  Future<EmptyResponse> deleteLog(
    String petId,
    String logId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteLog(
      petId,
      logId,
      DeleteLogPayload(rowVersion: rowVersion),
    );
  }

  Future<LogTypeListResponse> listLogTypes(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithMetrics,
  }) {
    return _healthApiClient.listLogTypes(
      petId,
      scope: scope,
      query: query,
      includeArchived: includeArchived,
      onlyWithMetrics: onlyWithMetrics,
    );
  }

  Future<LogType> createLogType(
    String petId, {
    required CreateLogTypeInput input,
  }) {
    return _healthApiClient.createLogType(
      petId,
      CreateLogTypePayload(
        name: input.name,
        metricRequirements: input.metricRequirements
            .map(_toLogTypeMetricRequirementPayload)
            .toList(growable: false),
      ),
    );
  }

  Future<LogType> updateLogType(
    String petId,
    String logTypeId, {
    required UpdateLogTypeInput input,
  }) {
    return _healthApiClient.updateLogType(
      petId,
      logTypeId,
      UpdateLogTypePayload(
        name: input.name,
        metricRequirements: input.metricRequirements
            .map(_toLogTypeMetricRequirementPayload)
            .toList(growable: false),
        rowVersion: input.rowVersion,
      ),
    );
  }

  Future<EmptyResponse> deleteLogType(
    String petId,
    String logTypeId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteLogType(
      petId,
      logTypeId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<MetricListResponse> listMetrics(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithData,
    bool? onlyWithUsage,
  }) {
    return _healthApiClient.listMetrics(
      petId,
      scope: scope,
      query: query,
      includeArchived: includeArchived,
      onlyWithData: onlyWithData,
      onlyWithUsage: onlyWithUsage,
    );
  }

  Future<Metric> createMetric(
    String petId, {
    required UpsertMetricInput input,
  }) {
    return _healthApiClient.createMetric(
      petId,
      CreateMetricPayload(
        name: input.name,
        inputKind: input.inputKind,
        unitCode: input.unitCode,
        minValue: input.minValue,
        maxValue: input.maxValue,
      ),
    );
  }

  Future<Metric> updateMetric(
    String petId,
    String metricId, {
    required UpdateMetricInput input,
  }) {
    return _healthApiClient.updateMetric(
      petId,
      metricId,
      UpdateMetricPayload(
        name: input.name,
        inputKind: input.inputKind,
        unitCode: input.unitCode,
        minValue: input.minValue,
        maxValue: input.maxValue,
        rowVersion: input.rowVersion,
      ),
    );
  }

  Future<EmptyResponse> deleteMetric(
    String petId,
    String metricId, {
    required int rowVersion,
  }) {
    return _healthApiClient.deleteMetric(
      petId,
      metricId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<AnalyticsMetricSummaryListResponse> listAnalyticsMetrics(
    String petId, {
    String? query,
    String? range,
    String? source,
    int? limit,
  }) {
    return _healthApiClient.listAnalyticsMetrics(
      petId,
      query: query,
      range: range,
      source: source,
      limit: limit,
    );
  }

  Future<MetricSeriesResponse> getMetricSeries(
    String petId,
    String metricId, {
    required AnalyticsSeriesQuery query,
  }) {
    return _healthApiClient.getMetricSeries(
      petId,
      metricId,
      range: query.range,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      source: query.source,
      typeIds: query.typeIds,
      sort: query.sort,
      includeSummary: query.includeSummary,
    );
  }

  UpsertLogPayload _toUpsertLogPayload(UpsertLogInput input) {
    return UpsertLogPayload(
      occurredAt: DateTime.parse(input.occurredAtIso),
      logTypeId: input.logTypeId,
      description: input.description,
      metricValues: input.metricValues
          .map(
            (item) => LogMetricValue(
              metricId: item.metricId,
              metricName: '',
              inputKind: '',
              valueNum: item.valueNum,
            ),
          )
          .toList(growable: false),
      attachmentFileIds: input.attachmentFileIds,
      rowVersion: input.rowVersion,
    );
  }

  LogTypeMetricRequirementPayload _toLogTypeMetricRequirementPayload(
    LogTypeMetricRequirementInput input,
  ) {
    return LogTypeMetricRequirementPayload(
      metricId: input.metricId,
      isRequired: input.isRequired,
    );
  }
}
