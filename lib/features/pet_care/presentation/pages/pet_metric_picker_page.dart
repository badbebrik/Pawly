import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../providers/health_controllers.dart';
import '../utils/metric_unit_formatter.dart';

class PetMetricPickerPage extends ConsumerStatefulWidget {
  const PetMetricPickerPage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetMetricPickerPage> createState() =>
      _PetMetricPickerPageState();
}

class _PetMetricPickerPageState extends ConsumerState<PetMetricPickerPage> {
  late final TextEditingController _searchController;
  String _searchQuery = '';

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
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Выбрать показатель',
      floatingActionButton: PawlyAddActionButton(
        label: 'Новый показатель',
        tooltip: 'Создать показатель',
        onTap: _openCreateMetric,
      ),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MetricPickerErrorView(
          onRetry: () =>
              ref.invalidate(petLogComposerBootstrapProvider(widget.petId)),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogComposerBootstrapResponse bootstrap,
  ) {
    final systemMetrics = _filterMetrics(bootstrap.systemMetrics);
    final customMetrics = _filterMetrics(bootstrap.customMetrics);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        PawlyTextField(
          controller: _searchController,
          hintText: 'Поиск по показателям',
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        if (systemMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          _MetricPickerSection(title: 'Системные', metrics: systemMetrics),
        ],
        if (customMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          _MetricPickerSection(title: 'Мои', metrics: customMetrics),
        ],
      ],
    );
  }

  List<Metric> _filterMetrics(List<Metric> metrics) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return metrics;
    }
    return metrics
        .where((metric) => metric.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  Future<void> _openCreateMetric() async {
    final createdMetricId = await context.pushNamed<String>(
      'petMetricCreate',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (createdMetricId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(createdMetricId);
  }
}

class _MetricPickerSection extends StatelessWidget {
  const _MetricPickerSection({required this.title, required this.metrics});

  final String title;
  final List<Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: PawlySpacing.sm),
        ...metrics.map(
          (metric) => Padding(
            padding: const EdgeInsets.only(bottom: PawlySpacing.md),
            child: _MetricChoiceCard(metric: metric),
          ),
        ),
      ],
    );
  }
}

class _MetricChoiceCard extends StatelessWidget {
  const _MetricChoiceCard({required this.metric});

  final Metric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: InkWell(
        onTap: () => Navigator.of(context).pop(metric.id),
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          padding: const EdgeInsets.all(PawlySpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      metric.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    Text(
                      _metricSubtitle(metric),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    Text(
                      metric.scope == 'SYSTEM' ? 'Системная' : 'Моя',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricPickerErrorView extends StatelessWidget {
  const _MetricPickerErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.xl),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Не удалось загрузить показатели',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Попробуйте обновить список через несколько секунд.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyButton(
                  label: 'Повторить',
                  onPressed: onRetry,
                  variant: PawlyButtonVariant.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _metricSubtitle(Metric metric) {
  final kind = _metricKindLabel(metric.inputKind);
  final unit = formatDisplayUnitCode(metric.unitCode).isEmpty
      ? 'без единиц'
      : formatDisplayUnitCode(metric.unitCode);
  final hasRange = metric.minValue != null || metric.maxValue != null;
  final range =
      hasRange ? ' · ${_formatRange(metric.minValue, metric.maxValue)}' : '';
  if (metric.inputKind == 'BOOLEAN') {
    return kind;
  }
  return '$kind · $unit$range';
}

String _metricKindLabel(String inputKind) {
  return switch (inputKind) {
    'NUMERIC' => 'Число',
    'SCALE' => 'Шкала',
    'BOOLEAN' => 'Да / Нет',
    _ => inputKind,
  };
}

String _formatRange(double? minValue, double? maxValue) {
  final min = minValue == null
      ? '...'
      : (minValue % 1 == 0
          ? minValue.toStringAsFixed(0)
          : minValue.toStringAsFixed(1));
  final max = maxValue == null
      ? '...'
      : (maxValue % 1 == 0
          ? maxValue.toStringAsFixed(0)
          : maxValue.toStringAsFixed(1));
  return '$min-$max';
}
