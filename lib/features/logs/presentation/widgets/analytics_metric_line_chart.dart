import 'package:flutter/material.dart';

import '../../models/analytics_models.dart';
import '../../shared/formatters/analytics_formatters.dart';
import 'analytics_chart_geometry.dart';
import 'analytics_chart_layout.dart';
import 'analytics_chart_selection_bubble.dart';
import 'analytics_metric_line_chart_painter.dart';

class AnalyticsMetricLineChart extends StatelessWidget {
  const AnalyticsMetricLineChart({
    required this.points,
    required this.inputKind,
    required this.unit,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
    super.key,
  });

  final List<MetricSeriesPointItem> points;
  final String inputKind;
  final String? unit;
  final int? selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  @override
  Widget build(BuildContext context) {
    return _InteractiveMetricLineChart(
      points: points,
      inputKind: inputKind,
      unit: unit,
      color: Theme.of(context).colorScheme.primary,
      selectedIndex: selectedIndex,
      onSelectedIndexChanged: onSelectedIndexChanged,
    );
  }
}

class _InteractiveMetricLineChart extends StatefulWidget {
  const _InteractiveMetricLineChart({
    required this.points,
    required this.inputKind,
    required this.unit,
    required this.color,
    required this.selectedIndex,
    required this.onSelectedIndexChanged,
  });

  final List<MetricSeriesPointItem> points;
  final String inputKind;
  final String? unit;
  final Color color;
  final int? selectedIndex;
  final ValueChanged<int> onSelectedIndexChanged;

  @override
  State<_InteractiveMetricLineChart> createState() =>
      _InteractiveMetricLineChartState();
}

class _InteractiveMetricLineChartState
    extends State<_InteractiveMetricLineChart> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values =
        widget.points.map((item) => item.valueNum).toList(growable: false);
    final geometry = AnalyticsChartGeometry.fromValues(values);
    final selectedPoint = widget.selectedIndex == null
        ? null
        : widget.points[widget.selectedIndex!];

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
        final plotRect = chartRectForSize(chartSize);
        final pointOffsets = chartOffsets(
          values: values,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          geometry: geometry,
        );
        final selectedOffset = widget.selectedIndex == null
            ? null
            : pointOffsets[widget.selectedIndex!];

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) =>
              _updateSelection(details.localPosition, pointOffsets),
          onHorizontalDragStart: (details) =>
              _updateSelection(details.localPosition, pointOffsets),
          onHorizontalDragUpdate: (details) =>
              _updateSelection(details.localPosition, pointOffsets),
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: CustomPaint(
                  painter: MetricLineChartPainter(
                    points: widget.points,
                    geometry: geometry,
                    color: widget.color,
                    selectedIndex: widget.selectedIndex,
                    inputKind: widget.inputKind,
                    unit: widget.unit,
                    axisLabelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                    outlineColor: theme.colorScheme.outlineVariant,
                    plotBackgroundColor: widget.color.withValues(alpha: 0.025),
                    surfaceColor: theme.colorScheme.surface,
                  ),
                ),
              ),
              if (selectedPoint != null && selectedOffset != null)
                Positioned(
                  left: selectionBubbleLeft(
                    chartWidth: constraints.maxWidth,
                    bubbleWidth: 156,
                    anchorX: selectedOffset.dx,
                    plotRect: plotRect,
                  ),
                  top: selectionBubbleTop(
                    anchorY: selectedOffset.dy,
                    plotRect: plotRect,
                  ),
                  child: ChartSelectionBubble(
                    width: 156,
                    color: widget.color,
                    value: formatAnalyticsMetricValue(
                      selectedPoint.valueNum,
                      widget.inputKind,
                      widget.unit,
                    ),
                    subtitle: formatMetricPointSubtitle(selectedPoint),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _updateSelection(Offset localPosition, List<Offset> offsets) {
    final index = _nearestPointIndex(localPosition, offsets);
    if (index == widget.selectedIndex) {
      return;
    }
    widget.onSelectedIndexChanged(index);
  }

  int _nearestPointIndex(Offset tapPosition, List<Offset> offsets) {
    if (offsets.length <= 1) {
      return 0;
    }

    var minDistance = double.infinity;
    var nearestIndex = 0;

    for (var index = 0; index < offsets.length; index++) {
      final distance = (offsets[index] - tapPosition).distanceSquared;
      if (distance < minDistance) {
        minDistance = distance;
        nearestIndex = index;
      }
    }

    return nearestIndex;
  }
}
