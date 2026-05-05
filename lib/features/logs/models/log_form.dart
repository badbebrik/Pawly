class LogFormMetricValue {
  const LogFormMetricValue({
    required this.metricId,
    required this.valueNum,
  });

  final String metricId;
  final double valueNum;
}

class LogForm {
  const LogForm({
    required this.occurredAt,
    this.logTypeId,
    this.description,
    this.metricValues = const <LogFormMetricValue>[],
  });

  final DateTime occurredAt;
  final String? logTypeId;
  final String? description;
  final List<LogFormMetricValue> metricValues;
}
