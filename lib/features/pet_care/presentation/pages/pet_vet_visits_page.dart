import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../core/network/models/log_models.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/attachment_launcher.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_file_upload_service.dart';
import '../../data/health_repository_models.dart';
import '../models/attachment_draft_item.dart';
import '../models/attachment_kind.dart';
import '../models/attachment_viewer_item.dart';
import '../providers/health_controllers.dart';
import '../providers/pet_health_home_controllers.dart';
import '../providers/pet_vet_visits_controller.dart';
import '../widgets/health_attachments_field.dart';

class PetVetVisitsPage extends ConsumerStatefulWidget {
  const PetVetVisitsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetVetVisitsPage> createState() => _PetVetVisitsPageState();
}

class _PetVetVisitsPageState extends ConsumerState<PetVetVisitsPage> {
  VetVisitBucket _selectedBucket = VetVisitBucket.upcoming;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(petVetVisitsControllerProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Ветеринарные визиты')),
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Новый визит'),
            )
          : null,
      body: stateAsync.when(
        data: (state) => _VetVisitsContent(
          petId: widget.petId,
          state: state,
          selectedBucket: _selectedBucket,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petVetVisitsControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petVetVisitsControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _VetVisitsErrorView(
          onRetry: () => ref
              .read(petVetVisitsControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petVetVisitsControllerProvider(widget.petId)).asData?.value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertVetVisitInput>(
      MaterialPageRoute<UpsertVetVisitInput>(
        builder: (context) => _VetVisitComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.vetVisitStatuses,
          allowedTypes: state.bootstrap.enums.vetVisitTypes,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .createVetVisit(
            input: input,
          );
      ref.invalidate(petHealthHomeProvider(widget.petId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Визит сохранен.')),
      );
      setState(
        () => _selectedBucket = input.status == 'PLANNED'
            ? VetVisitBucket.upcoming
            : VetVisitBucket.history,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _mutationErrorMessage(error, 'Не удалось сохранить визит.'))),
      );
    }
  }
}

class _VetVisitsContent extends StatelessWidget {
  const _VetVisitsContent({
    required this.petId,
    required this.state,
    required this.selectedBucket,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
  });

  final String petId;
  final PetVetVisitsState state;
  final VetVisitBucket selectedBucket;
  final ValueChanged<VetVisitBucket> onBucketChanged;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _VetVisitsNoAccessView(onRetry: onRetry);
    }

    final theme = Theme.of(context);
    final items = state.itemsFor(selectedBucket);

    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        Text(
          state.petName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: PawlySpacing.xxs),
        Text(
          state.canWrite
              ? 'Плановые и завершенные визиты к ветеринару'
              : 'Плановые и завершенные визиты к ветеринару · только просмотр',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Wrap(
          spacing: PawlySpacing.sm,
          runSpacing: PawlySpacing.sm,
          children: <Widget>[
            _VisitBucketChip(
              label: 'Предстоящие',
              count: state.upcomingItems.length,
              selected: selectedBucket == VetVisitBucket.upcoming,
              onTap: () => onBucketChanged(VetVisitBucket.upcoming),
            ),
            _VisitBucketChip(
              label: 'История',
              count: state.historyItems.length,
              selected: selectedBucket == VetVisitBucket.history,
              onTap: () => onBucketChanged(VetVisitBucket.history),
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.lg),
        if (items.isEmpty)
          PawlyCard(
            child: Text(
              selectedBucket == VetVisitBucket.upcoming
                  ? 'Предстоящих визитов пока нет.'
                  : 'История визитов пока пуста.',
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: _VetVisitListCard(
                petId: petId,
                item: item,
              ),
            ),
          ),
        if (state.nextCursorFor(selectedBucket) != null) ...<Widget>[
          const SizedBox(height: PawlySpacing.sm),
          PawlyButton(
            label: state.isLoadingMore(selectedBucket)
                ? 'Загружаем...'
                : 'Показать еще',
            onPressed: state.isLoadingMore(selectedBucket) ? null : onLoadMore,
            variant: PawlyButtonVariant.secondary,
          ),
        ],
      ],
    );
  }
}

class _VisitBucketChip extends StatelessWidget {
  const _VisitBucketChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(PawlyRadius.pill),
            border: Border.all(
              color: selected ? colorScheme.primary : colorScheme.outline,
            ),
          ),
          child: Text(
            '$label · $count',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: selected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}

class _VetVisitListCard extends StatelessWidget {
  const _VetVisitListCard({
    required this.petId,
    required this.item,
  });

