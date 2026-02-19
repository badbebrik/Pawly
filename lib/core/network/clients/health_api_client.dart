import '../api_client.dart';
import '../api_context.dart';
import '../api_endpoints.dart';
import '../models/common_models.dart';
import '../models/log_models.dart';

class HealthApiClient {
  HealthApiClient(this._apiClient);

  final ApiClient _apiClient;

  static const _withUserAndToken = ApiRequestOptions(
    requiresUserId: true,
    requiresAccessToken: true,
  );

  Future<LogComposerBootstrapResponse> getLogsBootstrap(
    String petId, {
    bool? includeCatalog,
  }) {
    return _apiClient.get<LogComposerBootstrapResponse>(
      ApiEndpoints.petLogsBootstrap(petId),
      queryParameters: <String, dynamic>{
        'include_catalog': includeCatalog,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: LogComposerBootstrapResponse.fromJson,
    );
  }

  Future<LogListResponse> listLogs(
    String petId, {
    String? cursor,
    int? limit,
    String? query,
    String? dateFrom,
    String? dateTo,
    List<String>? typeIds,
    String? source,
    bool? hasAttachments,
    bool? hasMetrics,
    String? sort,
    bool? includeFacets,
  }) {
    return _apiClient.get<LogListResponse>(
      ApiEndpoints.petLogs(petId),
      queryParameters: <String, dynamic>{
        'cursor': cursor,
        'limit': limit,
        'q': query,
        'date_from': dateFrom,
        'date_to': dateTo,
        'type_ids': _csv(typeIds),
        'source': source,
        'has_attachments': hasAttachments,
        'has_metrics': hasMetrics,
        'sort': sort,
        'include_facets': includeFacets,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: LogListResponse.fromJson,
    );
  }

  Future<LogEntry> getLog(String petId, String logId) {
    return _apiClient.get<LogEntry>(
      ApiEndpoints.petLogById(petId, logId),
      requestOptions: _withUserAndToken,
      decoder: LogEntry.fromJson,
    );
  }

  Future<LogEntry> createLog(String petId, UpsertLogPayload payload) {
    return _apiClient.post<LogEntry>(
      ApiEndpoints.petLogs(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: LogEntry.fromJson,
    );
  }

  Future<LogEntry> updateLog(
    String petId,
    String logId,
    UpsertLogPayload payload,
  ) {
    return _apiClient.patch<LogEntry>(
      ApiEndpoints.petLogById(petId, logId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: LogEntry.fromJson,
    );
  }

  Future<EmptyResponse> deleteLog(
    String petId,
    String logId,
    DeleteLogPayload payload,
  ) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.petLogById(petId, logId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<LogTypeListResponse> listLogTypes(
    String petId, {
    String? scope,
    String? query,
    bool? includeArchived,
    bool? onlyWithMetrics,
  }) {
    return _apiClient.get<LogTypeListResponse>(
      ApiEndpoints.petLogTypes(petId),
      queryParameters: <String, dynamic>{
        'scope': scope,
        'q': query,
        'include_archived': includeArchived,
        'only_with_metrics': onlyWithMetrics,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: LogTypeListResponse.fromJson,
    );
  }

  Future<LogType> createLogType(String petId, CreateLogTypePayload payload) {
    return _apiClient.post<LogType>(
      ApiEndpoints.petLogTypes(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: LogType.fromJson,
    );
  }

  Future<LogType> updateLogType(
    String petId,
    String logTypeId,
    UpdateLogTypePayload payload,
  ) {
    return _apiClient.patch<LogType>(
      ApiEndpoints.petLogTypeById(petId, logTypeId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: LogType.fromJson,
    );
  }

  Future<EmptyResponse> deleteLogType(
    String petId,
    String logTypeId,
    DeleteEntityPayload payload,
  ) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.petLogTypeById(petId, logTypeId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: EmptyResponse.fromJson,
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
    return _apiClient.get<MetricListResponse>(
      ApiEndpoints.petMetrics(petId),
      queryParameters: <String, dynamic>{
        'scope': scope,
        'q': query,
        'include_archived': includeArchived,
        'only_with_data': onlyWithData,
        'only_with_usage': onlyWithUsage,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: MetricListResponse.fromJson,
    );
  }

  Future<Metric> createMetric(String petId, CreateMetricPayload payload) {
    return _apiClient.post<Metric>(
      ApiEndpoints.petMetrics(petId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: Metric.fromJson,
    );
  }

  Future<Metric> updateMetric(
    String petId,
    String metricId,
    UpdateMetricPayload payload,
  ) {
    return _apiClient.patch<Metric>(
      ApiEndpoints.petMetricById(petId, metricId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: Metric.fromJson,
    );
  }

  Future<EmptyResponse> deleteMetric(
    String petId,
    String metricId,
    DeleteEntityPayload payload,
  ) {
    return _apiClient.delete<EmptyResponse>(
      ApiEndpoints.petMetricById(petId, metricId),
      data: payload.toJson(),
      requestOptions: _withUserAndToken,
      decoder: EmptyResponse.fromJson,
    );
  }

  Future<AnalyticsMetricSummaryListResponse> listAnalyticsMetrics(
    String petId, {
    String? query,
    String? range,
    String? source,
    int? limit,
  }) {
    return _apiClient.get<AnalyticsMetricSummaryListResponse>(
      ApiEndpoints.petAnalyticsMetrics(petId),
      queryParameters: <String, dynamic>{
        'q': query,
        'range': range,
        'source': source,
        'limit': limit,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: AnalyticsMetricSummaryListResponse.fromJson,
    );
  }

  Future<MetricSeriesResponse> getMetricSeries(
    String petId,
    String metricId, {
    String? range,
    String? dateFrom,
    String? dateTo,
    String? source,
    List<String>? typeIds,
    String? sort,
    bool? includeSummary,
  }) {
    return _apiClient.get<MetricSeriesResponse>(
      ApiEndpoints.petAnalyticsMetricSeries(petId, metricId),
      queryParameters: <String, dynamic>{
        'range': range,
        'date_from': dateFrom,
        'date_to': dateTo,
        'source': source,
        'type_ids': _csv(typeIds),
        'sort': sort,
        'include_summary': includeSummary,
      }..removeWhere((_, dynamic value) => value == null),
      requestOptions: _withUserAndToken,
      decoder: MetricSeriesResponse.fromJson,
    );
  }

  String? _csv(List<String>? values) {
    if (values == null || values.isEmpty) {
      return null;
    }
    return values.join(',');
  }
}
