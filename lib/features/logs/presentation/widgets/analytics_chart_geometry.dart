import 'dart:math' as math;

class AnalyticsChartGeometry {
  const AnalyticsChartGeometry({
    required this.minValue,
    required this.maxValue,
    required this.displayMin,
    required this.displayMax,
    required this.tickValues,
  });

  final double minValue;
  final double maxValue;
  final double displayMin;
  final double displayMax;
  final List<double> tickValues;

  double get displayRange => displayMax - displayMin;

  factory AnalyticsChartGeometry.fromValues(List<double> values) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final padding = range == 0
        ? math.max(maxValue.abs() * 0.12, 1.0)
        : math.max(range * 0.14, 0.2);
    final displayMin = minValue - padding;
    final displayMax = maxValue + padding;
    final step = (displayMax - displayMin) / 3;

    return AnalyticsChartGeometry(
      minValue: minValue,
      maxValue: maxValue,
      displayMin: displayMin,
      displayMax: displayMax,
      tickValues: List<double>.generate(
        4,
        (index) => displayMax - (step * index),
        growable: false,
      ),
    );
  }
}