  final String petId;
  final VetVisitCard item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PawlyCard(
      onTap: () => context.pushNamed(
        'petVetVisitDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'visitId': item.id,
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            _visitTypeLabel(item.visitType),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          PawlyBadge(
            label: _visitStatusLabel(item.status),
            tone: _visitStatusTone(item.status),
          ),
          if (_primaryDateLabel(item) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            _VisitInfoLine(
              icon: Icons.event_rounded,
              text: value,
            ),
          ],
          if (_nonEmpty(item.clinicName) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.xs),
            _VisitInfoLine(
              icon: Icons.local_hospital_rounded,
              text: value,
            ),
          ],
          if (_nonEmpty(item.vetName) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.xs),
            _VisitInfoLine(
              icon: Icons.person_outline_rounded,
              text: value,
            ),
          ],
          if (_nonEmpty(item.reasonText) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }

  String? _primaryDateLabel(VetVisitCard item) {
    final date = switch (item.status) {
      'COMPLETED' => item.completedAt ?? item.scheduledAt,
      'CANCELLED' => item.scheduledAt,
      _ => item.scheduledAt,
    };
    if (date == null) return null;

    final prefix = switch (item.status) {
      'COMPLETED' => 'Завершен',
      'CANCELLED' => 'Был запланирован',
      _ => 'Запланирован',
    };
    return '$prefix ${_formatDate(date)}';
  }
}

class _VisitInfoLine extends StatelessWidget {
  const _VisitInfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: PawlySpacing.xs),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}

class _VetVisitComposerSheet extends ConsumerStatefulWidget {
  const _VetVisitComposerSheet({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypes,
    this.initialVisit,
    this.title = 'Новый визит',
    this.submitLabel = 'Сохранить визит',
    this.showHeader = true,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<String> allowedTypes;
  final VetVisit? initialVisit;
  final String title;
  final String submitLabel;
  final bool showHeader;

  @override
  ConsumerState<_VetVisitComposerSheet> createState() =>
      _VetVisitComposerSheetState();
}

class _VetVisitComposerSheetState
    extends ConsumerState<_VetVisitComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _clinicController = TextEditingController();
  final _vetController = TextEditingController();
  final _reasonController = TextEditingController();
  final _resultController = TextEditingController();
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];
  final List<LogCard> _selectedLogs = <LogCard>[];

