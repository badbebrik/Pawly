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

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(petAnalyticsMetricsProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Аналитика')),
      body: metricsAsync.when(
        data: (response) => _buildContent(context, response.items),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _AnalyticsErrorView(
          onRetry: () =>
              ref.invalidate(petAnalyticsMetricsProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<AnalyticsMetricSummary> metrics,
  ) {
    if (metrics.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(PawlySpacing.lg),
          child: PawlyCard(
            child: Text('Для аналитики пока нет метрик с данными.'),
          ),
        ),
      );
    }

    final selectedMetricId = _selectedMetricId ?? metrics.first.metricId;
    final selectedMetric = metrics.firstWhere(
      (item) => item.metricId == selectedMetricId,
      orElse: () => metrics.first,
    );
    final seriesAsync = ref.watch(
      petMetricSeriesProvider(
        PetMetricSeriesRef(
          petId: widget.petId,
          metricId: selectedMetric.metricId,
          range: _range,
        ),
      ),
    );

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        DropdownButtonFormField<String>(
          initialValue: selectedMetric.metricId,
          items: metrics
              .map(
                (metric) => DropdownMenuItem<String>(
                  value: metric.metricId,
                  child: Text(metric.metricName),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }
            setState(() {
              _selectedMetricId = value;
            });
          },
          decoration: const InputDecoration(labelText: 'Метрика'),
        ),
        const SizedBox(height: PawlySpacing.md),
        Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: <Widget>[
            for (final range in const <String>['7d', '30d', '90d', 'all'])
              ChoiceChip(
                label: Text(_rangeLabel(range)),
                selected: _range == range,
                onSelected: (_) {
                  setState(() {
                    _range = range;
                  });
                },
              ),
          ],
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        PawlyCard(
          title: Text(
            summaryMetric.metricName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: PawlySpacing.sm,
                runSpacing: PawlySpacing.xs,
                children: <Widget>[
                  Text(
                    'Точек: ${series.points.length}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (summaryMetric.usedInLogTypes.isNotEmpty)
                    Text(
                      'Типы: ${summaryMetric.usedInLogTypes.map((item) => item.logTypeName).join(', ')}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  Text(
                    'Тип метрики: ${_metricKindLabel(inputKind)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: PawlySpacing.md),
              SizedBox(
                height: 320,
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
        const SizedBox(height: PawlySpacing.lg),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PawlySpacing.md,
          crossAxisSpacing: PawlySpacing.md,
          childAspectRatio: 1.5,
          children: <Widget>[
            _SummaryCard(
                title: 'Последнее',
                value: _formatValue(summary?.lastValueNum, inputKind, unit)),
            _SummaryCard(
                title: 'Минимум',
                value: _formatValue(summary?.minValueNum, inputKind, unit)),
            _SummaryCard(
                title: 'Максимум',
                value: _formatValue(summary?.maxValueNum, inputKind, unit)),
            _SummaryCard(
                title: 'Среднее',
                value: _formatValue(summary?.avgValueNum, inputKind, unit)),
          ],
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
    _selectedIndex = widget.points.isEmpty ? null : widget.points.length - 1;
  }

  @override
  void didUpdateWidget(covariant _InteractiveMetricLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.points != widget.points) {
      _selectedIndex = widget.points.isEmpty ? null : widget.points.length - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final values =
        widget.points.map((item) => item.valueNum).toList(growable: false);
    final geometry = _ChartGeometry.fromValues(values);
    final selectedPoint =
        _selectedIndex == null ? null : widget.points[_selectedIndex!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (selectedPoint != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(PawlySpacing.md),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(PawlyRadius.lg),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        _formatValue(
                          selectedPoint.valueNum,
                          widget.inputKind,
                          widget.unit,
                        ),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: PawlySpacing.xxs),
                      Text(
                        _formatPointSubtitle(selectedPoint),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (selectedPoint.logTypeName != null)
                  PawlyBadge(
                    label: selectedPoint.logTypeName!,
                    tone: PawlyBadgeTone.info,
                  ),
              ],
            ),
          ),
        const SizedBox(height: PawlySpacing.md),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartHeight = constraints.maxHeight - 32;

              return Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: <Widget>[
                        Positioned.fill(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTapDown: (details) {
                              final index = _nearestPointIndex(
                                details.localPosition.dx,
                                constraints.maxWidth,
                                widget.points.length,
                              );
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            child: CustomPaint(
                              painter: _MetricLineChartPainter(
                                points: values,
                                color: widget.color,
                                selectedIndex: _selectedIndex,
                              ),
                              child: const SizedBox.expand(),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _AxisLabel(
                            label: _formatValue(
                              geometry.maxValue,
                              widget.inputKind,
                              widget.unit,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 0,
                          child: _AxisLabel(
                            label: _formatValue(
                              geometry.minValue,
                              widget.inputKind,
                              widget.unit,
                            ),
                          ),
                        ),
                        if (_selectedIndex != null)
                          Positioned(
                            left: _selectedPointX(
                                  constraints.maxWidth,
                                  widget.points.length,
                                  _selectedIndex!,
                                ) -
                                1,
                            top: 0,
                            bottom: 16,
                            child: Container(
                              width: 2,
                              decoration: BoxDecoration(
                                color: widget.color.withValues(alpha: 0.18),
                                borderRadius:
                                    BorderRadius.circular(PawlyRadius.pill),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 24,
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            _formatAxisDate(widget.points.first.occurredAt),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ),
                        Text(
                          _formatAxisDate(widget.points.last.occurredAt),
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                      height: math.max(
                          0, chartHeight - (constraints.maxHeight - 32))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  int _nearestPointIndex(double tapX, double width, int itemCount) {
    if (itemCount <= 1) {
      return 0;
    }
    final stepX = width / (itemCount - 1);
    final rawIndex = (tapX / stepX).round();
    return rawIndex.clamp(0, itemCount - 1);
  }

  double _selectedPointX(double width, int itemCount, int index) {
    if (itemCount <= 1) {
      return width / 2;
    }
    return (width / (itemCount - 1)) * index;
  }
}

class _MetricLineChartPainter extends CustomPainter {
  const _MetricLineChartPainter({
    required this.points,
    required this.color,
    required this.selectedIndex,
  });

  final List<double> points;
  final int? selectedIndex;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const topPadding = 12.0;
    const bottomPadding = 18.0;
    const sidePadding = 8.0;
    final chartRect = Rect.fromLTWH(
      sidePadding,
      topPadding,
      size.width - (sidePadding * 2),
      size.height - topPadding - bottomPadding,
    );

    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final areaPaint = Paint()
      ..shader = LinearGradient(
        colors: <Color>[
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(chartRect);
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final selectedDotPaint = Paint()..color = color;
    final dotPaint = Paint()..color = color;

    for (var index = 1; index <= 3; index++) {
      final y = chartRect.top + (chartRect.height * index / 4);
      canvas.drawLine(
        Offset(chartRect.left, y),
        Offset(chartRect.right, y),
        gridPaint,
      );
    }

    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final range = maxValue - minValue;
    final safeRange = range == 0 ? 1.0 : range;
    final stepX =
        points.length == 1 ? 0.0 : chartRect.width / (points.length - 1);
    final path = Path();
    final areaPath = Path();
    final offsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final x = chartRect.left + (stepX * index);
      final normalizedY = (points[index] - minValue) / safeRange;
      final y = chartRect.bottom - (normalizedY * chartRect.height);
      final point = Offset(x, y);
      offsets.add(point);

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
        areaPath.moveTo(point.dx, chartRect.bottom);
        areaPath.lineTo(point.dx, point.dy);
      } else {
        final previous = offsets[index - 1];
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

    areaPath
      ..lineTo(offsets.last.dx, chartRect.bottom)
      ..close();

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        chartRect,
        const Radius.circular(PawlyRadius.lg),
      ),
      Paint()..color = color.withValues(alpha: 0.04),
    );
    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(path, linePaint);

    for (var index = 0; index < offsets.length; index++) {
      final point = offsets[index];
      final radius = selectedIndex == index ? 6.0 : 3.5;
      canvas.drawCircle(point, radius, dotPaint);
      if (selectedIndex == index) {
        canvas.drawCircle(
          point,
          10,
          Paint()
            ..color = color.withValues(alpha: 0.14)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(point, 6, selectedDotPaint);
        canvas.drawCircle(
          point,
          3,
          Paint()..color = Colors.white,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MetricLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PawlySpacing.xs,
        vertical: PawlySpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ChartGeometry {
  const _ChartGeometry({
    required this.minValue,
    required this.maxValue,
  });

  final double minValue;
  final double maxValue;

  factory _ChartGeometry.fromValues(List<double> values) {
    return _ChartGeometry(
      minValue: values.reduce(math.min),
      maxValue: values.reduce(math.max),
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
  final date = point.occurredAt == null
      ? 'Дата не указана'
      : _formatPointDateTime(point.occurredAt!);
  final source = point.source == 'HEALTH' ? 'Из здоровья' : 'Пользовательская';
  return '$date · $source';
}

String _formatPointDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}
