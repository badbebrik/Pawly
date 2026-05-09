import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/analytics_models.dart';
import '../../shared/formatters/analytics_formatters.dart';
import 'analytics_metric_chart.dart';

class AnalyticsMetricView extends StatefulWidget {
  const AnalyticsMetricView({
    required this.summaryMetric,
    required this.series,
    super.key,
  });

  final AnalyticsMetricItem summaryMetric;
  final MetricSeries series;

  @override
  State<AnalyticsMetricView> createState() => _AnalyticsMetricViewState();
}

class _AnalyticsMetricViewState extends State<AnalyticsMetricView> {
  int? _selectedPointIndex;

  @override
  void didUpdateWidget(covariant AnalyticsMetricView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.series.metric.id != widget.series.metric.id ||
        oldWidget.series.points.length != widget.series.points.length) {
      _selectedPointIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = widget.series.summary;
    final unit = widget.series.metric.unitCode;
    final inputKind = widget.series.metric.inputKind;
    final selectedPoint = _selectedPoint();
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _AnalyticsHeroValue(
                  title: widget.summaryMetric.metricName,
                  value: formatAnalyticsMetricValue(
                    selectedPoint?.valueNum ?? summary?.lastValueNum,
                    inputKind,
                    unit,
                  ),
                  subtitle: selectedPoint == null
                      ? analyticsMetricKindLabel(inputKind)
                      : formatMetricPointSubtitle(selectedPoint),
                ),
                const SizedBox(height: PawlySpacing.md),
                SizedBox(
                  height: 320,
                  child: widget.series.points.isEmpty
                      ? const AnalyticsChartEmptyState()
                      : AnalyticsMetricLineChart(
                          points: widget.series.points,
                          inputKind: inputKind,
                          unit: unit,
                          selectedIndex: _selectedPointIndex,
                          onSelectedIndexChanged: _selectPoint,
                        ),
                ),
              ],
            ),
          ),
        ),
        if (summary != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: _SummaryCard(
                  title: 'Мин',
                  value: formatAnalyticsMetricSummaryValue(
                    summary.minValueNum,
                    inputKind,
                    unit,
                  ),
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: _SummaryCard(
                  title: 'Макс',
                  value: formatAnalyticsMetricSummaryValue(
                    summary.maxValueNum,
                    inputKind,
                    unit,
                  ),
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: _SummaryCard(
                  title: 'Среднее',
                  value: formatAnalyticsMetricSummaryValue(
                    summary.avgValueNum,
                    inputKind,
                    unit,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.sm),
          _SummaryCard(
            title: 'Количество измерений',
            value: formatAnalyticsMetricCount(summary.pointsCount),
          ),
          const SizedBox(height: PawlySpacing.sm),
          _SummaryCard(
            title: 'Сумма',
            value: formatAnalyticsMetricSum(
              summary.sumValueNum,
              inputKind,
              unit,
            ),
          ),
        ],
      ],
    );
  }

  MetricSeriesPointItem? _selectedPoint() {
    final points = widget.series.points;
    if (points.isEmpty) {
      return null;
    }
    final selectedIndex = _selectedPointIndex;
    if (selectedIndex != null &&
        selectedIndex >= 0 &&
        selectedIndex < points.length) {
      return points[selectedIndex];
    }
    return points.last;
  }

  void _selectPoint(int index) {
    if (_selectedPointIndex == index) {
      return;
    }
    setState(() {
      _selectedPointIndex = index;
    });
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(PawlyRadius.lg),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(PawlySpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: PawlySpacing.xxs),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
