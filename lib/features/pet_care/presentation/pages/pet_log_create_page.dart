import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import 'pet_log_type_picker_page.dart';
import '../providers/health_controllers.dart';

class PetLogCreatePage extends ConsumerStatefulWidget {
  const PetLogCreatePage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetLogCreatePage> createState() => _PetLogCreatePageState();
}

class _PetLogCreatePageState extends ConsumerState<PetLogCreatePage> {
  late final TextEditingController _descriptionController;
  final Map<String, TextEditingController> _metricControllers =
      <String, TextEditingController>{};
  DateTime _occurredAt = DateTime.now();
  String? _selectedTypeId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    for (final controller in _metricControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bootstrapAsync = ref.watch(
      petLogComposerBootstrapProvider(widget.petId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Новая запись')),
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _CreateLogErrorView(
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
    final allTypes = _allTypes(bootstrap);
    final selectedType = _selectedType(allTypes);
    final canCreate = bootstrap.permissions.logWrite && !_isSubmitting;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        PawlyCard(
          onTap: canCreate ? _openTypePicker : null,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Тип записи',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    Text(
                      selectedType == null
                          ? 'Без типа'
                          : '${selectedType.name} · ${_scopeLabel(selectedType.scope)}',
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    Text(
                      selectedType == null
                          ? 'Можно оставить запись без типа'
                          : _typeMetricsLabel(selectedType),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.md),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_rounded),
          title: const Text('Дата и время события'),
          subtitle: Text(_formatOccurredAt(_occurredAt)),
          trailing: TextButton(
            onPressed: canCreate ? _pickOccurredAt : null,
            child: const Text('Изменить'),
          ),
        ),
        const SizedBox(height: PawlySpacing.sm),
        PawlyTextField(
          controller: _descriptionController,
          label: 'Описание',
          hintText: 'Что произошло',
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          enabled: canCreate,
        ),
        if (selectedType != null && selectedType.metricRequirements.isNotEmpty)
          ...<Widget>[
            const SizedBox(height: PawlySpacing.lg),
            Text(
              'Метрики',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            ...selectedType.metricRequirements.map(
              (requirement) => Padding(
                padding: const EdgeInsets.only(bottom: PawlySpacing.md),
                child: PawlyTextField(
                  controller: _controllerForMetric(requirement.metricId),
                  label: requirement.isRequired
                      ? '${requirement.metricName} *'
                      : requirement.metricName,
                  hintText: _metricHint(requirement),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  enabled: canCreate,
                ),
              ),
            ),
          ],
        if (!bootstrap.permissions.logWrite) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const PawlyCard(
            child: Text('У вас нет прав на создание записей для этого питомца.'),
          ),
        ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: _isSubmitting ? 'Сохраняем...' : 'Сохранить запись',
          onPressed: canCreate ? () => _submit(bootstrap) : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  List<LogType> _allTypes(LogComposerBootstrapResponse bootstrap) {
    final result = <LogType>[];
    final seenIds = <String>{};

    for (final type in <LogType>[
      ...bootstrap.recentLogTypes,
      ...bootstrap.systemLogTypes,
      ...bootstrap.customLogTypes,
    ]) {
      if (seenIds.add(type.id)) {
        result.add(type);
      }
    }

    return result;
  }

  LogType? _selectedType(List<LogType> allTypes) {
    for (final type in allTypes) {
      if (type.id == _selectedTypeId) {
        return type;
      }
    }
    return null;
  }

  TextEditingController _controllerForMetric(String metricId) {
    return _metricControllers.putIfAbsent(metricId, TextEditingController.new);
  }

  Future<void> _pickOccurredAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    if (time == null) {
      return;
    }

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _openTypePicker() async {
    final selectedTypeId = await context.pushNamed<String>(
      'petLogTypePicker',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (selectedTypeId == null || !mounted) {
      return;
    }

    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
    await ref.read(petLogComposerBootstrapProvider(widget.petId).future);
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedTypeId = selectedTypeId == noLogTypeSelectionId
          ? null
          : selectedTypeId;
    });
  }

  Future<void> _submit(LogComposerBootstrapResponse bootstrap) async {
    final allTypes = _allTypes(bootstrap);
    final selectedType = _selectedType(allTypes);
    final metricInputs = <LogMetricInput>[];

    for (final requirement in selectedType?.metricRequirements ?? const []) {
      final rawValue = _controllerForMetric(requirement.metricId).text.trim();
      if (rawValue.isEmpty) {
        if (requirement.isRequired) {
          _showError('Заполни метрику "${requirement.metricName}".');
          return;
        }
        continue;
      }

      final value = double.tryParse(rawValue.replaceAll(',', '.'));
      if (value == null) {
        _showError('Метрика "${requirement.metricName}" должна быть числом.');
        return;
      }

      metricInputs.add(
        LogMetricInput(metricId: requirement.metricId, valueNum: value),
      );
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(healthRepositoryProvider).createLog(
            widget.petId,
            input: UpsertLogInput(
              occurredAtIso: _occurredAt.toUtc().toIso8601String(),
              logTypeId: _selectedTypeId,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              metricValues: metricInputs,
            ),
          );

      ref.invalidate(petLogsControllerProvider(widget.petId));

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось сохранить запись.',
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

class _CreateLogErrorView extends StatelessWidget {
  const _CreateLogErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось подготовить форму записи.'),
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

String _metricHint(LogTypeMetricRequirement requirement) {
  final parts = <String>[];
  if (requirement.unitCode != null && requirement.unitCode!.isNotEmpty) {
    parts.add(requirement.unitCode!);
  }
  if (requirement.minValue != null || requirement.maxValue != null) {
    final min = requirement.minValue?.toStringAsFixed(0) ?? '...';
    final max = requirement.maxValue?.toStringAsFixed(0) ?? '...';
    parts.add('$min-$max');
  }
  return parts.isEmpty ? 'Введите значение' : parts.join(' · ');
}

String _formatOccurredAt(DateTime value) {
  final day = value.day.toString().padLeft(2, '0');
  final month = value.month.toString().padLeft(2, '0');
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$day.$month.${value.year} $hour:$minute';
}

String _scopeLabel(String scope) {
  return scope == 'SYSTEM' ? 'Системный' : 'Мой';
}

String _typeMetricsLabel(LogType type) {
  if (type.metricRequirements.isEmpty) {
    return 'Метрики не заданы';
  }
  final metrics = type.metricRequirements
      .map((metric) => metric.metricName)
      .join(', ');
  return 'Метрики: $metrics';
}
