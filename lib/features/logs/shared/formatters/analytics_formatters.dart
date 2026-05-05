import 'package:flutter/material.dart';

import '../../models/analytics_models.dart';
import '../../models/log_constants.dart';
import '../utils/analytics_type_catalog.dart';
import 'log_metric_formatters.dart';

class AnalyticsResolvedRange {
  const AnalyticsResolvedRange({this.dateFrom, this.dateTo});

  final String? dateFrom;
  final String? dateTo;
}

String analyticsRangeLabel(String range) {
  switch (range) {
    case '7d':
      return '7 дней';
    case '30d':
      return '30 дней';
    case '90d':
      return '90 дней';
    case 'all':
      return 'Все';
    default:
      return range;
  }
}

AnalyticsResolvedRange resolveAnalyticsPresetRange(String range) {
  if (range == 'all') {
    return const AnalyticsResolvedRange();
  }

  final nowUtc = DateTime.now().toUtc();
  final duration = switch (range) {
    '7d' => const Duration(days: 7),
    '30d' => const Duration(days: 30),
    '90d' => const Duration(days: 90),
    _ => null,
  };

  if (duration == null) {
    return const AnalyticsResolvedRange();
  }

  return AnalyticsResolvedRange(
    dateFrom: nowUtc.subtract(duration).toIso8601String(),
    dateTo: nowUtc.toIso8601String(),
  );
}

String analyticsMetricKindLabel(String inputKind) {
  return switch (inputKind) {
    LogMetricInputKind.numeric => 'Число',
    LogMetricInputKind.scale => 'Шкала',
    LogMetricInputKind.boolean => 'Да / Нет',
    _ => inputKind,
  };
}

String analyticsMetricSubtitle(AnalyticsMetricItem metric) {
  final kind = analyticsMetricKindLabel(metric.inputKind);
  if (metric.inputKind == LogMetricInputKind.boolean) {
    return kind;
  }
  final unit = formatDisplayUnitCode(metric.unitCode);
  if (unit.isEmpty) {
    return kind;
  }
  return '$kind · $unit';
}

String analyticsPeriodLabel({
  required String range,
  required DateTimeRange? customDateRange,
}) {
  if (range == 'custom' && customDateRange != null) {
    return formatAnalyticsDateRange(customDateRange);
  }
  return analyticsRangeLabel(range);
}

String analyticsSelectedTypesLabel({
  required AnalyticsTypeCatalog catalog,
  required Iterable<String> selectedTypeIds,
}) {
  final selectedTypes = catalog.resolveSelected(selectedTypeIds);
  if (selectedTypes.isEmpty) {
    return '';
  }
  if (selectedTypes.length == 1) {
    return selectedTypes.first.name;
  }
  return '${selectedTypes.length} типа записей';
}

String? analyticsActiveFiltersSummary({
  required String range,
  required DateTimeRange? customDateRange,
  required AnalyticsTypeCatalog typeCatalog,
  required Iterable<String> selectedTypeIds,
}) {
  final hasCustomFilters = selectedTypeIds.isNotEmpty || range != '30d';
  if (!hasCustomFilters) {
    return null;
  }

  final parts = <String>[];
  if (range != '30d') {
    parts.add(
      analyticsPeriodLabel(range: range, customDateRange: customDateRange),
    );
  }

  final typesLabel = analyticsSelectedTypesLabel(
    catalog: typeCatalog,
    selectedTypeIds: selectedTypeIds,
  );
  if (typesLabel.isNotEmpty) {
    parts.add(typesLabel);
  }

  if (parts.isEmpty) {
    return 'Есть активные фильтры';
  }
  return parts.join(' · ');
}

String formatAnalyticsMetricValue(
  double? value,
  String inputKind,
  String? unit,
) {
  if (value == null) {
    return '—';
  }
  if (inputKind == LogMetricInputKind.boolean) {
    return value == 0 ? 'Нет' : 'Да';
  }
  final number =
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  final displayUnit = formatDisplayUnitCode(unit);
  if (displayUnit.isEmpty) {
    return number;
  }
  return '$number $displayUnit';
}

String formatAnalyticsMetricSum(
  double? value,
  String inputKind,
  String? unit,
) {
  if (value == null) {
    return '—';
  }
  if (inputKind == LogMetricInputKind.boolean ||
      inputKind == LogMetricInputKind.scale) {
    return '—';
  }
  return formatAnalyticsMetricValue(value, inputKind, unit);
}

String formatAnalyticsMetricSummaryValue(
  double? value,
  String inputKind,
  String? unit,
) {
  if (inputKind == LogMetricInputKind.boolean) {
    return '—';
  }
  return formatAnalyticsMetricValue(value, inputKind, unit);
}

String formatAnalyticsMetricCount(int value) {
  return value.toString();
}

String formatAnalyticsAxisDate(DateTime? value) {
  if (value == null) {
    return '—';
  }
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String formatMetricPointSubtitle(MetricSeriesPointItem point) {
  return point.occurredAt == null
      ? 'Дата не указана'
      : _formatPointDateTime(point.occurredAt!);
}

String formatAnalyticsDateRange(DateTimeRange value) {
  return '${_formatDate(value.start)} - ${_formatDate(value.end)}';
}

String startOfDayUtcIso(DateTime value) {
  return DateTime(value.year, value.month, value.day).toUtc().toIso8601String();
}

String endOfDayUtcIso(DateTime value) {
  return DateTime(
    value.year,
    value.month,
    value.day,
    23,
    59,
    59,
    999,
  ).toUtc().toIso8601String();
}

String _formatPointDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month.${local.year}';
}
