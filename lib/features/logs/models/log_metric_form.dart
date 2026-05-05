class LogMetricForm {
  const LogMetricForm({
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
