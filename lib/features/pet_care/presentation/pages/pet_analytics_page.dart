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
          onRetry: () => ref.invalidate(petAnalyticsMetricsProvider(widget.petId)),
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
          value: selectedMetric.metricId,
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
    final sumValue = series.points.fold<double>(
      0,
      (total, point) => total + point.valueNum,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: PawlySpacing.md,
          crossAxisSpacing: PawlySpacing.md,
          childAspectRatio: 1.5,
          children: <Widget>[
            _SummaryCard(title: 'Последнее', value: _formatValue(summary?.lastValueNum, unit)),
            _SummaryCard(title: 'Минимум', value: _formatValue(summary?.minValueNum, unit)),
            _SummaryCard(title: 'Максимум', value: _formatValue(summary?.maxValueNum, unit)),
            _SummaryCard(title: 'Среднее', value: _formatValue(summary?.avgValueNum, unit)),
            _SummaryCard(title: 'Сумма', value: _formatValue(sumValue, unit)),
          ],
        ),
        const SizedBox(height: PawlySpacing.lg),
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
              Text(
                'Точек: ${series.points.length}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: PawlySpacing.md),
              SizedBox(
                height: 220,
                child: series.points.isEmpty
                    ? const Center(child: Text('Нет данных для графика.'))
                    : _MetricLineChart(points: series.points),
              ),
            ],
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
  const _MetricLineChart({required this.points});

  final List<MetricSeriesPoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MetricLineChartPainter(
        points: points.map((item) => item.valueNum).toList(growable: false),
        color: Theme.of(context).colorScheme.primary,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MetricLineChartPainter extends CustomPainter {
  const _MetricLineChartPainter({
    required this.points,
    required this.color,
  });

  final List<double> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dotPaint = Paint()..color = color;

    for (var index = 1; index <= 3; index++) {
      final y = size.height * index / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minValue = points.reduce(math.min);
    final maxValue = points.reduce(math.max);
    final range = maxValue - minValue;
    final safeRange = range == 0 ? 1.0 : range;
    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);
    final path = Path();

    for (var index = 0; index < points.length; index++) {
      final x = stepX * index;
      final normalizedY = (points[index] - minValue) / safeRange;
      final y = size.height - (normalizedY * (size.height - 16)) - 8;
      final point = Offset(x, y);

      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
      canvas.drawCircle(point, 4, dotPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _MetricLineChartPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.color != color;
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

String _formatValue(double? value, String? unit) {
  if (value == null) {
    return '—';
  }
  final number = value % 1 == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  if (unit == null || unit.isEmpty) {
    return number;
  }
  return '$number $unit';
}
