import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/analytics_models.dart';
import '../models/log_refs.dart';
import 'logs_dependencies.dart';

final petAnalyticsMetricsProvider = FutureProvider.autoDispose
    .family<List<AnalyticsMetricItem>, PetAnalyticsMetricsRef>((
  ref,
  args,
) async {
  return ref.read(logsRepositoryProvider).listAnalyticsMetrics(
        args.petId,
        query: AnalyticsMetricsQuery(
          dateFrom: args.dateFrom,
          dateTo: args.dateTo,
          typeIds: args.typeIds,
        ),
      );
});

final petMetricSeriesProvider =
    FutureProvider.autoDispose.family<MetricSeries, PetMetricSeriesRef>((
  ref,
  args,
) async {
  return ref.read(logsRepositoryProvider).getMetricSeries(
        args.petId,
        args.metricId,
        query: AnalyticsSeriesQuery(
          dateFrom: args.dateFrom,
          dateTo: args.dateTo,
          typeIds: args.typeIds,
        ),
      );
});
