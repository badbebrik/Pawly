import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import 'analytics_chart_geometry.dart';

const double chartTopPadding = 16;
const double chartBottomPadding = 32;
const double chartLeftPadding = 44;
const double chartRightPadding = 10;

Rect chartRectForSize(Size size) {
  return Rect.fromLTWH(
    chartLeftPadding,
    chartTopPadding,
    size.width - chartLeftPadding - chartRightPadding,
    size.height - chartTopPadding - chartBottomPadding,
  );
}

List<Offset> chartOffsets({
  required List<double> values,
  required double width,
  required double height,
  required AnalyticsChartGeometry geometry,
}) {
  if (values.isEmpty) {
    return const <Offset>[];
  }

  final chartRect = chartRectForSize(Size(width, height));
  if (values.length == 1) {
    return <Offset>[chartRect.center];
  }

  final stepX = chartRect.width / (values.length - 1);
  return List<Offset>.generate(values.length, (index) {
    final x = chartRect.left + (stepX * index);
    final normalized =
        (values[index] - geometry.displayMin) / geometry.displayRange;
    final y = chartRect.bottom - (normalized * chartRect.height);
    return Offset(x, y);
  }, growable: false);
}

List<int> xAxisTickIndices(int count) {
  if (count <= 1) {
    return const <int>[0];
  }
  if (count <= 4) {
    return List<int>.generate(count, (index) => index, growable: false);
  }

  final last = count - 1;
  final ticks = <int>{
    0,
    (last / 3).round(),
    ((last * 2) / 3).round(),
    last,
  }.toList()
    ..sort();
  return ticks;
}

double selectionBubbleLeft({
  required double chartWidth,
  required double bubbleWidth,
  required double anchorX,
  required Rect plotRect,
}) {
  return (anchorX - (bubbleWidth / 2))
      .clamp(plotRect.left, chartWidth - bubbleWidth)
      .toDouble();
}

double selectionBubbleTop({required double anchorY, required Rect plotRect}) {
  final top = anchorY - 72;
  if (top >= plotRect.top) {
    return top;
  }
  return math.min(anchorY + 16, plotRect.bottom - 56);
}

double yPositionForChartValue(
  double value, {
  required AnalyticsChartGeometry geometry,
  required Rect chartRect,
}) {
  final normalized = (value - geometry.displayMin) / geometry.displayRange;
  return chartRect.bottom - (normalized * chartRect.height);
}

double yAxisLabelWidth() => chartLeftPadding - PawlySpacing.sm;