  late String _status;
  late String _visitType;
  DateTime? _scheduledAt;
  DateTime? _completedAt;
  bool _pushEnabled = true;
  int? _remindOffsetMinutes = 0;
  late bool _shouldSendReminder;
  bool _isUploadingAttachments = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialVisit;
    _status = initial?.status ??
        (widget.allowedStatuses.contains('PLANNED')
            ? 'PLANNED'
            : widget.allowedStatuses.first);
    _visitType = initial?.visitType ??
        (widget.allowedTypes.contains('CHECKUP')
            ? 'CHECKUP'
            : widget.allowedTypes.first);
    _clinicController.text = initial?.clinicName ?? '';
    _vetController.text = initial?.vetName ?? '';
    _reasonController.text = initial?.reasonText ?? '';
    _resultController.text = initial?.resultText ?? '';
    _scheduledAt = initial?.scheduledAt;
    _completedAt = initial?.completedAt;
    _shouldSendReminder = initial == null;
    _attachments.addAll(
      initial?.attachments.map(AttachmentDraftItem.fromHealthAttachment) ??
          const <AttachmentDraftItem>[],
    );
  }

  @override
  void dispose() {
    _clinicController.dispose();
    _vetController.dispose();
    _reasonController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.lg,
            0,
            PawlySpacing.lg,
            PawlySpacing.lg,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (widget.showHeader) ...<Widget>[
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: PawlySpacing.lg),
                ],
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: widget.allowedStatuses
                      .map(
                        (status) => ChoiceChip(
                          label: Text(_visitStatusLabel(status)),
                          selected: _status == status,
                          onSelected: (_) => setState(() => _status = status),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: PawlySpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _visitType,
                  decoration: const InputDecoration(labelText: 'Тип визита'),
                  items: widget.allowedTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(_visitTypeLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _visitType = value);
                  },
                ),
                const SizedBox(height: PawlySpacing.sm),
                _DateButton(
                  label: _scheduledAt == null
                      ? 'Дата визита'
                      : 'Дата визита: ${_formatDateTime(_scheduledAt!)}',
                  onTap: () async {
                    final picked = await _pickDateTime(
                      context,
                      initialDate: _scheduledAt ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _scheduledAt = picked);
                    }
                  },
                ),
                if (_status != 'PLANNED') ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  _DateButton(
                    label: _completedAt == null
                        ? 'Дата завершения'
                        : 'Дата завершения: ${_formatDateTime(_completedAt!)}',
                    onTap: () async {
                      final picked = await _pickDateTime(
                        context,
                        initialDate:
                            _completedAt ?? _scheduledAt ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _completedAt = picked);
                      }
                    },
                    secondary: true,
                  ),
                ],
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _clinicController,
                  label: 'Клиника',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _vetController,
                  label: 'Ветеринар',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _reasonController,
                  label: 'Причина визита',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (_status != 'PLANNED') ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  PawlyTextField(
                    controller: _resultController,
                    label: 'Результат визита',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ],
                const SizedBox(height: PawlySpacing.lg),
                HealthAttachmentsField(
                  attachments: _attachments,
                  isUploading: _isUploadingAttachments,
                  enabled: true,
                  onAddFiles: _pickAndUploadAttachments,
                  onAddFromGallery: _pickAndUploadFromGallery,
                  onAddFromCamera: _pickAndUploadFromCamera,
                  onRemove: _removeAttachment,
                ),
                if (_status == 'PLANNED') ...<Widget>[
                  const SizedBox(height: PawlySpacing.lg),
                  PawlyCard(
                    child: Column(
                      children: <Widget>[
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _pushEnabled,
                          onChanged: (value) {
                            setState(() {
                              _pushEnabled = value;
                              _shouldSendReminder = true;
                            });
                          },
                          title: const Text('Напоминание включено'),
                        ),
                        if (_pushEnabled) ...<Widget>[
                          const SizedBox(height: PawlySpacing.sm),
                          DropdownButtonFormField<int>(
                            initialValue: _remindOffsetMinutes ?? 0,
                            decoration: const InputDecoration(
                              labelText: 'Когда напомнить',
                            ),
                            items: const <DropdownMenuItem<int>>[
                              DropdownMenuItem<int>(
                                value: 0,
                                child: Text('В момент события'),
                              ),
                              DropdownMenuItem<int>(
                                value: 15,
                                child: Text('За 15 минут'),
                              ),
                              DropdownMenuItem<int>(
                                value: 30,
                                child: Text('За 30 минут'),
                              ),
                              DropdownMenuItem<int>(
                                value: 60,
                                child: Text('За 1 час'),
                              ),
                              DropdownMenuItem<int>(
                                value: 1440,
                                child: Text('За 1 день'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _remindOffsetMinutes = value;
                                _shouldSendReminder = true;
                              });
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (widget.initialVisit == null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.lg),
                  PawlyCard(
                    title: Text(
                      'Прикрепленные записи',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    footer: Align(
                      alignment: Alignment.centerLeft,
                      child: PawlyButton(
                        label: 'Прикрепить запись',
                        onPressed: _pickRelatedLog,
                        variant: PawlyButtonVariant.secondary,
                      ),
                    ),
                    child: _selectedLogs.isEmpty
                        ? const _AttachedLogsEmptyState()
                        : Column(
                            children: _selectedLogs
                                .map(
                                  (log) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.notes_rounded),
                                    title: Text(log.logTypeName ?? 'Запись'),
                                    subtitle: Text(_logCardSubtitle(log)),
                                    trailing: IconButton(
                                      onPressed: () =>
                                          _removeRelatedLog(log.id),
                                      icon: const Icon(Icons.close_rounded),
                                      tooltip: 'Убрать',
                                    ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                  ),
                ],
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: widget.submitLabel,
                  onPressed: _isUploadingAttachments ? null : _submit,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isUploadingAttachments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дождитесь окончания загрузки файлов.')),
      );
      return;
    }

    Navigator.of(context).pop(
      UpsertVetVisitInput(
        status: _status,
        visitType: _visitType,
        scheduledAtIso: _scheduledAt?.toIso8601String(),
        completedAtIso: _completedAt?.toIso8601String(),
        clinicName: _nonEmpty(_clinicController.text),
        vetName: _nonEmpty(_vetController.text),
        reasonText: _nonEmpty(_reasonController.text),
        resultText: _nonEmpty(_resultController.text),
        attachmentFileIds: _attachments
            .map((attachment) => attachment.fileId)
            .toList(growable: false),
        relatedLogIds:
            _selectedLogs.map((log) => log.id).toList(growable: false),
        reminder: _status == 'PLANNED' && _shouldSendReminder
            ? HealthEntityReminderInput(
                pushEnabled: _pushEnabled,
                remindOffsetMinutes:
                    _pushEnabled ? (_remindOffsetMinutes ?? 0) : null,
              )
            : null,
        rowVersion: widget.initialVisit?.rowVersion,
      ),
    );
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
        _attachments.addAll(uploaded.map(AttachmentDraftItem.fromUploaded));
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось загрузить файлы.',
          ),
        ),
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
    final files =
        await ref.read(mediaPickerServiceProvider).pickGalleryImages();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message.toString()
                : 'Не удалось загрузить файлы.',
          ),
        ),
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

  Future<void> _pickRelatedLog() async {
    final selected = await showModalBottomSheet<LogCard>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VisitLogPickerSheet(
        petId: widget.petId,
        excludedLogIds: _selectedLogs.map((log) => log.id).toSet(),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _selectedLogs.add(selected);
    });
  }

  void _removeRelatedLog(String logId) {
    setState(() {
      _selectedLogs.removeWhere((log) => log.id == logId);
    });
  }
}

