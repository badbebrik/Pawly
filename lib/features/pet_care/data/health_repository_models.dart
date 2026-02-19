class LogListQuery {
  const LogListQuery({
    this.cursor,
    this.limit = 30,
    this.searchQuery,
    this.dateFrom,
    this.dateTo,
    this.typeIds = const <String>[],
    this.source,
    this.hasAttachments,
    this.hasMetrics,
    this.sort = 'occurred_at_desc',
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

class LogMetricInput {
  const LogMetricInput({
    required this.metricId,
    required this.valueNum,
  });

  final String metricId;
  final double valueNum;
}

class UpsertLogInput {
  const UpsertLogInput({
    required this.occurredAtIso,
    this.logTypeId,
    this.description,
    this.metricValues = const <LogMetricInput>[],
    this.attachmentFileIds = const <String>[],
    this.rowVersion,
  });

  final String occurredAtIso;
  final String? logTypeId;
  final String? description;
  final List<LogMetricInput> metricValues;
  final List<String> attachmentFileIds;
  final int? rowVersion;
}

class LogTypeMetricRequirementInput {
  const LogTypeMetricRequirementInput({
    required this.metricId,
    required this.isRequired,
  });

  final String metricId;
  final bool isRequired;
}

class CreateLogTypeInput {
  const CreateLogTypeInput({
    required this.name,
    this.metricRequirements = const <LogTypeMetricRequirementInput>[],
  });

  final String name;
  final List<LogTypeMetricRequirementInput> metricRequirements;
}

class UpdateLogTypeInput extends CreateLogTypeInput {
  const UpdateLogTypeInput({
    required super.name,
    super.metricRequirements,
    required this.rowVersion,
  });

  final int rowVersion;
}

class UpsertMetricInput {
  const UpsertMetricInput({
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
}

class UpdateMetricInput extends UpsertMetricInput {
  const UpdateMetricInput({
    required super.name,
    required super.inputKind,
    super.unitCode,
    super.minValue,
    super.maxValue,
    required this.rowVersion,
  });

  final int rowVersion;
}

class AnalyticsSeriesQuery {
  const AnalyticsSeriesQuery({
    this.range,
    this.dateFrom,
    this.dateTo,
    this.source,
    this.typeIds = const <String>[],
    this.sort = 'occurred_at_asc',
    this.includeSummary = true,
  });

  final String? range;
  final String? dateFrom;
  final String? dateTo;
  final String? source;
  final List<String> typeIds;
  final String sort;
  final bool includeSummary;
}
