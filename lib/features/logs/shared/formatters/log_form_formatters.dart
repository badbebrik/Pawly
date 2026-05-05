import '../../models/log_constants.dart';
import '../../models/log_models.dart';
import 'log_metric_formatters.dart';

String logMetricRequirementHint(LogTypeMetricRequirementItem requirement) {
  if (requirement.inputKind == LogMetricInputKind.boolean) {
    return 'Выберите Да или Нет';
  }
  if (requirement.minValue != null || requirement.maxValue != null) {
    final min = formatLogMetricBound(requirement.minValue) ?? '...';
    final max = formatLogMetricBound(requirement.maxValue) ?? '...';
    return 'Допустимый диапазон: $min–$max';
  }
  final unit = formatDisplayUnitCode(requirement.unitCode);
  if (unit.isNotEmpty) {
    return 'Введите значение в $unit';
  }
  return 'Введите значение';
}

String formatLogFormDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}

String logMetricRequirementLabel(LogTypeMetricRequirementItem requirement) {
  final name = logMetricRequirementName(requirement);
  return requirement.isRequired ? '$name *' : name;
}

String logMetricRequirementName(LogTypeMetricRequirementItem requirement) {
  final name = requirement.metricName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return 'Показатель';
}

String logMetricKindLabel(String inputKind) {
  return switch (inputKind) {
    LogMetricInputKind.numeric => 'Число',
    LogMetricInputKind.scale => 'Шкала',
    LogMetricInputKind.boolean => 'Да / Нет',
    _ => inputKind,
  };
}

String logMetricPlaceholder(LogTypeMetricRequirementItem requirement) {
  return switch (requirement.inputKind) {
    LogMetricInputKind.scale => 'Например, 4',
    LogMetricInputKind.numeric => 'Например, 4.2',
    _ => 'Введите значение',
  };
}

String? formatLogMetricBound(double? value) {
  if (value == null) {
    return null;
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}

String formatLogMetricInputValue(double value) {
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}

String logTypeMetricSummary(LogTypeMetricRequirementItem requirement) {
  final name = logMetricRequirementName(requirement);
  final kind = logMetricKindLabel(requirement.inputKind);
  return '$name ($kind)';
}

String logTypeMetricsLabel(LogTypeItem type) {
  if (type.metricRequirements.isEmpty) {
    return 'Показатели не заданы';
  }
  final metrics = type.metricRequirements.map(logTypeMetricSummary).join(', ');
  return 'Показатели: $metrics';
}

String logTypeMetricNames(LogTypeItem type) {
  return type.metricRequirements
      .map((item) => item.metricName)
      .where((value) => value.isNotEmpty)
      .join(', ');
}

String logTypeMetricNamesSubtitle(LogTypeItem type) {
  final metrics = logTypeMetricNames(type);
  return metrics.isEmpty ? 'Показатели не заданы' : 'Показатели: $metrics';
}

String logTypeScopeLabel(String scope) {
  return scope == LogTypeScope.system ? 'Системный' : 'Мой';
}

String logMetricScopeLabel(String scope) {
  return scope == LogTypeScope.system ? 'Системная' : 'Моя';
}

String logMetricCatalogSubtitle(LogMetricCatalogItem metric) {
  final kind = logMetricKindLabel(metric.inputKind);
  if (metric.inputKind == LogMetricInputKind.boolean) {
    return kind;
  }

  final unit = formatDisplayUnitCode(metric.unitCode);
  final unitLabel = unit.isEmpty ? 'без единиц' : unit;
  final range = _logMetricCatalogRange(metric.minValue, metric.maxValue);
  if (range == null) {
    return '$kind · $unitLabel';
  }
  return '$kind · $unitLabel · $range';
}

String? _logMetricCatalogRange(double? minValue, double? maxValue) {
  if (minValue == null && maxValue == null) {
    return null;
  }
  final min = formatLogMetricBound(minValue) ?? '...';
  final max = formatLogMetricBound(maxValue) ?? '...';
  return '$min-$max';
}