class _VetVisitComposerPage extends StatelessWidget {
  const _VetVisitComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypes,
    this.initialVisit,
    this.title = 'Новый визит',
    this.submitLabel = 'Сохранить визит',
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<String> allowedTypes;
  final VetVisit? initialVisit;
  final String title;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _VetVisitComposerSheet(
        petId: petId,
        allowedStatuses: allowedStatuses,
        allowedTypes: allowedTypes,
        initialVisit: initialVisit,
        title: title,
        submitLabel: submitLabel,
        showHeader: false,
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({
    required this.label,
    required this.onTap,
    this.secondary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return PawlyButton(
      label: label,
      onPressed: onTap,
      variant:
          secondary ? PawlyButtonVariant.secondary : PawlyButtonVariant.ghost,
    );
  }
}

class PetVetVisitDetailsPage extends ConsumerWidget {
  const PetVetVisitDetailsPage({
    required this.petId,
    required this.visitId,
    super.key,
  });

  final String petId;
  final String visitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitRef = PetVetVisitRef(petId: petId, visitId: visitId);
    final visitAsync = ref.watch(petVetVisitDetailsProvider(visitRef));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Визит'),
        actions: visitAsync.maybeWhen(
          data: (visit) => <Widget>[
            if (visit.canEdit)
              IconButton(
                onPressed: () => _editVisit(context, ref, visit),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Редактировать',
              ),
            if (visit.canDelete)
              IconButton(
                onPressed: () => _deleteVisit(context, ref, visit),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Удалить',
              ),
          ],
          orElse: () => const <Widget>[],
        ),
      ),
      body: visitAsync.when(
        data: (visit) => _VetVisitDetailsView(
          petId: petId,
          visit: visit,
          onRefresh: () async {
            ref.invalidate(petVetVisitDetailsProvider(visitRef));
            await ref.read(petVetVisitDetailsProvider(visitRef).future);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _VetVisitsErrorView(
          onRetry: () => ref.invalidate(petVetVisitDetailsProvider(visitRef)),
        ),
      ),
    );
  }

  Future<void> _editVisit(
    BuildContext context,
    WidgetRef ref,
    VetVisit visit,
  ) async {
    final state = ref.read(petVetVisitsControllerProvider(petId)).asData?.value;
    final input = await Navigator.of(context).push<UpsertVetVisitInput>(
      MaterialPageRoute<UpsertVetVisitInput>(
        builder: (context) => _VetVisitComposerPage(
          petId: petId,
          allowedStatuses: state?.bootstrap.enums.vetVisitStatuses ??
              const <String>['PLANNED', 'COMPLETED', 'CANCELLED'],
          allowedTypes:
              state?.bootstrap.enums.vetVisitTypes ?? const <String>['CHECKUP'],
          initialVisit: visit,
          title: 'Редактировать визит',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(petVetVisitsControllerProvider(petId).notifier)
          .updateVetVisit(
            visitId: visitId,
            input: input,
          );
      ref.invalidate(petVetVisitDetailsProvider(
          PetVetVisitRef(petId: petId, visitId: visitId)));
      ref.invalidate(petHealthHomeProvider(petId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменения сохранены.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _mutationErrorMessage(error, 'Не удалось обновить визит.'))),
      );
    }
  }

  Future<void> _deleteVisit(
    BuildContext context,
    WidgetRef ref,
    VetVisit visit,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить визит?'),
            content: const Text(
              'Запись о визите будет удалена. Это действие нельзя отменить.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Удалить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) return;

    try {
      await ref
          .read(petVetVisitsControllerProvider(petId).notifier)
          .deleteVetVisit(
            visitId: visit.id,
            rowVersion: visit.rowVersion,
          );
      ref.invalidate(petVetVisitDetailsProvider(
          PetVetVisitRef(petId: petId, visitId: visitId)));
      ref.invalidate(petHealthHomeProvider(petId));
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _mutationErrorMessage(error, 'Не удалось удалить визит.'))),
      );
    }
  }
}

