import '../../../core/network/clients/health_api_client.dart';
import '../../../core/network/models/common_models.dart';
import '../../../core/network/models/log_models.dart' as network;
import '../../shared/attachments/data/attachment_input.dart';
import '../models/analytics_models.dart';
import '../models/log_form.dart';
import '../models/log_metric_form.dart';
import '../models/log_models.dart';
import '../models/log_type_form.dart';
import '../shared/mappers/log_mappers.dart';

class LogsRepository {
  const LogsRepository({
    required HealthApiClient healthApiClient,
  }) : _healthApiClient = healthApiClient;

  final HealthApiClient _healthApiClient;

  Future<LogsBootstrap> getLogsBootstrap(
    String petId, {
    bool? includeCatalog,
  }) async {
    final response = await _healthApiClient.getLogsBootstrap(
      petId,
      includeCatalog: includeCatalog,
    );
    return mapLogsBootstrap(response);
  }

  Future<LogsPageResult> listLogs(
    String petId, {
    required LogsQuery query,
  }) async {
    final response = await _healthApiClient.listLogs(
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
    return mapLogsPage(response);
  }

  Future<LogDetails> getLog(String petId, String logId) async {
    final response = await _healthApiClient.getLog(petId, logId);
    return mapLogEntry(response);
  }

  Future<LogDetails> createLog(
    String petId, {
    required LogForm form,
    List<AttachmentInput>? attachments,
  }) async {
    final response = await _healthApiClient.createLog(
      petId,
      _toUpsertLogPayload(form: form, attachments: attachments),
    );
    return mapLogEntry(response);
  }

  Future<LogDetails> updateLog(
    String petId,
    String logId, {
    required LogForm form,
    required int rowVersion,
    List<AttachmentInput>? attachments,
  }) async {
    final response = await _healthApiClient.updateLog(
      petId,
      logId,
      _toUpsertLogPayload(
        form: form,
        attachments: attachments,
        rowVersion: rowVersion,
      ),
    );
    return mapLogEntry(response);
  }

  Future<void> deleteLog(
    String petId,
    String logId, {
    required int rowVersion,
  }) async {
    await _healthApiClient.deleteLog(
      petId,
      logId,
      network.DeleteLogPayload(rowVersion: rowVersion),
    );
  }

  Future<List<LogTypeItem>> listLogTypes(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithMetrics,
  }) async {
    final response = await _healthApiClient.listLogTypes(
      petId,
      scope: scope,
      query: query,
      includeArchived: includeArchived,
      onlyWithMetrics: onlyWithMetrics,
    );
    return response.items.map(mapLogType).toList(growable: false);
  }

  Future<LogTypeItem> createLogType(
    String petId, {
    required LogTypeForm form,
  }) async {
    final response = await _healthApiClient.createLogType(
      petId,
      network.CreateLogTypePayload(
        name: form.name,
        metricRequirements: form.metricSelections
            .map(_toLogTypeMetricRequirementPayload)
            .toList(growable: false),
      ),
    );
    return mapLogType(response);
  }

  Future<LogTypeItem> updateLogType(
    String petId,
    String logTypeId, {
    required LogTypeForm form,
    required int rowVersion,
  }) async {
    final response = await _healthApiClient.updateLogType(
      petId,
      logTypeId,
      network.UpdateLogTypePayload(
        name: form.name,
        metricRequirements: form.metricSelections
            .map(_toLogTypeMetricRequirementPayload)
            .toList(growable: false),
        rowVersion: rowVersion,
      ),
    );
    return mapLogType(response);
  }

  Future<void> deleteLogType(
    String petId,
    String logTypeId, {
    required int rowVersion,
  }) async {
    await _healthApiClient.deleteLogType(
      petId,
      logTypeId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<List<LogMetricCatalogItem>> listMetrics(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithData,
    bool? onlyWithUsage,
  }) async {
    final response = await _healthApiClient.listMetrics(
      petId,
      scope: scope,
      query: query,
      includeArchived: includeArchived,
      onlyWithData: onlyWithData,
      onlyWithUsage: onlyWithUsage,
    );
    return response.items.map(mapMetric).toList(growable: false);
  }

  Future<LogMetricCatalogItem> createMetric(
    String petId, {
    required LogMetricForm form,
  }) async {
    final response = await _healthApiClient.createMetric(
      petId,
      network.CreateMetricPayload(
        name: form.name,
        inputKind: form.inputKind,
        unitCode: form.unitCode,
        minValue: form.minValue,
        maxValue: form.maxValue,
      ),
    );
    return mapMetric(response);
  }

  Future<LogMetricCatalogItem> updateMetric(
    String petId,
    String metricId, {
    required LogMetricForm form,
    required int rowVersion,
  }) async {
    final response = await _healthApiClient.updateMetric(
      petId,
      metricId,
      network.UpdateMetricPayload(
        name: form.name,
        inputKind: form.inputKind,
        unitCode: form.unitCode,
        minValue: form.minValue,
        maxValue: form.maxValue,
        rowVersion: rowVersion,
      ),
    );
    return mapMetric(response);
  }

  Future<void> deleteMetric(
    String petId,
    String metricId, {
    required int rowVersion,
  }) async {
    await _healthApiClient.deleteMetric(
      petId,
      metricId,
      DeleteEntityPayload(rowVersion: rowVersion),
    );
  }

  Future<List<AnalyticsMetricItem>> listAnalyticsMetrics(
    String petId, {
    AnalyticsMetricsQuery query = const AnalyticsMetricsQuery(),
  }) async {
    final response = await _healthApiClient.listAnalyticsMetrics(
      petId,
      query: query.query,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      source: query.source,
      typeIds: query.typeIds,
      limit: query.limit,
    );
    return mapAnalyticsMetrics(response);
  }

  Future<MetricSeries> getMetricSeries(
    String petId,
    String metricId, {
    required AnalyticsSeriesQuery query,
  }) async {
    final response = await _healthApiClient.getMetricSeries(
      petId,
      metricId,
      dateFrom: query.dateFrom,
      dateTo: query.dateTo,
      source: query.source,
      typeIds: query.typeIds,
      sort: query.sort,
      includeSummary: query.includeSummary,
    );
    return mapMetricSeries(response);
  }

  network.UpsertLogPayload _toUpsertLogPayload({
    required LogForm form,
    List<AttachmentInput>? attachments,
    int? rowVersion,
  }) {
    return network.UpsertLogPayload(
      occurredAt: form.occurredAt.toUtc(),
      logTypeId: form.logTypeId,
      description: _emptyToNull(form.description),
      metricValues: form.metricValues
          .map(
            (item) => network.UpsertLogMetricValuePayload(
              metricId: item.metricId,
              valueNum: item.valueNum,
            ),
          )
          .toList(growable: false),
      attachments: _toAttachmentPayloads(attachments),
      rowVersion: rowVersion,
    );
  }

  List<AttachmentPayload>? _toAttachmentPayloads(
    List<AttachmentInput>? attachments,
  ) {
    return attachments
        ?.map(
          (item) => AttachmentPayload(
            fileId: item.fileId,
            fileName: _emptyToNull(item.fileName),
          ),
        )
        .toList(growable: false);
  }

  network.LogTypeMetricRequirementPayload _toLogTypeMetricRequirementPayload(
    LogTypeMetricSelection selection,
  ) {
    return network.LogTypeMetricRequirementPayload(
      metricId: selection.metricId,
      isRequired: selection.isRequired,
    );
  }

  String? _emptyToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
