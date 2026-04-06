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
import 'pet_log_type_picker_page.dart';
import '../providers/health_controllers.dart';
import '../widgets/health_attachments_field.dart';

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
  final Map<String, bool?> _booleanMetricValues = <String, bool?>{};
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];
  DateTime _occurredAt = DateTime.now();
  String? _selectedTypeId;
  bool _isSubmitting = false;
  bool _isUploadingAttachments = false;

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
    final canCreate = bootstrap.permissions.logWrite &&
        !_isSubmitting &&
        !_isUploadingAttachments;

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
        const SizedBox(height: PawlySpacing.lg),
        HealthAttachmentsField(
          attachments: _attachments,
          isUploading: _isUploadingAttachments,
          enabled: bootstrap.permissions.logWrite && !_isSubmitting,
          onAddFiles: _pickAndUploadAttachments,
          onAddFromGallery: _pickAndUploadFromGallery,
          onAddFromCamera: _pickAndUploadFromCamera,
          onRemove: _removeAttachment,
        ),
        if (selectedType != null &&
            selectedType.metricRequirements.isNotEmpty) ...<Widget>[
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
              child: _buildMetricField(requirement, canCreate),
            ),
          ),
        ],
        if (!bootstrap.permissions.logWrite) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const PawlyCard(
            child:
                Text('У вас нет прав на создание записей для этого питомца.'),
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

  Widget _buildMetricField(
    LogTypeMetricRequirement requirement,
    bool enabled,
  ) {
    final label = _metricLabel(requirement);
    if (requirement.inputKind == 'BOOLEAN') {
      return DropdownButtonFormField<bool>(
        initialValue: _booleanMetricValues[requirement.metricId],
        decoration: InputDecoration(
          labelText: label,
          helperText: _metricHint(requirement),
        ),
        items: const <DropdownMenuItem<bool>>[
          DropdownMenuItem<bool>(value: true, child: Text('Да')),
          DropdownMenuItem<bool>(value: false, child: Text('Нет')),
        ],
        onChanged: enabled
            ? (value) {
                setState(() {
                  _booleanMetricValues[requirement.metricId] = value;
                });
              }
            : null,
      );
    }

    return PawlyTextField(
      controller: _controllerForMetric(requirement.metricId),
      label: label,
      hintText: _metricHint(requirement),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      enabled: enabled,
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

  Future<void> _submit(LogComposerBootstrapResponse bootstrap) async {
    if (_isUploadingAttachments) {
      _showError('Дождитесь окончания загрузки файлов.');
      return;
    }

    final allTypes = _allTypes(bootstrap);
    final selectedType = _selectedType(allTypes);
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
      await ref.read(healthRepositoryProvider).createLog(
            widget.petId,
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
            ),
          );

      ref.invalidate(petLogsControllerProvider(widget.petId));
      ref.invalidate(petAnalyticsMetricsProvider);

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
  if (requirement.inputKind == 'BOOLEAN') {
    return 'Выбери Да или Нет';
  }
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

String _typeMetricSummary(LogTypeMetricRequirement requirement) {
  final name = _metricName(requirement);
  final kind = _metricKindLabel(requirement.inputKind);
  return '$name ($kind)';
}

String _typeMetricsLabel(LogType type) {
  if (type.metricRequirements.isEmpty) {
    return 'Метрики не заданы';
  }
  final metrics = type.metricRequirements.map(_typeMetricSummary).join(', ');
  return 'Метрики: $metrics';
}

String _scopeLabel(String scope) {
  return scope == 'SYSTEM' ? 'Системный' : 'Мой';
}