class _VetVisitDetailsView extends ConsumerStatefulWidget {
  const _VetVisitDetailsView({
    required this.petId,
    required this.visit,
    required this.onRefresh,
  });

  final String petId;
  final VetVisit visit;
  final Future<void> Function() onRefresh;

  @override
  ConsumerState<_VetVisitDetailsView> createState() =>
      _VetVisitDetailsViewState();
}

class _VetVisitDetailsViewState extends ConsumerState<_VetVisitDetailsView> {
  bool _isMutatingLogs = false;

  @override
  Widget build(BuildContext context) {
    final visit = widget.visit;
    final listState =
        ref.watch(petVetVisitsControllerProvider(widget.petId)).asData?.value;
    final canReadLogs = listState?.bootstrap.permissions.logRead == true;
    final canAttachLogs = visit.canEdit && canReadLogs;

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          PawlyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _visitTypeLabel(visit.visitType),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                PawlyBadge(
                  label: _visitStatusLabel(visit.status),
                  tone: _visitStatusTone(visit.status),
                ),
              ],
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyCard(
            title: Text(
              'Основное',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (_dateValue(visit.scheduledAt) case final value?)
                  _VisitDetailsRow(label: 'Дата визита', value: value),
                if (_dateValue(visit.completedAt) case final value?)
                  _VisitDetailsRow(label: 'Дата завершения', value: value),
                if (_nonEmpty(visit.clinicName) case final value?)
                  _VisitDetailsRow(label: 'Клиника', value: value),
                if (_nonEmpty(visit.vetName) case final value?)
                  _VisitDetailsRow(label: 'Ветеринар', value: value),
              ],
            ),
          ),
          if (_nonEmpty(visit.reasonText) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Причина визита',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(value),
            ),
          ],
          if (_nonEmpty(visit.resultText) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Результат визита',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(value),
            ),
          ],
          if (visit.relatedLogs.isNotEmpty || canAttachLogs) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Связанные записи',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              footer: canAttachLogs
                  ? PawlyButton(
                      label: _isMutatingLogs
                          ? 'Обновляем...'
                          : 'Прикрепить запись',
                      onPressed: _isMutatingLogs ? null : _attachLog,
                      icon: Icons.add_link_rounded,
                      variant: PawlyButtonVariant.secondary,
                    )
                  : null,
              child: visit.relatedLogs.isEmpty
                  ? const _AttachedLogsEmptyState()
                  : Column(
                      children: visit.relatedLogs
                          .map(
                            (log) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.notes_rounded),
                              title: Text(log.logTypeName ?? 'Запись'),
                              subtitle: Text(_relatedLogSubtitle(log)),
                              trailing: visit.canEdit
                                  ? IconButton(
                                      onPressed: _isMutatingLogs
                                          ? null
                                          : () => _unlinkLog(log),
                                      icon: const Icon(
                                        Icons.link_off_rounded,
                                      ),
                                      tooltip: 'Открепить',
                                    )
                                  : null,
                              onTap: canReadLogs
                                  ? () => context.pushNamed(
                                        'petLogDetails',
                                        pathParameters: <String, String>{
                                          'petId': widget.petId,
                                          'logId': log.id,
                                        },
                                      )
                                  : null,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ),
          ],
          if (visit.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            Builder(
              builder: (context) {
                final viewerItems = visit.attachments
                    .map(
                      (attachment) => AttachmentViewerItem.fromAttachment(
                        fileId: attachment.fileId,
                        fileType: attachment.fileType,
                        fileName: attachment.fileName,
                        previewUrl: attachment.previewUrl,
                        downloadUrl: attachment.downloadUrl,
                      ),
                    )
                    .toList(growable: false);
                final imageItems = viewerItems
                    .where(
                      (item) =>
                          item.kind == AttachmentKind.image && item.url != null,
                    )
                    .toList(growable: false);

                return PawlyCard(
                  title: Text(
                    'Вложения',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  child: Column(
                    children: List<Widget>.generate(visit.attachments.length,
                        (index) {
                      final attachment = visit.attachments[index];
                      final viewerItem = viewerItems[index];
                      final imageIndex = imageItems.indexWhere(
                        (item) =>
                            item.url == viewerItem.url &&
                            item.title == viewerItem.title,
                      );

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          switch (viewerItem.kind) {
                            AttachmentKind.image => Icons.photo_rounded,
                            AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
                            AttachmentKind.other => Icons.description_rounded,
                          },
                        ),
                        title: Text(viewerItem.title),
                        subtitle: Text(
                          attachment.addedAt == null
                              ? attachment.fileType
                              : '${attachment.fileType} • ${_formatDate(attachment.addedAt!)}',
                        ),
                        onTap: () => openAttachmentUrl(
                          context,
                          fileId: attachment.fileId,
                          fileType: attachment.fileType,
                          fileName: viewerItem.title,
                          previewUrl: attachment.previewUrl,
                          downloadUrl: attachment.downloadUrl,
                          imageGalleryItems: imageItems,
                          initialImageIndex:
                              imageIndex >= 0 ? imageIndex : null,
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _attachLog() async {
    final selected = await showModalBottomSheet<LogCard>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VisitLogPickerSheet(
        petId: widget.petId,
        excludedLogIds: widget.visit.relatedLogs.map((log) => log.id).toSet(),
      ),
    );
    if (selected == null || !mounted) {
      return;
    }

    setState(() => _isMutatingLogs = true);
    try {
      await ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .linkLogToVisit(
            visitId: widget.visit.id,
            logId: selected.id,
          );
      _refreshVisitData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись прикреплена.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(error, 'Не удалось прикрепить запись.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutatingLogs = false);
      }
    }
  }

  Future<void> _unlinkLog(RelatedLog log) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Открепить запись?'),
            content: const Text(
              'Запись останется в журнале питомца, но больше не будет связана с этим визитом.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Отмена'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Открепить'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    setState(() => _isMutatingLogs = true);
    try {
      await ref
          .read(petVetVisitsControllerProvider(widget.petId).notifier)
          .unlinkLogFromVisit(
            visitId: widget.visit.id,
            logId: log.id,
          );
      _refreshVisitData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись откреплена.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(error, 'Не удалось открепить запись.'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isMutatingLogs = false);
      }
    }
  }

  void _refreshVisitData() {
    ref.invalidate(
      petVetVisitDetailsProvider(
        PetVetVisitRef(petId: widget.petId, visitId: widget.visit.id),
      ),
    );
    ref.invalidate(petVetVisitsControllerProvider(widget.petId));
    ref.invalidate(petHealthHomeProvider(widget.petId));
  }
}

class _AttachedLogsEmptyState extends StatelessWidget {
  const _AttachedLogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'К этому визиту пока не прикреплены записи.',
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }
}

class _VisitLogPickerSheet extends ConsumerStatefulWidget {
  const _VisitLogPickerSheet({
    required this.petId,
    required this.excludedLogIds,
  });

  final String petId;
  final Set<String> excludedLogIds;

  @override
  ConsumerState<_VisitLogPickerSheet> createState() =>
      _VisitLogPickerSheetState();
}

class _VisitLogPickerSheetState extends ConsumerState<_VisitLogPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  late Future<LogListResponse> _logsFuture;

  @override
  void initState() {
    super.initState();
    _logsFuture = _loadLogs();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final height = MediaQuery.of(context).size.height * 0.8;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              PawlySpacing.lg,
              0,
              PawlySpacing.lg,
              PawlySpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Прикрепить запись',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Выберите существующую запись из журнала питомца.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: PawlyTextField(
                        controller: _searchController,
                        label: 'Поиск по записям',
                        textInputAction: TextInputAction.search,
                        onFieldSubmitted: (_) => _reloadLogs(),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: PawlyButton(
                        label: 'Найти',
                        onPressed: _reloadLogs,
                        variant: PawlyButtonVariant.secondary,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                Expanded(
                  child: FutureBuilder<LogListResponse>(
                    future: _logsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: PawlyCard(
                            title: const Text('Не удалось загрузить записи'),
                            footer: PawlyButton(
                              label: 'Повторить',
                              onPressed: _reloadLogs,
                              variant: PawlyButtonVariant.secondary,
                            ),
                            child: const Text(
                              'Попробуйте обновить список еще раз.',
                            ),
                          ),
                        );
                      }

                      final response = snapshot.data ??
                          const LogListResponse(items: <LogCard>[]);
                      final logs = response.items
                          .where(
                            (log) => !widget.excludedLogIds.contains(log.id),
                          )
                          .toList(growable: false);

                      if (logs.isEmpty) {
                        return Center(
                          child: PawlyCard(
                            child: Text(
                              widget.excludedLogIds.isEmpty
                                  ? 'Подходящих записей пока нет.'
                                  : 'Все найденные записи уже прикреплены к визиту.',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: logs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: PawlySpacing.sm),
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return _LogPickerTile(log: log);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<LogListResponse> _loadLogs() {
    return ref.read(healthRepositoryProvider).listLogs(
          widget.petId,
          query: LogListQuery(
            limit: 30,
            searchQuery: _nonEmpty(_searchController.text),
            sort: 'occurred_at_desc',
            includeFacets: false,
          ),
        );
  }

  void _reloadLogs() {
    setState(() => _logsFuture = _loadLogs());
  }
}

class _LogPickerTile extends StatelessWidget {
  const _LogPickerTile({required this.log});

  final LogCard log;

  @override
  Widget build(BuildContext context) {
    final preview = _nonEmpty(log.descriptionPreview);
    final subtitleParts = <String>[
      if (_dateValue(log.occurredAt) case final date?) date,
      if (preview != null) preview,
      _logSourceLabel(log.source),
    ];

    return PawlyCard(
      onTap: () => Navigator.of(context).pop(log),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(Icons.notes_rounded),
          const SizedBox(width: PawlySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  log.logTypeName ?? 'Запись',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  subtitleParts.join(' · '),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisitDetailsRow extends StatelessWidget {
  const _VisitDetailsRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

class _VetVisitsNoAccessView extends StatelessWidget {
  const _VetVisitsNoAccessView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Нет доступа к визитам',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                'У текущей роли нет права health_read для этого питомца.',
                style: Theme.of(context).textTheme.bodyMedium,
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
    );
  }
}

class _VetVisitsErrorView extends StatelessWidget {
  const _VetVisitsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить визиты'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const Text('Попробуйте обновить экран чуть позже.'),
        ),
      ),
    );
  }
}

Future<DateTime?> _pickDateTime(
  BuildContext context, {
  required DateTime initialDate,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );
  if (date == null || !context.mounted) {
    return null;
  }

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (time == null) {
    return null;
  }

  return DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year $hour:$minute';
}

String _formatDate(DateTime value) => _formatDateTime(value);

String? _dateValue(DateTime? value) =>
    value == null ? null : _formatDateTime(value);

String? _nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String _mutationErrorMessage(Object error, String fallback) {
  if (error is StateError) {
    return error.message.toString();
  }
  return fallback;
}

String _relatedLogSubtitle(RelatedLog log) {
  final parts = <String>[
    if (_dateValue(log.occurredAt) case final date?) date,
    if (_nonEmpty(log.descriptionPreview) case final preview?) preview,
    _logSourceLabel(log.source),
  ];
  return parts.join(' · ');
}

String _logCardSubtitle(LogCard log) {
  final parts = <String>[
    if (_dateValue(log.occurredAt) case final date?) date,
    if (_nonEmpty(log.descriptionPreview) case final preview?) preview,
    _logSourceLabel(log.source),
  ];
  return parts.join(' · ');
}

String _logSourceLabel(String source) {
  return switch (source) {
    'USER' => 'Журнал',
    'HEALTH' => 'Медраздел',
    _ => source,
  };
}

String _visitStatusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирован',
    'COMPLETED' => 'Завершен',
    'CANCELLED' => 'Отменен',
    _ => status,
  };
}

PawlyBadgeTone _visitStatusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'COMPLETED' => PawlyBadgeTone.success,
    'CANCELLED' => PawlyBadgeTone.warning,
    _ => PawlyBadgeTone.neutral,
  };
}

String _visitTypeLabel(String type) {
  return switch (type) {
    'CHECKUP' => 'Осмотр',
    'SYMPTOM' => 'Симптомы',
    'FOLLOW_UP' => 'Повторный прием',
    'VACCINATION' => 'Вакцинация',
    'PROCEDURE' => 'Процедура',
    'OTHER' => 'Другое',
    _ => type,
  };
}
