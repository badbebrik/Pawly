import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../providers/health_controllers.dart';

class PetMetricPickerPage extends ConsumerStatefulWidget {
  const PetMetricPickerPage({
    required this.petId,
    super.key,
  });

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

    return Scaffold(
      appBar: AppBar(title: const Text('Выбрать метрику')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateMetric,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Новая метрика'),
      ),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MetricPickerErrorView(
          onRetry: () => ref.invalidate(
            petLogComposerBootstrapProvider(widget.petId),
          ),
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
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        PawlyTextField(
          controller: _searchController,
          hintText: 'Поиск по метрикам',
          prefixIcon: const Icon(Icons.search_rounded),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        if (systemMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
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
  const _MetricPickerSection({
    required this.title,
    required this.metrics,
  });

  final String title;
  final List<Metric> metrics;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
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
    return PawlyCard(
      onTap: () => Navigator.of(context).pop(metric.id),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  metric.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  _metricSubtitle(metric),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Text(
            metric.scope == 'SYSTEM' ? 'Системный' : 'Мой',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricPickerErrorView extends StatelessWidget {
  const _MetricPickerErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить метрики.'),
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

String _metricSubtitle(Metric metric) {
  final kind = _metricKindLabel(metric.inputKind);
  final unit = metric.unitCode == null || metric.unitCode!.isEmpty
      ? 'без единиц'
      : metric.unitCode!;
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
