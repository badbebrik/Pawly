import 'log_constants.dart';

class AnalyticsMetricsQuery {
  const AnalyticsMetricsQuery({
    this.query,
    this.dateFrom,
    this.dateTo,
    this.source,
    this.typeIds = const <String>[],
    this.limit,
  });

  final String? query;
  final String? dateFrom;
  final String? dateTo;
  final String? source;
  final List<String> typeIds;
  final int? limit;
}

class AnalyticsSeriesQuery {
  const AnalyticsSeriesQuery({
    this.dateFrom,
    this.dateTo,
    this.source,
    this.typeIds = const <String>[],
    this.sort = LogSort.occurredAtAsc,
    this.includeSummary = true,
  });

  final String? dateFrom;
  final String? dateTo;
  final String? source;
  final List<String> typeIds;
  final String sort;
  final bool includeSummary;
}

class AnalyticsMetricLogTypeItem {
  const AnalyticsMetricLogTypeItem({
    required this.logTypeId,
    required this.logTypeName,
  });

  final String logTypeId;
  final String logTypeName;
}

class AnalyticsMetricItem {
  const AnalyticsMetricItem({
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
  final List<AnalyticsMetricLogTypeItem> usedInLogTypes;
}

class MetricSeriesMetric {
  const MetricSeriesMetric({
    required this.id,
    required this.scope,
    this.petId,
    this.code,
    required this.name,
    required this.inputKind,
    this.unitCode,
    this.minValue,
    this.maxValue,
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
}

class MetricSeriesPointItem {
  const MetricSeriesPointItem({
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
}

class MetricSeriesSummaryItem {
  const MetricSeriesSummaryItem({
    required this.pointsCount,
    this.minValueNum,
    this.maxValueNum,
    this.lastValueNum,
    this.avgValueNum,
    this.sumValueNum,
    this.deltaFromFirstNum,
  });

  final int pointsCount;
  final double? minValueNum;
  final double? maxValueNum;
  final double? lastValueNum;
  final double? avgValueNum;
  final double? sumValueNum;
  final double? deltaFromFirstNum;
}

class MetricSeries {
  const MetricSeries({
    required this.metric,
    this.summary,
    required this.points,
  });

  final MetricSeriesMetric metric;
  final MetricSeriesSummaryItem? summary;
  final List<MetricSeriesPointItem> points;
}
