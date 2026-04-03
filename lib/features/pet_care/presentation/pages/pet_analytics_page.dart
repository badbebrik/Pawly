import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../providers/health_controllers.dart';

class PetAnalyticsPage extends ConsumerStatefulWidget {
  const PetAnalyticsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetAnalyticsPage> createState() => _PetAnalyticsPageState();
}

class _PetAnalyticsPageState extends ConsumerState<PetAnalyticsPage> {
  String? _selectedMetricId;
  String _range = '30d';
  DateTimeRange? _customDateRange;
  String? _dateFrom;
  String? _dateTo;
  final Set<String> _selectedTypeIds = <String>{};

  @override
  void initState() {
    super.initState();
    final resolvedRange = _resolvePresetRange('30d');
    _dateFrom = resolvedRange.dateFrom;
    _dateTo = resolvedRange.dateTo;
  }

  @override
  Widget build(BuildContext context) {
    final typeIds = _selectedTypeIds.toList(growable: false)..sort();
    final metricsAsync = ref.watch(
      petAnalyticsMetricsProvider(
        PetAnalyticsMetricsRef(
          petId: widget.petId,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          typeIds: typeIds,
        ),
      ),
    );
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );
    final typeCatalog = _AnalyticsTypeCatalog.fromBootstrap(
      bootstrapAsync.asData?.value,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: metricsAsync.when(
        data: (response) => _buildContent(
          context,
          metrics: response.items,
          typeCatalog: typeCatalog,
          isTypeCatalogLoading: bootstrapAsync.isLoading,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AnalyticsErrorView(
          onRetry: () {
            ref.invalidate(petAnalyticsMetricsProvider);
            ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required List<AnalyticsMetricSummary> metrics,
    required _AnalyticsTypeCatalog typeCatalog,
    required bool isTypeCatalogLoading,
  }) {
    final typeIds = _selectedTypeIds.toList(growable: false)..sort();
    final selectedMetric = metrics.isEmpty
        ? null
        : metrics.firstWhere(
            (item) =>
                item.metricId == (_selectedMetricId ?? metrics.first.metricId),
            orElse: () => metrics.first,
          );

    if (metrics.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          _AnalyticsCompactToolbar(
            metricLabel: 'Нет метрик',
            onPickMetric: null,
            onOpenFilters: () => _openFilters(typeCatalog),
            hasActiveFilters: _hasCustomFilters,
            activeFiltersSummary: _activeFiltersSummary(typeCatalog),
            isFiltersLoading: isTypeCatalogLoading,
          ),
          const SizedBox(height: PawlySpacing.lg),
          _AnalyticsEmptyState(
            hasTypeFilters: _selectedTypeIds.isNotEmpty,
            hasPeriodFilters: _dateFrom != null || _dateTo != null,
            onClearTypes: _selectedTypeIds.isEmpty ? null : _clearTypeFilters,
            onShowAllTime:
                (_dateFrom == null && _dateTo == null) ? null : _showAllTime,
          ),
        ],
      );
    }

    final seriesAsync = ref.watch(
      petMetricSeriesProvider(
        PetMetricSeriesRef(
          petId: widget.petId,
          metricId: selectedMetric!.metricId,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          typeIds: typeIds,
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        _AnalyticsCompactToolbar(
          metricLabel: selectedMetric.metricName,
          onPickMetric: () => _pickMetric(metrics),
          onOpenFilters: () => _openFilters(typeCatalog),
          hasActiveFilters: _hasCustomFilters,
          activeFiltersSummary: _activeFiltersSummary(typeCatalog),
          isFiltersLoading: isTypeCatalogLoading,
        ),
        const SizedBox(height: PawlySpacing.lg),
        seriesAsync.when(
          data: (series) => _AnalyticsMetricView(
            summaryMetric: selectedMetric,
            series: series,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const PawlyCard(
            child: Text('Не удалось загрузить график по выбранной метрике.'),
          ),
        ),
      ],
    );
  }

  bool get _hasCustomFilters => _selectedTypeIds.isNotEmpty || _range != '30d';

  Future<void> _pickMetric(List<AnalyticsMetricSummary> metrics) async {
    final nextMetricId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AnalyticsMetricPickerSheet(
        metrics: metrics,
        selectedMetricId: _selectedMetricId ?? metrics.first.metricId,
      ),
    );
    if (nextMetricId == null) {
      return;
    }

    setState(() {
      _selectedMetricId = nextMetricId;
    });
  }

  Future<void> _openFilters(_AnalyticsTypeCatalog typeCatalog) async {
    final nextFilters = await showModalBottomSheet<_AnalyticsFilterState>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _AnalyticsFiltersSheet(
        initialState: _AnalyticsFilterState(
          range: _range,
          customDateRange: _customDateRange,
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          selectedTypeIds: _selectedTypeIds,
        ),
        typeCatalog: typeCatalog,
      ),
    );
    if (nextFilters == null) {
      return;
    }

    setState(() {
      _range = nextFilters.range;
      _customDateRange = nextFilters.customDateRange;
      _dateFrom = nextFilters.dateFrom;
      _dateTo = nextFilters.dateTo;
      _selectedTypeIds
        ..clear()
        ..addAll(nextFilters.selectedTypeIds);
    });
  }

  void _clearTypeFilters() {
    setState(() {
      _selectedTypeIds.clear();
    });
  }

  void _showAllTime() {
    setState(() {
      _range = 'all';
      _customDateRange = null;
      _dateFrom = null;
      _dateTo = null;
    });
  }

  String _periodLabel() {
    if (_range == 'custom' && _customDateRange != null) {
      return _formatDateRange(_customDateRange!);
    }
    return _rangeLabel(_range);
  }

  String _selectedTypesLabel(_AnalyticsTypeCatalog catalog) {
    final selectedTypes = catalog.resolveSelected(_selectedTypeIds);
    if (selectedTypes.isEmpty) {
      return '';
    }
    if (selectedTypes.length == 1) {
      return selectedTypes.first.name;
    }
    return '${selectedTypes.length} типа записей';
  }

  String? _activeFiltersSummary(_AnalyticsTypeCatalog catalog) {
    if (!_hasCustomFilters) {
      return null;
    }

    final parts = <String>[];
    if (_range != '30d') {
      parts.add(_periodLabel());
    }

    final typesLabel = _selectedTypesLabel(catalog);
    if (typesLabel.isNotEmpty) {
      parts.add(typesLabel);
    }

    if (parts.isEmpty) {
      return 'Есть активные фильтры';
    }

    return parts.join(' · ');
  }
}

class _AnalyticsMetricView extends StatelessWidget {
  const _AnalyticsMetricView({
    required this.summaryMetric,
    required this.series,
  });

