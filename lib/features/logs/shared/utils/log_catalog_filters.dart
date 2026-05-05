import '../../models/analytics_models.dart';
import '../../models/log_models.dart';

class LogTypeFilterItem {
  const LogTypeFilterItem({
    required this.id,
    required this.name,
    required this.scope,
  });

  final String id;
  final String name;
  final String scope;
}

List<LogTypeFilterItem> buildLogTypeFilterItems({
  required LogsBootstrap bootstrap,
  LogsFacets? facets,
}) {
  final result = <LogTypeFilterItem>[];
  final seenIds = <String>{};

  void addType({
    required String id,
    required String name,
    required String scope,
  }) {
    if (!seenIds.add(id)) {
      return;
    }
    result.add(LogTypeFilterItem(id: id, name: name, scope: scope));
  }

  for (final type in bootstrap.systemLogTypes) {
    addType(id: type.id, name: type.name, scope: type.scope);
  }
  for (final type in bootstrap.customLogTypes) {
    addType(id: type.id, name: type.name, scope: type.scope);
  }
  for (final type in facets?.types ?? const <LogTypeFacetItem>[]) {
    addType(id: type.id, name: type.name, scope: type.scope);
  }

  return result;
}

List<LogTypeFilterItem> filterLogTypeFilterItemsByName({
  required List<LogTypeFilterItem> types,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return types;
  }
  return types
      .where((type) => type.name.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}

List<LogTypeItem> filterUniqueLogTypesByName({
  required List<LogTypeItem> types,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  final result = <LogTypeItem>[];
  final seenIds = <String>{};

  for (final type in types) {
    if (!seenIds.add(type.id)) {
      continue;
    }
    if (normalizedQuery.isNotEmpty &&
        !type.name.toLowerCase().contains(normalizedQuery)) {
      continue;
    }
    result.add(type);
  }

  return result;
}

List<LogMetricCatalogItem> filterMetricsByName({
  required List<LogMetricCatalogItem> metrics,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return metrics;
  }
  return metrics
      .where((metric) => metric.name.toLowerCase().contains(normalizedQuery))
      .toList(growable: false);
}

List<AnalyticsMetricItem> filterAnalyticsMetricsByName({
  required List<AnalyticsMetricItem> metrics,
  required String query,
}) {
  final normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return metrics;
  }
  return metrics
      .where(
        (metric) => metric.metricName.toLowerCase().contains(normalizedQuery),
      )
      .toList(growable: false);
}
