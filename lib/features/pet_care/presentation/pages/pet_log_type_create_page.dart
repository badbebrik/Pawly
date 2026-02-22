import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import '../providers/health_controllers.dart';

class PetLogTypeCreatePage extends ConsumerStatefulWidget {
  const PetLogTypeCreatePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetLogTypeCreatePage> createState() =>
      _PetLogTypeCreatePageState();
}

class _PetLogTypeCreatePageState extends ConsumerState<PetLogTypeCreatePage> {
  late final TextEditingController _nameController;
  final Map<String, bool> _selectedMetrics = <String, bool>{};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Новый тип записи')),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _TypeCreateErrorView(
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
    final canSubmit = bootstrap.permissions.logWrite && !_isSubmitting;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        PawlyTextField(
          controller: _nameController,
          label: 'Название типа',
          hintText: 'Например, Контроль веса дома',
          enabled: canSubmit,
          textCapitalization: TextCapitalization.sentences,
        ),
        const SizedBox(height: PawlySpacing.lg),
        Text(
          'Метрики',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: PawlySpacing.xs),
        Text(
          'Выбери, какие метрики будут доступны в этом типе записи.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyButton(
          label: 'Выбрать метрику',
          onPressed: canSubmit ? _openMetricPicker : null,
          variant: PawlyButtonVariant.secondary,
          icon: Icons.add_rounded,
        ),
        if (_selectedMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          ..._selectedMetricEntries(bootstrap).map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: _SelectedMetricCard(
                metric: entry.metric,
                isRequired: entry.isRequired,
                enabled: canSubmit,
                onRequiredChanged: (value) =>
                    _setMetricRequired(entry.metric.id, value),
                onRemove: () => _removeMetric(entry.metric.id),
              ),
            ),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: _isSubmitting ? 'Сохраняем...' : 'Создать тип',
          onPressed: canSubmit ? _submit : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  void _setMetricRequired(String metricId, bool isRequired) {
    setState(() {
      _selectedMetrics[metricId] = isRequired;
    });
  }

  void _removeMetric(String metricId) {
    setState(() {
      _selectedMetrics.remove(metricId);
    });
  }

  List<_SelectedMetricEntry> _selectedMetricEntries(
    LogComposerBootstrapResponse bootstrap,
  ) {
    final allMetrics = <String, Metric>{
      for (final metric in <Metric>[
        ...bootstrap.systemMetrics,
        ...bootstrap.customMetrics,
      ])
        metric.id: metric,
    };

    return _selectedMetrics.entries
        .map((entry) {
          final metric = allMetrics[entry.key];
          if (metric == null) {
            return null;
          }
          return _SelectedMetricEntry(metric: metric, isRequired: entry.value);
        })
        .whereType<_SelectedMetricEntry>()
        .toList(growable: false);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Укажи название типа.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final type = await ref.read(healthRepositoryProvider).createLogType(
            widget.petId,
            input: CreateLogTypeInput(
              name: name,
              metricRequirements: _selectedMetrics.entries
                  .map(
                    (entry) => LogTypeMetricRequirementInput(
                      metricId: entry.key,
                      isRequired: entry.value,
                    ),
                  )
                  .toList(growable: false),
            ),
          );
      ref.invalidate(petLogComposerBootstrapProvider(widget.petId));

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(type.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось создать тип записи.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _openMetricPicker() async {
    final selectedMetricId = await context.pushNamed<String>(
      'petMetricPicker',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (selectedMetricId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    if (!mounted) {
      return;
    }

    setState(() {
      _selectedMetrics.putIfAbsent(selectedMetricId, () => false);
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _TypeCreateErrorView extends StatelessWidget {
  const _TypeCreateErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось подготовить создание типа.'),
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

class _SelectedMetricEntry {
  const _SelectedMetricEntry({
    required this.metric,
    required this.isRequired,
  });

  final Metric metric;
  final bool isRequired;
}

class _SelectedMetricCard extends StatelessWidget {
  const _SelectedMetricCard({
    required this.metric,
    required this.isRequired,
    required this.enabled,
    required this.onRequiredChanged,
    required this.onRemove,
  });

  final Metric metric;
  final bool isRequired;
  final bool enabled;
  final ValueChanged<bool> onRequiredChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      trailing: IconButton(
        onPressed: enabled ? onRemove : null,
        icon: const Icon(Icons.close_rounded),
      ),
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
          const SizedBox(height: PawlySpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: isRequired,
            onChanged: enabled ? onRequiredChanged : null,
            title: const Text('Обязательная метрика'),
          ),
        ],
      ),
    );
  }
}

String _metricSubtitle(Metric metric) {
  final kind = metric.inputKind == 'NUMERIC' ? 'Число' : 'Шкала';
  final unit = metric.unitCode == null || metric.unitCode!.isEmpty
      ? 'без единиц'
      : metric.unitCode!;
  final hasRange = metric.minValue != null || metric.maxValue != null;
  final range = hasRange
      ? ' · ${_formatRange(metric.minValue, metric.maxValue)}'
      : '';
  return '$kind · $unit$range';
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
