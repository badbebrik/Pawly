import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/analytics_models.dart';
import '../../models/log_constants.dart';
import '../../shared/formatters/analytics_formatters.dart';
import 'analytics_chart_geometry.dart';
import 'analytics_chart_layout.dart';

class MetricLineChartPainter extends CustomPainter {
  const MetricLineChartPainter({
    required this.points,
    required this.geometry,
    required this.color,
    required this.selectedIndex,
    required this.inputKind,
    required this.unit,
    required this.axisLabelStyle,
    required this.outlineColor,
    required this.plotBackgroundColor,
    required this.surfaceColor,
  });

  final List<MetricSeriesPointItem> points;
  final AnalyticsChartGeometry geometry;
  final int? selectedIndex;
  final Color color;
  final String inputKind;
  final String? unit;
  final TextStyle? axisLabelStyle;
  final Color outlineColor;
  final Color plotBackgroundColor;
  final Color surfaceColor;

  @override
  void paint(Canvas canvas, Size size) {
    final chartRect = chartRectForSize(size);
    final values = points.map((item) => item.valueNum).toList(growable: false);
    final offsets = chartOffsets(
      values: values,
      width: size.width,
      height: size.height,
      geometry: geometry,
    );

    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final borderPaint = Paint()
      ..color = outlineColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final plotPaint = Paint()..color = plotBackgroundColor;
    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          color.withValues(alpha: 0.14),
          color.withValues(alpha: 0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final pointStrokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final pointFillPaint = Paint()..color = surfaceColor;
    final selectedDotPaint = Paint()..color = color;

    canvas.drawRRect(
      RRect.fromRectAndRadius(chartRect, const Radius.circular(PawlyRadius.md)),
      plotPaint,
    );

    final yTicks = inputKind == LogMetricInputKind.boolean
        ? const <double>[1, 0]
        : geometry.tickValues;

    for (final tickValue in yTicks) {
      final y = yPositionForChartValue(
        tickValue,
        geometry: geometry,
        chartRect: chartRect,
      );
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
      _paintText(
        canvas,
        formatAnalyticsMetricValue(tickValue, inputKind, unit),
        axisLabelStyle,
        Offset(0, y - 8),
        maxWidth: yAxisLabelWidth(),
        textAlign: TextAlign.right,
      );
    }

    final xTickIndices = xAxisTickIndices(points.length);
    for (final index in xTickIndices) {
      final point = offsets[index];
      if (index != 0 && index != points.length - 1) {
        canvas.drawLine(
          Offset(point.dx, chartRect.top),
          Offset(point.dx, chartRect.bottom),
          Paint()
            ..color = color.withValues(alpha: 0.06)
            ..strokeWidth = 1,
        );
      }
      final label = formatAnalyticsAxisDate(points[index].occurredAt);
      final labelPainter = _textPainter(
        label,
        axisLabelStyle,
        maxWidth: 56,
        textAlign: TextAlign.center,
      );
      final labelX = (point.dx - (labelPainter.width / 2))
          .clamp(0.0, size.width - labelPainter.width)
          .toDouble();
      labelPainter.paint(
        canvas,
        Offset(labelX, chartRect.bottom + PawlySpacing.sm),
      );
    }

    if (points.length == 1) {
      _paintSinglePoint(
        canvas: canvas,
        chartRect: chartRect,
        point: offsets.first,
        borderPaint: borderPaint,
        pointFillPaint: pointFillPaint,
        selectedDotPaint: selectedDotPaint,
      );
      return;
    }

    final paths = _buildLinePaths(offsets, chartRect);
    canvas.drawPath(paths.areaPath, areaPaint);
    canvas.drawPath(paths.linePath, linePaint);

    _paintPoints(
      canvas: canvas,
      offsets: offsets,
      pointFillPaint: pointFillPaint,
      pointStrokePaint: pointStrokePaint,
      selectedDotPaint: selectedDotPaint,
    );

    if (selectedIndex != null) {
      final selectedPoint = offsets[selectedIndex!];
      canvas.drawLine(
        Offset(selectedPoint.dx, chartRect.top),
        Offset(selectedPoint.dx, chartRect.bottom),
        Paint()
          ..color = color.withValues(alpha: 0.16)
          ..strokeWidth = 1.5,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(chartRect, const Radius.circular(PawlyRadius.md)),
      borderPaint,
    );
  }

  void _paintSinglePoint({
    required Canvas canvas,
    required Rect chartRect,
    required Offset point,
    required Paint borderPaint,
    required Paint pointFillPaint,
    required Paint selectedDotPaint,
  }) {
    canvas.drawCircle(
        point, 16, Paint()..color = color.withValues(alpha: 0.12));
    canvas.drawCircle(point, 6.5, selectedDotPaint);
    canvas.drawCircle(point, 3, pointFillPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(chartRect, const Radius.circular(PawlyRadius.md)),
      borderPaint,
    );
  }

  _ChartPaths _buildLinePaths(List<Offset> offsets, Rect chartRect) {
    final path = Path();
    final areaPath = Path();

    for (var index = 0; index < offsets.length; index++) {
      final point = offsets[index];
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
        areaPath.moveTo(point.dx, chartRect.bottom);
        areaPath.lineTo(point.dx, point.dy);
        continue;
      }

      final previous = offsets[index - 1];
      if (points.length <= 4) {
        path.lineTo(point.dx, point.dy);
        areaPath.lineTo(point.dx, point.dy);
      } else {
        final controlX = (previous.dx + point.dx) / 2;
        path.cubicTo(
          controlX,
          previous.dy,
          controlX,
          point.dy,
          point.dx,
          point.dy,
        );
        areaPath.cubicTo(
          controlX,
          previous.dy,
          controlX,
          point.dy,
          point.dx,
          point.dy,
        );
      }
    }

    areaPath
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..close();

    return _ChartPaths(linePath: path, areaPath: areaPath);
  }

  void _paintPoints({
    required Canvas canvas,
    required List<Offset> offsets,
    required Paint pointFillPaint,
    required Paint pointStrokePaint,
    required Paint selectedDotPaint,
  }) {
    final lastIndex = offsets.length - 1;
    for (var index = 0; index < offsets.length; index++) {
      final point = offsets[index];
      final isSelected = selectedIndex == index;
      final isLast = index == lastIndex;

      if (isSelected) {
        canvas.drawCircle(
          point,
          11,
          Paint()..color = color.withValues(alpha: 0.14),
        );
      } else if (isLast) {
        canvas.drawCircle(
          point,
          9,
          Paint()..color = color.withValues(alpha: 0.10),
        );
      }

      canvas.drawCircle(point, isSelected || isLast ? 5.5 : 4, pointFillPaint);
      canvas.drawCircle(
        point,
        isSelected || isLast ? 5.5 : 4,
        pointStrokePaint,
      );

      if (selectedIndex == index) {
        canvas.drawCircle(point, 3, selectedDotPaint);
      } else if (isLast) {
        canvas.drawCircle(point, 2.5, selectedDotPaint);
      }
    }
  }

  TextPainter _textPainter(
    String text,
    TextStyle? style, {
    double? maxWidth,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth ?? double.infinity);
    return painter;
  }

  void _paintText(
    Canvas canvas,
    String text,
    TextStyle? style,
    Offset offset, {
    double? maxWidth,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = _textPainter(
      text,
      style,
      maxWidth: maxWidth,
      textAlign: textAlign,
    );
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant MetricLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.geometry != geometry ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.inputKind != inputKind ||
        oldDelegate.unit != unit ||
        oldDelegate.axisLabelStyle != axisLabelStyle ||
        oldDelegate.outlineColor != outlineColor ||
        oldDelegate.plotBackgroundColor != plotBackgroundColor ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

class _ChartPaths {
  const _ChartPaths({required this.linePath, required this.areaPath});

  final Path linePath;
  final Path areaPath;
}
