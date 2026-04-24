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
import '../utils/log_attachment_limits.dart';
import '../utils/metric_unit_formatter.dart';
import '../widgets/health_attachments_field.dart';
import 'pet_log_type_picker_page.dart';

class PetLogCreatePage extends ConsumerStatefulWidget {
  const PetLogCreatePage({
    required this.petId,
    this.initialLogTypeId,
    super.key,
  });

  final String petId;
  final String? initialLogTypeId;

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
    _selectedTypeId = widget.initialLogTypeId;
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

    return PawlyScreenScaffold(
      title: 'Новая запись',
      body: bootstrapAsync.when(
        data: (bootstrap) => _buildContent(context, bootstrap),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _CreateLogErrorView(
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
    final allTypes = _allTypes(bootstrap);
    final selectedType = _selectedType(allTypes);
    final canCreate = bootstrap.permissions.logWrite &&
        !_isSubmitting &&
        !_isUploadingAttachments;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _LogTypeSelectorCard(
          onTap: canCreate ? _openTypePicker : null,
          title: selectedType == null ? 'Без типа' : selectedType.name,
          subtitle: selectedType == null
              ? 'Можно оставить запись без типа'
              : '${_scopeLabel(selectedType.scope)} · ${_typeMetricsLabel(selectedType)}',
        ),
        const SizedBox(height: PawlySpacing.md),
        if (selectedType != null &&
            selectedType.metricRequirements.isNotEmpty) ...<Widget>[
          _LogFormSection(
            title: 'Показатели',
            child: Column(
              children: selectedType.metricRequirements
                  .map(
                    (requirement) => Padding(
                      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
                      child: _buildMetricField(requirement, canCreate),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
        ],
        _LogDateTile(
          value: _formatOccurredAt(_occurredAt),
          onTap: canCreate ? _pickOccurredAt : null,
        ),
        const SizedBox(height: PawlySpacing.md),
        _LogFormSection(
          title: 'Описание',
          child: PawlyTextField(
            controller: _descriptionController,
            hintText: 'Что произошло',
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            enabled: canCreate,
          ),
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
          onRename: _renameAttachment,
        ),
        if (!bootstrap.permissions.logWrite) ...<Widget>[
          const SizedBox(height: PawlySpacing.lg),
          const _LogFormInlineMessage(
            title: 'Нет доступа',
            message: 'У вас нет прав на создание записей для этого питомца.',
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

  Widget _buildMetricField(LogTypeMetricRequirement requirement, bool enabled) {
    final label = _metricLabel(requirement);
    if (requirement.inputKind == 'BOOLEAN') {
      final selectedValue = _booleanMetricValues[requirement.metricId];
      return _MetricFieldShell(
        title: label,
        subtitle: _metricHint(requirement),
        child: Wrap(
          spacing: PawlySpacing.xs,
          runSpacing: PawlySpacing.xs,
          children: <Widget>[
            _LogBooleanChoice(
              label: 'Да',
              isSelected: selectedValue == true,
              enabled: enabled,
              onTap: () {
                setState(() {
                  _booleanMetricValues[requirement.metricId] = true;
                });
              },
            ),
            _LogBooleanChoice(
              label: 'Нет',
              isSelected: selectedValue == false,
              enabled: enabled,
              onTap: () {
                setState(() {
                  _booleanMetricValues[requirement.metricId] = false;
                });
              },
            ),
          ],
        ),
      );
    }

    return _MetricFieldShell(
      title: label,
      subtitle: _metricHint(requirement),
      child: TextFormField(
        controller: _controllerForMetric(requirement.metricId),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        enabled: enabled,
        decoration: InputDecoration(
          hintText: _metricPlaceholder(requirement),
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
            _showError('Заполните показатель "${_metricName(requirement)}".');
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
          _showError('Заполните показатель "${_metricName(requirement)}".');
          return;
        }
        continue;
      }

      final value = double.tryParse(rawValue.replaceAll(',', '.'));
      if (value == null) {
        _showError(
          'Показатель "${_metricName(requirement)}" должен быть числом.',
        );
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
              attachments: _attachmentInputs(),
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

    try {
      await validatePlatformLogAttachments(
        existingAttachments: _attachments,
        files: files,
      );
    } catch (error) {
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось добавить файлы.',
      );
      return;
    }

    setState(() {
      _isUploadingAttachments = true;
    });

    try {
      final uploaded = await ref
          .read(healthFileUploadServiceProvider)
          .uploadFiles(widget.petId, files: files, entityType: 'LOG');
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

  Future<void> _pickAndUploadFromGallery() async {
    final files = await ref
        .read(mediaPickerServiceProvider)
        .pickAttachmentImagesFromGallery();
    if (files.isEmpty || !mounted) {
      return;
    }
    try {
      await validateXFileLogAttachments(
        existingAttachments: _attachments,
        files: files,
      );
    } catch (error) {
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось добавить фото.',
      );
      return;
    }
    await _uploadPickedImages(files);
  }

  Future<void> _pickAndUploadFromCamera() async {
    final file =
        await ref.read(mediaPickerServiceProvider).takeAttachmentPhoto();
    if (file == null || !mounted) {
      return;
    }
    try {
      await validateXFileLogAttachments(
        existingAttachments: _attachments,
        files: <XFile>[file],
      );
    } catch (error) {
      _showError(
        error is StateError
            ? error.message.toString()
            : 'Не удалось добавить фото.',
      );
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
          .uploadXFiles(widget.petId, files: files, entityType: 'LOG');
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

  void _renameAttachment(String fileId, String fileName) {
    setState(() {
      final index = _attachments.indexWhere(
        (attachment) => attachment.fileId == fileId,
      );
      if (index >= 0) {
        _attachments[index] = _attachments[index].copyWith(fileName: fileName);
      }
    });
  }

  List<AttachmentInput> _attachmentInputs() {
    return _attachments
        .map(
          (attachment) => AttachmentInput(
            fileId: attachment.fileId,
            fileName: attachment.fileName,
          ),
        )
        .toList(growable: false);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LogTypeSelectorCard extends StatelessWidget {
  const _LogTypeSelectorCard({
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: InkWell(
        onTap: onTap,
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
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

class _LogFormSection extends StatelessWidget {
  const _LogFormSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetricFieldShell extends StatelessWidget {
  const _MetricFieldShell({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.56),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.xxs),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _LogBooleanChoice extends StatelessWidget {
  const _LogBooleanChoice({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.84),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.xs,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LogDateTile extends StatelessWidget {
  const _LogDateTile({required this.value, this.onTap});

  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: InkWell(
        onTap: onTap,
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
            children: <Widget>[
              Icon(Icons.calendar_today_rounded, color: colorScheme.primary),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Дата и время события',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      value,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Изменить',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: onTap == null
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.primary,
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

class _LogFormInlineMessage extends StatelessWidget {
  const _LogFormInlineMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
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
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateLogErrorView extends StatelessWidget {
  const _CreateLogErrorView({required this.onRetry});

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
                  'Не удалось подготовить форму записи',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Попробуйте открыть форму снова через несколько секунд.',
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

String _metricHint(LogTypeMetricRequirement requirement) {
  if (requirement.inputKind == 'BOOLEAN') {
    return 'Выберите Да или Нет';
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
  return 'Показатель';
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

String _typeMetricsLabel(LogType type) {
  if (type.metricRequirements.isEmpty) {
    return 'Показатели не заданы';
  }
  final metrics = type.metricRequirements.map(_typeMetricSummary).join(', ');
  return 'Показатели: $metrics';
}

String _scopeLabel(String scope) {
  return scope == 'SYSTEM' ? 'Системный' : 'Мой';
}