  final AnalyticsMetricSummary summaryMetric;
  final MetricSeriesResponse series;

  @override
  Widget build(BuildContext context) {
    final summary = series.summary;
    final unit = series.metric.unitCode;
    final inputKind = series.metric.inputKind;
    final selectedPoint = series.points.isEmpty ? null : series.points.last;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PawlyCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _AnalyticsHeroValue(
                title: summaryMetric.metricName,
                value: _formatValue(
                  selectedPoint?.valueNum ?? summary?.lastValueNum,
                  inputKind,
                  unit,
                ),
                subtitle: selectedPoint == null
                    ? _metricKindLabel(inputKind)
                    : _formatPointSubtitle(selectedPoint),
              ),
              const SizedBox(height: PawlySpacing.lg),
              SizedBox(
                height: 400,
                child: series.points.isEmpty
                    ? const Center(child: Text('Нет данных для графика.'))
                    : _MetricLineChart(
                        points: series.points,
                        inputKind: inputKind,
                        unit: unit,
                      ),
              ),
            ],
          ),
        ),
        if (summary != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  title: 'Мин',
                  value: _formatValue(summary.minValueNum, inputKind, unit),
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: _SummaryCard(
                  title: 'Макс',
                  value: _formatValue(summary.maxValueNum, inputKind, unit),
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: _SummaryCard(
                  title: 'Среднее',
                  value: _formatValue(summary.avgValueNum, inputKind, unit),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _AnalyticsHeroValue extends StatelessWidget {
  const _AnalyticsHeroValue({
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1,
              ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricLineChart extends StatelessWidget {
  const _MetricLineChart({
    required this.points,
    required this.inputKind,
    required this.unit,
  });

  final List<MetricSeriesPoint> points;
  final String inputKind;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return _InteractiveMetricLineChart(
      points: points,
      inputKind: inputKind,
      unit: unit,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

const double _chartTopPadding = 16;
const double _chartBottomPadding = 32;
const double _chartLeftPadding = 44;
const double _chartRightPadding = 10;

Rect _chartRectForSize(Size size) {
  return Rect.fromLTWH(
    _chartLeftPadding,
    _chartTopPadding,
    size.width - _chartLeftPadding - _chartRightPadding,
    size.height - _chartTopPadding - _chartBottomPadding,
  );
}

List<Offset> _chartOffsets({
  required List<double> values,
  required double width,
  required double height,
  required _ChartGeometry geometry,
}) {
  if (values.isEmpty) {
    return const <Offset>[];
  }

  final chartRect = _chartRectForSize(Size(width, height));
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

List<int> _xAxisTickIndices(int count) {
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

double _selectionBubbleLeft({
  required double chartWidth,
  required double bubbleWidth,
  required double anchorX,
  required Rect plotRect,
}) {
  return (anchorX - (bubbleWidth / 2))
      .clamp(plotRect.left, chartWidth - bubbleWidth)
      .toDouble();
}

double _selectionBubbleTop({
  required double anchorY,
  required Rect plotRect,
}) {
  final top = anchorY - 72;
  if (top >= plotRect.top) {
    return top;
  }
  return math.min(anchorY + 16, plotRect.bottom - 56);
}

class _InteractiveMetricLineChart extends StatefulWidget {
  const _InteractiveMetricLineChart({
    required this.points,
    required this.inputKind,
    required this.unit,
    required this.color,
  });

  final List<MetricSeriesPoint> points;
  final String inputKind;
  final String? unit;
  final Color color;

  @override
  State<_InteractiveMetricLineChart> createState() =>
      _InteractiveMetricLineChartState();
}

class _InteractiveMetricLineChartState
    extends State<_InteractiveMetricLineChart> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = null;
  }

  @override
  void didUpdateWidget(covariant _InteractiveMetricLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final values =
        widget.points.map((item) => item.valueNum).toList(growable: false);
    final geometry = _ChartGeometry.fromValues(values);
    final selectedPoint =
        _selectedIndex == null ? null : widget.points[_selectedIndex!];

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartSize = Size(constraints.maxWidth, constraints.maxHeight);
        final plotRect = _chartRectForSize(chartSize);
        final pointOffsets = _chartOffsets(
          values: values,
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          geometry: geometry,
        );
        final selectedOffset = _selectedIndex == null
            ? null
            : pointOffsets[_selectedIndex!];

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
                  painter: _MetricLineChartPainter(
                    points: widget.points,
                    geometry: geometry,
                    color: widget.color,
                    selectedIndex: _selectedIndex,
                    inputKind: widget.inputKind,
                    unit: widget.unit,
                    axisLabelStyle: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1,
                    ),
                    outlineColor: theme.colorScheme.outlineVariant,
                    plotBackgroundColor:
                        widget.color.withValues(alpha: 0.025),
                    surfaceColor: theme.colorScheme.surface,
                  ),
                ),
              ),
              if (selectedPoint != null && selectedOffset != null)
                Positioned(
                  left: _selectionBubbleLeft(
                    chartWidth: constraints.maxWidth,
                    bubbleWidth: 156,
                    anchorX: selectedOffset.dx,
                    plotRect: plotRect,
                  ),
                  top: _selectionBubbleTop(
                    anchorY: selectedOffset.dy,
                    plotRect: plotRect,
                  ),
                  child: _ChartSelectionBubble(
                    width: 156,
                    color: widget.color,
                    value: _formatValue(
                      selectedPoint.valueNum,
                      widget.inputKind,
                      widget.unit,
                    ),
                    subtitle: _formatPointSubtitle(selectedPoint),
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
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
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

class _MetricLineChartPainter extends CustomPainter {
  const _MetricLineChartPainter({
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

  final List<MetricSeriesPoint> points;
  final _ChartGeometry geometry;
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
    final chartRect = _chartRectForSize(size);
    final values = points.map((item) => item.valueNum).toList(growable: false);
    final offsets = _chartOffsets(
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
      RRect.fromRectAndRadius(
        chartRect,
        const Radius.circular(PawlyRadius.md),
      ),
      plotPaint,
    );

    final yTicks = inputKind == 'BOOLEAN'
        ? const <double>[1, 0]
        : geometry.tickValues;

    for (final tickValue in yTicks) {
      final y = _yPositionForValue(
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
        _formatValue(tickValue, inputKind, unit),
        axisLabelStyle,
        Offset(0, y - 8),
        maxWidth: _chartLeftPadding - PawlySpacing.sm,
        textAlign: TextAlign.right,
      );
    }

    final xTickIndices = _xAxisTickIndices(points.length);
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
      final label = _formatAxisDate(points[index].occurredAt);
      final labelPainter = _textPainter(
        label,
        axisLabelStyle,
        maxWidth: 56,
        textAlign: TextAlign.center,
      );
      final labelX = (point.dx - (labelPainter.width / 2)).clamp(
        0.0,
        size.width - labelPainter.width,
      ).toDouble();
      labelPainter.paint(
        canvas,
        Offset(labelX, chartRect.bottom + PawlySpacing.sm),
      );
    }

    if (points.length == 1) {
      final point = offsets.first;
      canvas.drawCircle(
        point,
        16,
        Paint()..color = color.withValues(alpha: 0.12),
      );
      canvas.drawCircle(point, 6.5, selectedDotPaint);
      canvas.drawCircle(
        point,
        3,
        pointFillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          chartRect,
          const Radius.circular(PawlyRadius.md),
        ),
        borderPaint,
      );
      return;
    }
    final path = Path();
    final areaPath = Path();

    for (var index = 0; index < offsets.length; index++) {
      final point = offsets[index];
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
        areaPath.moveTo(point.dx, chartRect.bottom);
        areaPath.lineTo(point.dx, point.dy);
      } else {
        final previous = offsets[index - 1];
        if (points.length <= 4) {
          path.lineTo(point.dx, point.dy);
          areaPath.lineTo(point.dx, point.dy);
        } else {
          final controlX = (previous.dx + point.dx) / 2;
          path.cubicTo(
              controlX, previous.dy, controlX, point.dy, point.dx, point.dy);
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
    }

    areaPath
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..close();

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);

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

      canvas.drawCircle(
        point,
        isSelected || isLast ? 5.5 : 4,
        pointFillPaint,
      );
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
      RRect.fromRectAndRadius(
        chartRect,
        const Radius.circular(PawlyRadius.md),
      ),
      borderPaint,
    );
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

  double _yPositionForValue(
    double value, {
    required _ChartGeometry geometry,
    required Rect chartRect,
  }) {
    final normalized =
        (value - geometry.displayMin) / geometry.displayRange;
    return chartRect.bottom - (normalized * chartRect.height);
  }

  @override
  bool shouldRepaint(covariant _MetricLineChartPainter oldDelegate) {
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

class _ChartSelectionBubble extends StatelessWidget {
  const _ChartSelectionBubble({
    required this.width,
    required this.color,
    required this.value,
    required this.subtitle,
  });

  final double width;
  final Color color;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.md,
        vertical: PawlySpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(PawlyRadius.md),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
          ),
          const SizedBox(height: PawlySpacing.xxs),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChartGeometry {
  const _ChartGeometry({
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

  factory _ChartGeometry.fromValues(List<double> values) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;
    final padding = range == 0
        ? math.max(maxValue.abs() * 0.12, 1.0)
        : math.max(range * 0.14, 0.2);
    final displayMin = minValue - padding;
    final displayMax = maxValue + padding;
    final step = (displayMax - displayMin) / 3;

    return _ChartGeometry(
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

class _AnalyticsCompactToolbar extends StatelessWidget {
  const _AnalyticsCompactToolbar({
    required this.metricLabel,
    required this.onPickMetric,
    required this.onOpenFilters,
    required this.hasActiveFilters,
    required this.activeFiltersSummary,
    required this.isFiltersLoading,
  });

  final String metricLabel;
  final VoidCallback? onPickMetric;
  final VoidCallback onOpenFilters;
  final bool hasActiveFilters;
  final String? activeFiltersSummary;
  final bool isFiltersLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: PawlyCard(
                onTap: onPickMetric,
                padding: const EdgeInsets.symmetric(
                  horizontal: PawlySpacing.md,
                  vertical: PawlySpacing.md,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        metricLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    const Icon(Icons.keyboard_arrow_down_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
              child: InkWell(
                onTap: onOpenFilters,
                borderRadius: BorderRadius.circular(PawlyRadius.lg),
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(PawlyRadius.lg),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      if (isFiltersLoading)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        const Icon(Icons.tune_rounded),
                      if (hasActiveFilters)
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (activeFiltersSummary != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.sm),
          Text(
            activeFiltersSummary!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}

class _AnalyticsFilterState {
  const _AnalyticsFilterState({
    required this.range,
    required this.customDateRange,
    required this.dateFrom,
    required this.dateTo,
    required this.selectedTypeIds,
  });

  final String range;
  final DateTimeRange? customDateRange;
  final String? dateFrom;
  final String? dateTo;
  final Set<String> selectedTypeIds;
}

class _AnalyticsFiltersSheet extends StatefulWidget {
  const _AnalyticsFiltersSheet({
    required this.initialState,
    required this.typeCatalog,
  });

  final _AnalyticsFilterState initialState;
  final _AnalyticsTypeCatalog typeCatalog;

  @override
  State<_AnalyticsFiltersSheet> createState() => _AnalyticsFiltersSheetState();
}

class _AnalyticsFiltersSheetState extends State<_AnalyticsFiltersSheet> {
  late String _range;
  late DateTimeRange? _customDateRange;
  late String? _dateFrom;
  late String? _dateTo;
  late Set<String> _selectedTypeIds;

  @override
  void initState() {
    super.initState();
    _range = widget.initialState.range;
    _customDateRange = widget.initialState.customDateRange;
    _dateFrom = widget.initialState.dateFrom;
    _dateTo = widget.initialState.dateTo;
    _selectedTypeIds = Set<String>.from(widget.initialState.selectedTypeIds);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTypes = widget.typeCatalog.resolveSelected(_selectedTypeIds);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: PawlySpacing.lg,
          right: PawlySpacing.lg,
          top: PawlySpacing.md,
          bottom: PawlySpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Фильтры аналитики',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: PawlySpacing.md),
            Text(
              'Период',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            Wrap(
              spacing: PawlySpacing.xs,
              runSpacing: PawlySpacing.xs,
              children: <Widget>[
                for (final item in const <String>['7d', '30d', '90d', 'all'])
                  ChoiceChip(
                    label: Text(_rangeLabel(item)),
                    selected: _range == item,
                    onSelected: (_) => _setPresetRange(item),
                  ),
                ChoiceChip(
                  label: Text(
                    _range == 'custom' && _customDateRange != null
                        ? _formatDateRange(_customDateRange!)
                        : 'Свои даты',
                  ),
                  selected: _range == 'custom',
                  onSelected: (_) => _pickCustomRange(),
                ),
              ],
            ),
            const SizedBox(height: PawlySpacing.lg),
            Text(
              'Типы записей',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            OutlinedButton.icon(
              onPressed: widget.typeCatalog.isEmpty ? null : _pickTypes,
              icon: const Icon(Icons.tune_rounded),
              label: Text(_selectedTypesSheetLabel(widget.typeCatalog)),
            ),
            if (selectedTypes.isNotEmpty) ...<Widget>[
              const SizedBox(height: PawlySpacing.sm),
              Wrap(
                spacing: PawlySpacing.xs,
                runSpacing: PawlySpacing.xs,
                children: selectedTypes
                    .map(
                      (type) => InputChip(
                        label: Text(type.name),
                        onDeleted: () {
                          setState(() {
                            _selectedTypeIds.remove(type.id);
                          });
                        },
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            const SizedBox(height: PawlySpacing.lg),
            Row(
              children: <Widget>[
                Expanded(
                  child: PawlyButton(
                    label: 'Сбросить',
                    onPressed: _resetFilters,
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Expanded(
                  child: PawlyButton(
                    label: 'Применить',
                    onPressed: () => Navigator.of(context).pop(
                      _AnalyticsFilterState(
                        range: _range,
                        customDateRange: _customDateRange,
                        dateFrom: _dateFrom,
                        dateTo: _dateTo,
                        selectedTypeIds: _selectedTypeIds,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _setPresetRange(String range) {
    final resolvedRange = _resolvePresetRange(range);
    setState(() {
      _range = range;
      _customDateRange = null;
      _dateFrom = resolvedRange.dateFrom;
      _dateTo = resolvedRange.dateTo;
    });
  }

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 29)),
          end: now,
        );
    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: initialRange,
      helpText: 'Выбери период',
      saveText: 'Применить',
      cancelText: 'Отмена',
    );
    if (pickedRange == null) {
      return;
    }

    final normalizedRange = DateTimeRange(
      start: DateTime(
        pickedRange.start.year,
        pickedRange.start.month,
        pickedRange.start.day,
      ),
      end: DateTime(
        pickedRange.end.year,
        pickedRange.end.month,
        pickedRange.end.day,
      ),
    );

    setState(() {
      _range = 'custom';
      _customDateRange = normalizedRange;
      _dateFrom = _startOfDayUtcIso(normalizedRange.start);
      _dateTo = _endOfDayUtcIso(normalizedRange.end);
    });
  }

  Future<void> _pickTypes() async {
    final selectedIds = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _AnalyticsTypeFilterSheet(
        catalog: widget.typeCatalog,
        selectedTypeIds: _selectedTypeIds,
      ),
    );
    if (selectedIds == null) {
      return;
    }

    setState(() {
      _selectedTypeIds = selectedIds.toSet();
    });
  }

  void _resetFilters() {
    final resolvedRange = _resolvePresetRange('30d');
    setState(() {
      _range = '30d';
      _customDateRange = null;
      _dateFrom = resolvedRange.dateFrom;
      _dateTo = resolvedRange.dateTo;
      _selectedTypeIds.clear();
    });
  }

  String _selectedTypesSheetLabel(_AnalyticsTypeCatalog catalog) {
    final selectedTypes = catalog.resolveSelected(_selectedTypeIds);
    if (selectedTypes.isEmpty) {
      return 'Все типы записей';
    }
    if (selectedTypes.length == 1) {
      return selectedTypes.first.name;
    }
    return '${selectedTypes.length} выбрано';
  }
}

class _AnalyticsMetricPickerSheet extends StatefulWidget {
  const _AnalyticsMetricPickerSheet({
    required this.metrics,
    required this.selectedMetricId,
  });

  final List<AnalyticsMetricSummary> metrics;
  final String selectedMetricId;

  @override
  State<_AnalyticsMetricPickerSheet> createState() =>
      _AnalyticsMetricPickerSheetState();
}

class _AnalyticsMetricPickerSheetState
    extends State<_AnalyticsMetricPickerSheet> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalizedQuery = _query.trim().toLowerCase();
    final filteredMetrics = widget.metrics
        .where(
          (metric) => metric.metricName.toLowerCase().contains(normalizedQuery),
        )
        .toList(growable: false);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: PawlySpacing.lg,
          right: PawlySpacing.lg,
          top: PawlySpacing.md,
          bottom: PawlySpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Выбери метрику',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: PawlySpacing.md),
            PawlyTextField(
              controller: _searchController,
              hintText: 'Поиск по метрикам',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: PawlySpacing.md),
            Flexible(
              child: filteredMetrics.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(PawlySpacing.lg),
                        child: Text('Метрики не найдены.'),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredMetrics.length,
                      itemBuilder: (context, index) {
                        final metric = filteredMetrics[index];
                        final isSelected =
                            metric.metricId == widget.selectedMetricId;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            isSelected
                                ? Icons.radio_button_checked_rounded
                                : Icons.radio_button_off_rounded,
                          ),
                          title: Text(metric.metricName),
                          subtitle: Text(_metricKindLabel(metric.inputKind)),
                          onTap: () =>
                              Navigator.of(context).pop(metric.metricId),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  const _AnalyticsEmptyState({
    required this.hasTypeFilters,
    required this.hasPeriodFilters,
    this.onClearTypes,
    this.onShowAllTime,
  });

  final bool hasTypeFilters;
  final bool hasPeriodFilters;
  final VoidCallback? onClearTypes;
  final VoidCallback? onShowAllTime;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      title: const Text('Нет данных для аналитики'),
      footer: Wrap(
        spacing: PawlySpacing.sm,
        runSpacing: PawlySpacing.sm,
        children: <Widget>[
          if (onClearTypes != null)
            PawlyButton(
              label: 'Убрать типы',
              onPressed: onClearTypes,
              variant: PawlyButtonVariant.secondary,
            ),
          if (onShowAllTime != null)
            PawlyButton(
              label: 'Показать всё время',
              onPressed: onShowAllTime,
              variant: PawlyButtonVariant.secondary,
            ),
        ],
      ),
      child: Text(
        hasTypeFilters || hasPeriodFilters
            ? 'За выбранный период и фильтры по типам записи пока не найдены.'
            : 'Для аналитики пока нет метрик с данными.',
      ),
    );
  }
}

class _AnalyticsTypeCatalog {
  const _AnalyticsTypeCatalog({
    required this.sections,
    required this.byId,
  });

  final List<_AnalyticsTypeSection> sections;
  final Map<String, LogType> byId;

  factory _AnalyticsTypeCatalog.fromBootstrap(
    LogComposerBootstrapResponse? bootstrap,
  ) {
    if (bootstrap == null) {
      return const _AnalyticsTypeCatalog(
        sections: <_AnalyticsTypeSection>[],
        byId: <String, LogType>{},
      );
    }

    final seenIds = <String>{};
    List<LogType> unique(List<LogType> values) {
      return values
          .where((item) => seenIds.add(item.id))
          .toList(growable: false);
    }

    final recent = unique(bootstrap.recentLogTypes);
    final system = unique(bootstrap.systemLogTypes);
    final custom = unique(bootstrap.customLogTypes);
    final allTypes = <LogType>[
      ...recent,
      ...system,
      ...custom,
    ];

    return _AnalyticsTypeCatalog(
      sections: <_AnalyticsTypeSection>[
        if (recent.isNotEmpty)
          _AnalyticsTypeSection(title: 'Недавние', items: recent),
        if (system.isNotEmpty)
          _AnalyticsTypeSection(title: 'Системные', items: system),
        if (custom.isNotEmpty)
          _AnalyticsTypeSection(title: 'Мои', items: custom),
      ],
      byId: <String, LogType>{
        for (final type in allTypes) type.id: type,
      },
    );
  }

  bool get isEmpty => byId.isEmpty;

  List<LogType> resolveSelected(Iterable<String> ids) {
    final selected = <LogType>[];
    for (final id in ids) {
      final type = byId[id];
      if (type != null) {
        selected.add(type);
      }
    }
    selected.sort((left, right) => left.name.compareTo(right.name));
    return selected;
  }

  List<_AnalyticsTypeSection> filter(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return sections;
    }

    return sections
        .map(
          (section) => _AnalyticsTypeSection(
            title: section.title,
            items: section.items
                .where(
                  (item) => item.name.toLowerCase().contains(normalizedQuery),
                )
                .toList(growable: false),
          ),
        )
        .where((section) => section.items.isNotEmpty)
        .toList(growable: false);
  }
}

class _AnalyticsTypeSection {
  const _AnalyticsTypeSection({
    required this.title,
    required this.items,
  });

  final String title;
  final List<LogType> items;
}

class _AnalyticsTypeFilterSheet extends StatefulWidget {
  const _AnalyticsTypeFilterSheet({
    required this.catalog,
    required this.selectedTypeIds,
  });

  final _AnalyticsTypeCatalog catalog;
  final Set<String> selectedTypeIds;

  @override
  State<_AnalyticsTypeFilterSheet> createState() =>
      _AnalyticsTypeFilterSheetState();
}

class _AnalyticsTypeFilterSheetState extends State<_AnalyticsTypeFilterSheet> {
  late final TextEditingController _searchController;
  late final Set<String> _selectedTypeIds;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedTypeIds = Set<String>.from(widget.selectedTypeIds);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredSections = widget.catalog.filter(_query);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: PawlySpacing.lg,
          right: PawlySpacing.lg,
          top: PawlySpacing.md,
          bottom: PawlySpacing.lg + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Фильтр по типам записей',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: PawlySpacing.md),
            PawlyTextField(
              controller: _searchController,
              hintText: 'Поиск по типам',
              prefixIcon: const Icon(Icons.search_rounded),
              onChanged: (value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: PawlySpacing.md),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _selectedTypeIds.clear();
                  });
                },
                child: const Text('Снять фильтр по типам'),
              ),
            ),
            Flexible(
              child: filteredSections.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(PawlySpacing.lg),
                        child: Text('Типы записей не найдены.'),
                      ),
                    )
                  : ListView(
                      shrinkWrap: true,
                      children: filteredSections
                          .map(
                            (section) => _AnalyticsTypeSectionWidget(
                              section: section,
                              selectedTypeIds: _selectedTypeIds,
                              onToggle: _toggleType,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
            const SizedBox(height: PawlySpacing.md),
            Row(
              children: <Widget>[
                Expanded(
                  child: PawlyButton(
                    label: 'Сбросить',
                    onPressed: () => Navigator.of(context).pop(<String>[]),
                    variant: PawlyButtonVariant.secondary,
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Expanded(
                  child: PawlyButton(
                    label: 'Применить',
                    onPressed: () => Navigator.of(context).pop(
                      _selectedTypeIds.toList(growable: false)..sort(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _toggleType(String typeId, bool isSelected) {
    setState(() {
      if (isSelected) {
        _selectedTypeIds.add(typeId);
      } else {
        _selectedTypeIds.remove(typeId);
      }
    });
  }
}

class _AnalyticsTypeSectionWidget extends StatelessWidget {
  const _AnalyticsTypeSectionWidget({
    required this.section,
    required this.selectedTypeIds,
    required this.onToggle,
  });

  final _AnalyticsTypeSection section;
  final Set<String> selectedTypeIds;
  final void Function(String typeId, bool isSelected) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            section.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          ...section.items.map(
            (type) => CheckboxListTile(
              value: selectedTypeIds.contains(type.id),
              contentPadding: EdgeInsets.zero,
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(type.name),
              subtitle: type.metricRequirements.isEmpty
                  ? null
                  : Text(
                      type.metricRequirements
                          .map((item) => item.metricName)
                          .where((value) => value.isNotEmpty)
                          .join(', '),
                    ),
              onChanged: (selected) => onToggle(type.id, selected ?? false),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsErrorView extends StatelessWidget {
  const _AnalyticsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить аналитику.'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _ResolvedAnalyticsRange {
  const _ResolvedAnalyticsRange({
    this.dateFrom,
    this.dateTo,
  });

  final String? dateFrom;
  final String? dateTo;
}

String _rangeLabel(String range) {
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

_ResolvedAnalyticsRange _resolvePresetRange(String range) {
  if (range == 'all') {
    return const _ResolvedAnalyticsRange();
  }

  final nowUtc = DateTime.now().toUtc();
  final duration = switch (range) {
    '7d' => const Duration(days: 7),
    '30d' => const Duration(days: 30),
    '90d' => const Duration(days: 90),
    _ => null,
  };

  if (duration == null) {
    return const _ResolvedAnalyticsRange();
  }

  return _ResolvedAnalyticsRange(
    dateFrom: nowUtc.subtract(duration).toIso8601String(),
    dateTo: nowUtc.toIso8601String(),
  );
}

String _metricKindLabel(String inputKind) {
  return switch (inputKind) {
    'NUMERIC' => 'Число',
    'SCALE' => 'Шкала',
    'BOOLEAN' => 'Да / Нет',
    _ => inputKind,
  };
}

String _formatValue(double? value, String inputKind, String? unit) {
  if (value == null) {
    return '—';
  }
  if (inputKind == 'BOOLEAN') {
    return value == 0 ? 'Нет' : 'Да';
  }
  final number =
      value % 1 == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  if (unit == null || unit.isEmpty) {
    return number;
  }
  return '$number $unit';
}

String _formatAxisDate(DateTime? value) {
  if (value == null) {
    return '—';
  }
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day.$month';
}

String _formatPointSubtitle(MetricSeriesPoint point) {
  return point.occurredAt == null
      ? 'Дата не указана'
      : _formatPointDateTime(point.occurredAt!);
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

String _formatDateRange(DateTimeRange value) {
  return '${_formatDate(value.start)} - ${_formatDate(value.end)}';
}

String _startOfDayUtcIso(DateTime value) {
  return DateTime(value.year, value.month, value.day).toUtc().toIso8601String();
}

String _endOfDayUtcIso(DateTime value) {
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
