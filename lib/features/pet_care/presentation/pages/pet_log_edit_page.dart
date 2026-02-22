import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import 'pet_log_type_picker_page.dart';
import '../providers/health_controllers.dart';

class PetLogEditPage extends ConsumerStatefulWidget {
  const PetLogEditPage({
    required this.petId,
    required this.logId,
    super.key,
  });

  final String petId;
  final String logId;

  @override
  ConsumerState<PetLogEditPage> createState() => _PetLogEditPageState();
}

class _PetLogEditPageState extends ConsumerState<PetLogEditPage> {
  late final TextEditingController _descriptionController;
  final Map<String, TextEditingController> _metricControllers =
      <String, TextEditingController>{};
  DateTime _occurredAt = DateTime.now();
  String? _selectedTypeId;
  bool _isSubmitting = false;
  bool _didPopulate = false;

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
    final logAsync = ref.watch(
      petLogDetailsControllerProvider(
        PetLogRef(petId: widget.petId, logId: widget.logId),
      ),
    );
    final bootstrap = bootstrapAsync.asData?.value;
    final entry = logAsync.asData?.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Редактировать запись')),
      body: bootstrap != null && entry != null
          ? _buildContent(context, bootstrap, entry)
          : (bootstrapAsync.hasError || logAsync.hasError)
              ? _EditLogErrorView(
                  onRetry: () {
                    ref.invalidate(petLogComposerBootstrapProvider(widget.petId));
                    ref
                        .read(
                          petLogDetailsControllerProvider(
                            PetLogRef(petId: widget.petId, logId: widget.logId),
                          ).notifier,
                        )
                        .reload();
                  },
                )
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildContent(
    BuildContext context,
    LogComposerBootstrapResponse bootstrap,
    LogEntry log,
  ) {
    _populateFromLog(log);
    final allTypes = _allTypes(bootstrap);
    final selectedType = _selectedType(allTypes);
    final canEdit = bootstrap.permissions.logWrite && log.canEdit && !_isSubmitting;

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        if (!log.canEdit)
          const Padding(
            padding: EdgeInsets.only(bottom: PawlySpacing.md),
            child: PawlyCard(
              child: Text('Эту запись нельзя редактировать.'),
            ),
          ),
        PawlyCard(
          onTap: canEdit ? _openTypePicker : null,
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
            onPressed: canEdit ? _pickOccurredAt : null,
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
          enabled: canEdit,
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
                  enabled: canEdit,
                ),
              ),
            ),
          ],
        const SizedBox(height: PawlySpacing.lg),
        PawlyButton(
          label: _isSubmitting ? 'Сохраняем...' : 'Сохранить изменения',
          onPressed: canEdit ? () => _submit(log, bootstrap) : null,
          icon: Icons.check_rounded,
        ),
      ],
    );
  }

  void _populateFromLog(LogEntry log) {
    if (_didPopulate) {
      return;
    }
    _didPopulate = true;
    _selectedTypeId = log.logTypeId;
    _occurredAt = log.occurredAt ?? DateTime.now();
    _descriptionController.text = log.description;
    for (final metric in log.metricValues) {
      _controllerForMetric(metric.metricId).text = metric.valueNum % 1 == 0
          ? metric.valueNum.toStringAsFixed(0)
          : metric.valueNum.toString();
    }
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

  Future<void> _submit(
    LogEntry log,
    LogComposerBootstrapResponse bootstrap,
  ) async {
    final selectedType = _selectedType(_allTypes(bootstrap));
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
      await ref.read(healthRepositoryProvider).updateLog(
            widget.petId,
            widget.logId,
            input: UpsertLogInput(
              occurredAtIso: _occurredAt.toUtc().toIso8601String(),
              logTypeId: _selectedTypeId,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),
              metricValues: metricInputs,
              rowVersion: log.rowVersion,
            ),
          );
      ref.invalidate(petLogsControllerProvider(widget.petId));
      ref.invalidate(
        petLogDetailsControllerProvider(
          PetLogRef(petId: widget.petId, logId: widget.logId),
        ),
      );
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
            : 'Не удалось сохранить изменения.',
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

class _EditLogErrorView extends StatelessWidget {
  const _EditLogErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось подготовить редактирование записи.'),
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
