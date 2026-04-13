import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/network/models/log_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_file_upload_service.dart';
import '../../data/health_repository_models.dart';
import '../models/attachment_draft_item.dart';
import '../providers/health_controllers.dart';
import '../utils/metric_unit_formatter.dart';
import '../widgets/health_attachments_field.dart';
import 'pet_log_type_picker_page.dart';

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
  final Map<String, bool?> _booleanMetricValues = <String, bool?>{};
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];
  DateTime _occurredAt = DateTime.now();
  String? _selectedTypeId;
  bool _isSubmitting = false;
  bool _isUploadingAttachments = false;
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
                    ref.invalidate(
                        petLogComposerBootstrapProvider(widget.petId));
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
    final canEdit =
        bootstrap.permissions.logWrite &&
        log.canEdit &&
        !_isSubmitting &&
        !_isUploadingAttachments;

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
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
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
        if (selectedType != null &&
            selectedType.metricRequirements.isNotEmpty) ...<Widget>[
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
              child: _buildMetricField(requirement, canEdit),
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
        ],
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
        const SizedBox(height: PawlySpacing.lg),
        HealthAttachmentsField(
          attachments: _attachments,
          isUploading: _isUploadingAttachments,
          enabled:
              bootstrap.permissions.logWrite && log.canEdit && !_isSubmitting,
          onAddFiles: _pickAndUploadAttachments,
          onAddFromGallery: _pickAndUploadFromGallery,
          onAddFromCamera: _pickAndUploadFromCamera,
          onRemove: _removeAttachment,
        ),
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
    _occurredAt = (log.occurredAt ?? DateTime.now()).toLocal();
    _descriptionController.text = log.description;
    _attachments
      ..clear()
      ..addAll(log.attachments.map(AttachmentDraftItem.fromLogAttachment));
    for (final metric in log.metricValues) {
      if (metric.inputKind == 'BOOLEAN') {
        _booleanMetricValues[metric.metricId] = metric.valueNum != 0;
      } else {
        _controllerForMetric(metric.metricId).text = metric.valueNum % 1 == 0
            ? metric.valueNum.toStringAsFixed(0)
            : metric.valueNum.toString();
      }
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

  Widget _buildMetricField(
    LogTypeMetricRequirement requirement,
    bool enabled,
  ) {
    final label = _metricLabel(requirement);
    if (requirement.inputKind == 'BOOLEAN') {
      final selectedValue = _booleanMetricValues[requirement.metricId];
      return PawlyCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              _metricHint(requirement),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            Wrap(
              spacing: PawlySpacing.xs,
              runSpacing: PawlySpacing.xs,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Да'),
                  selected: selectedValue == true,
                  onSelected: enabled
                      ? (_) {
                          setState(() {
                            _booleanMetricValues[requirement.metricId] = true;
                          });
                        }
                      : null,
                ),
                ChoiceChip(
                  label: const Text('Нет'),
                  selected: selectedValue == false,
                  onSelected: enabled
                      ? (_) {
                          setState(() {
                            _booleanMetricValues[requirement.metricId] = false;
                          });
                        }
                      : null,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return TextFormField(
      controller: _controllerForMetric(requirement.metricId),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        hintText: _metricPlaceholder(requirement),
        helperText: _metricHint(requirement),
        suffixIcon: (requirement.unitCode ?? '').trim().isEmpty
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    formatDisplayUnitCode(requirement.unitCode),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
      ),
    );
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
      _selectedTypeId =
          selectedTypeId == noLogTypeSelectionId ? null : selectedTypeId;
    });
  }

  Future<void> _submit(
    LogEntry log,
    LogComposerBootstrapResponse bootstrap,
  ) async {
    if (_isUploadingAttachments) {
      _showError('Дождитесь окончания загрузки файлов.');
      return;
    }

    final selectedType = _selectedType(_allTypes(bootstrap));
    final metricInputs = <LogMetricInput>[];

    for (final requirement in selectedType?.metricRequirements ?? const []) {
      if (requirement.inputKind == 'BOOLEAN') {
        final selectedValue = _booleanMetricValues[requirement.metricId];
        if (selectedValue == null) {
          if (requirement.isRequired) {
            _showError('Заполни метрику "${_metricName(requirement)}".');
            return;
          }
          continue;
        }
        metricInputs.add(
          LogMetricInput(
            metricId: requirement.metricId,
            valueNum: selectedValue ? 1 : 0,
          ),
        );
        continue;
      }

      final rawValue = _controllerForMetric(requirement.metricId).text.trim();
      if (rawValue.isEmpty) {
        if (requirement.isRequired) {
          _showError('Заполни метрику "${_metricName(requirement)}".');
          return;
        }
        continue;
      }
      final value = double.tryParse(rawValue.replaceAll(',', '.'));
      if (value == null) {
        _showError('Метрика "${_metricName(requirement)}" должна быть числом.');
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
              attachmentFileIds: _attachments
                  .map((attachment) => attachment.fileId)
                  .toList(growable: false),
              rowVersion: log.rowVersion,
            ),
          );
      ref.invalidate(petLogsControllerProvider(widget.petId));
      ref.invalidate(petAnalyticsMetricsProvider);
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

  Future<void> _pickAndUploadAttachments() async {
    final files = await ref.read(mediaPickerServiceProvider).pickFiles(
          allowedExtensions: HealthFileUploadService.supportedExtensions,
        );
    if (files.isEmpty || !mounted) {
      return;
    }

    setState(() {
      _isUploadingAttachments = true;
    });

    try {
      final uploaded = await ref
          .read(healthFileUploadServiceProvider)
          .uploadFiles(widget.petId, files: files);
      if (!mounted) {
        return;
      }
      setState(() {
        _attachments.addAll(
          uploaded.map(AttachmentDraftItem.fromUploaded),
        );
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось загрузить файлы.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachments = false;
        });
      }
    }
  }

  Future<void> _pickAndUploadFromGallery() async {
    final files = await ref.read(mediaPickerServiceProvider).pickGalleryImages();
    if (files.isEmpty || !mounted) {
      return;
    }
    await _uploadPickedImages(files);
  }

  Future<void> _pickAndUploadFromCamera() async {
    final file = await ref.read(mediaPickerServiceProvider).pickImage(
          source: ImageSource.camera,
        );
    if (file == null || !mounted) {
      return;
    }
    await _uploadPickedImages(<XFile>[file]);
  }

  Future<void> _uploadPickedImages(List<XFile> files) async {
    setState(() {
      _isUploadingAttachments = true;
    });

    try {
      final uploaded = await ref
          .read(healthFileUploadServiceProvider)
          .uploadXFiles(widget.petId, files: files);
      if (!mounted) {
        return;
      }
      setState(() {
        _attachments.addAll(uploaded.map(AttachmentDraftItem.fromUploaded));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось загрузить файлы.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAttachments = false;
        });
      }
    }
  }

  void _removeAttachment(String fileId) {
    setState(() {
      _attachments.removeWhere((attachment) => attachment.fileId == fileId);
    });
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
  if (requirement.inputKind == 'BOOLEAN') {
    return 'Выбери Да или Нет';
  }
  if (requirement.minValue != null || requirement.maxValue != null) {
    final min = _formatMetricBound(requirement.minValue) ?? '...';
    final max = _formatMetricBound(requirement.maxValue) ?? '...';
    return 'Допустимый диапазон: $min–$max';
  }
  final unit = formatDisplayUnitCode(requirement.unitCode);
  if (unit.isNotEmpty) {
    return 'Введите значение в $unit';
  }
  return 'Введите значение';
}

