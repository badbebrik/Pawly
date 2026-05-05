class LogTypeForm {
  const LogTypeForm({
    required this.name,
    required this.metricSelections,
  });

  final String name;
  final List<LogTypeMetricSelection> metricSelections;
}

class LogTypeMetricSelection {
  const LogTypeMetricSelection({
    required this.metricId,
    required this.isRequired,
  });

  final String metricId;
  final bool isRequired;
}
