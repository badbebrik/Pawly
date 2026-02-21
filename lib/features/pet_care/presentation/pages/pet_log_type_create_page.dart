import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
        if (bootstrap.systemMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          _MetricSelectionSection(
            title: 'Системные метрики',
            metrics: bootstrap.systemMetrics,
            selectedMetrics: _selectedMetrics,
            enabled: canSubmit,
            onChanged: _setMetricSelected,
            onRequiredChanged: _setMetricRequired,
          ),
        ],
        if (bootstrap.customMetrics.isNotEmpty) ...<Widget>[
          const SizedBox(height: PawlySpacing.md),
          _MetricSelectionSection(
            title: 'Мои метрики',
            metrics: bootstrap.customMetrics,
            selectedMetrics: _selectedMetrics,
            enabled: canSubmit,
            onChanged: _setMetricSelected,
            onRequiredChanged: _setMetricRequired,
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

  void _setMetricSelected(String metricId, bool selected) {
    setState(() {
      if (!selected) {
        _selectedMetrics.remove(metricId);
      } else {
        _selectedMetrics.putIfAbsent(metricId, () => false);
      }
    });
  }

  void _setMetricRequired(String metricId, bool isRequired) {
    setState(() {
      _selectedMetrics[metricId] = isRequired;
    });
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _MetricSelectionSection extends StatelessWidget {
  const _MetricSelectionSection({
    required this.title,
    required this.metrics,
    required this.selectedMetrics,
    required this.enabled,
    required this.onChanged,
    required this.onRequiredChanged,
  });

  final String title;
  final List<Metric> metrics;
  final Map<String, bool> selectedMetrics;
  final bool enabled;
  final void Function(String metricId, bool selected) onChanged;
  final void Function(String metricId, bool isRequired) onRequiredChanged;

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      child: Column(
        children: metrics.map((metric) {
          final isSelected = selectedMetrics.containsKey(metric.id);
          final isRequired = selectedMetrics[metric.id] ?? false;

          return Padding(
            padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
            child: Column(
              children: <Widget>[
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isSelected,
                  onChanged: enabled
                      ? (value) => onChanged(metric.id, value ?? false)
                      : null,
                  title: Text(metric.name),
                  subtitle: Text(_metricSubtitle(metric)),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
                if (isSelected)
                  SwitchListTile(
                    contentPadding: const EdgeInsets.only(
                      left: PawlySpacing.md,
                    ),
                    value: isRequired,
                    onChanged: enabled
                        ? (value) => onRequiredChanged(metric.id, value)
                        : null,
                    title: const Text('Обязательная метрика'),
                  ),
              ],
            ),
          );
        }).toList(growable: false),
      ),
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

String _metricSubtitle(Metric metric) {
  final parts = <String>[metric.inputKind];
  if (metric.unitCode != null && metric.unitCode!.isNotEmpty) {
    parts.add(metric.unitCode!);
  }
  return parts.join(' · ');
}