String _formatOccurredAt(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.${local.year} $hour:$minute';
}

String _metricLabel(LogTypeMetricRequirement requirement) {
  final name = _metricName(requirement);
  return requirement.isRequired ? '$name *' : name;
}

String _metricName(LogTypeMetricRequirement requirement) {
  final name = requirement.metricName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return 'Метрика';
}

String _metricKindLabel(String inputKind) {
  return switch (inputKind) {
    'NUMERIC' => 'Число',
    'SCALE' => 'Шкала',
    'BOOLEAN' => 'Да / Нет',
    _ => inputKind,
  };
}

String _metricPlaceholder(LogTypeMetricRequirement requirement) {
  return switch (requirement.inputKind) {
    'SCALE' => 'Например, 4',
    'NUMERIC' => 'Например, 4.2',
    _ => 'Введите значение',
  };
}

String? _formatMetricBound(double? value) {
  if (value == null) {
    return null;
  }
  return value % 1 == 0 ? value.toStringAsFixed(0) : value.toString();
}

String _typeMetricSummary(LogTypeMetricRequirement requirement) {
  final name = _metricName(requirement);
  final kind = _metricKindLabel(requirement.inputKind);
  return '$name ($kind)';
}

String _scopeLabel(String scope) {
  return scope == 'SYSTEM' ? 'Системный' : 'Мой';
}

String _typeMetricsLabel(LogType type) {
  if (type.metricRequirements.isEmpty) {
    return 'Метрики не заданы';
  }
  final metrics = type.metricRequirements.map(_typeMetricSummary).join(', ');
  return 'Метрики: $metrics';
}
