import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/network/models/health_models.dart';
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
import '../providers/pet_medical_records_controller.dart';
import '../widgets/health_attachments_field.dart';

class PetMedicalRecordsPage extends ConsumerStatefulWidget {
  const PetMedicalRecordsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetMedicalRecordsPage> createState() =>
      _PetMedicalRecordsPageState();
}

class _PetMedicalRecordsPageState extends ConsumerState<PetMedicalRecordsPage> {
  MedicalRecordBucket _selectedBucket = MedicalRecordBucket.active;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      petMedicalRecordsControllerProvider(widget.petId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Медкарта')),
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Новая запись'),
            )
          : null,
      body: stateAsync.when(
        data: (state) => _MedicalRecordsContent(
          petId: widget.petId,
          state: state,
          selectedBucket: _selectedBucket,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MedicalRecordsErrorView(
          onRetry: () => ref
              .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
              .reload(),
        ),
      ),
    );
  }

  Future<void> _openCreateSheet() async {
    final state = ref
        .read(petMedicalRecordsControllerProvider(widget.petId))
        .asData
        ?.value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertMedicalRecordInput>(
      MaterialPageRoute<UpsertMedicalRecordInput>(
        builder: (context) => _MedicalRecordComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.medicalRecordStatuses,
          allowedTypes: state.bootstrap.enums.medicalRecordTypes,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
          .createMedicalRecord(input: input);
      ref.invalidate(petHealthHomeProvider(widget.petId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Запись медкарты сохранена.')),
      );
      setState(
        () => _selectedBucket = input.status == 'ACTIVE'
            ? MedicalRecordBucket.active
            : MedicalRecordBucket.archive,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(
              error,
              'Не удалось сохранить запись медкарты.',
            ),
          ),
        ),
      );
    }
  }
}

class _MedicalRecordComposerPage extends StatelessWidget {
  const _MedicalRecordComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypes,
    this.initialRecord,
    this.title = 'Новая запись',
    this.submitLabel = 'Сохранить запись',
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<String> allowedTypes;
  final MedicalRecord? initialRecord;
  final String title;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: _MedicalRecordComposerSheet(
        petId: petId,
        allowedStatuses: allowedStatuses,
        allowedTypes: allowedTypes,
        initialRecord: initialRecord,
        title: title,
        submitLabel: submitLabel,
        showHeader: false,
      ),
    );
  }
}

class _MedicalRecordsContent extends StatelessWidget {
  const _MedicalRecordsContent({
    required this.petId,
    required this.state,
    required this.selectedBucket,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
  });

  final String petId;
  final PetMedicalRecordsState state;
  final MedicalRecordBucket selectedBucket;
  final ValueChanged<MedicalRecordBucket> onBucketChanged;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _MedicalRecordsNoAccessView(onRetry: onRetry);
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
              ? 'Диагнозы, аллергии и клинические записи'
              : 'Диагнозы, аллергии и клинические записи · только просмотр',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Wrap(
          spacing: PawlySpacing.sm,
          runSpacing: PawlySpacing.sm,
          children: <Widget>[
            _MedicalRecordBucketChip(
              label: 'Активные',
              count: state.activeItems.length,
              selected: selectedBucket == MedicalRecordBucket.active,
              onTap: () => onBucketChanged(MedicalRecordBucket.active),
            ),
            _MedicalRecordBucketChip(
              label: 'Архив',
              count: state.archiveItems.length,
              selected: selectedBucket == MedicalRecordBucket.archive,
              onTap: () => onBucketChanged(MedicalRecordBucket.archive),
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.lg),
        if (items.isEmpty)
          PawlyCard(
            child: Text(
              selectedBucket == MedicalRecordBucket.active
                  ? 'Активных записей пока нет.'
                  : 'Архив медкарты пока пуст.',
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: _MedicalRecordListCard(
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

class _MedicalRecordBucketChip extends StatelessWidget {
  const _MedicalRecordBucketChip({
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

class _MedicalRecordListCard extends StatelessWidget {
  const _MedicalRecordListCard({
    required this.petId,
    required this.item,
  });

  final String petId;
  final MedicalRecordCard item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PawlyCard(
      onTap: () => context.pushNamed(
        'petMedicalRecordDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'recordId': item.id,
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            item.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Wrap(
            spacing: PawlySpacing.xs,
            runSpacing: PawlySpacing.xs,
            children: <Widget>[
              PawlyBadge(
                label: _medicalRecordStatusLabel(item.status),
                tone: _medicalRecordStatusTone(item.status),
              ),
              PawlyBadge(
                label: _medicalRecordTypeLabel(item.recordType),
                tone: PawlyBadgeTone.neutral,
              ),
            ],
          ),
          if (_dateLine(item) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            _MedicalRecordInfoLine(
              icon: Icons.event_rounded,
              text: value,
            ),
          ],
          if (_nonEmpty(item.descriptionPreview) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            Text(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ],
          if (item.attachmentsCount > 0) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            _MedicalRecordInfoLine(
              icon: Icons.attach_file_rounded,
              text: '${item.attachmentsCount} влож.',
            ),
          ],
        ],
      ),
    );
  }

  String? _dateLine(MedicalRecordCard item) {
    final parts = <String>[
      if (_dateValue(item.startedAt) case final started?) 'С $started',
      if (_dateValue(item.resolvedAt) case final resolved?) 'Закрыто $resolved',
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }
}

class _MedicalRecordInfoLine extends StatelessWidget {
  const _MedicalRecordInfoLine({
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

class _MedicalRecordComposerSheet extends ConsumerStatefulWidget {
  const _MedicalRecordComposerSheet({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypes,
    this.initialRecord,
    this.title = 'Новая запись',
    this.submitLabel = 'Сохранить запись',
    this.showHeader = true,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<String> allowedTypes;
  final MedicalRecord? initialRecord;
  final String title;
  final String submitLabel;
  final bool showHeader;

  @override
  ConsumerState<_MedicalRecordComposerSheet> createState() =>
      _MedicalRecordComposerSheetState();
}

class _MedicalRecordComposerSheetState
    extends ConsumerState<_MedicalRecordComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];

  late String _status;
  late String _recordType;
  DateTime? _startedAt;
  DateTime? _resolvedAt;
  bool _isUploadingAttachments = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialRecord;
    _status = initial?.status ??
        (widget.allowedStatuses.contains('ACTIVE')
            ? 'ACTIVE'
            : widget.allowedStatuses.first);
    _recordType = initial?.recordType ??
        (widget.allowedTypes.contains('CLINICAL_NOTE')
            ? 'CLINICAL_NOTE'
            : widget.allowedTypes.first);
    _titleController.text = initial?.title ?? '';
    _descriptionController.text = initial?.description ?? '';
    _startedAt = initial?.startedAt;
    _resolvedAt = initial?.resolvedAt;
    _attachments.addAll(
      initial?.attachments.map(AttachmentDraftItem.fromHealthAttachment) ??
          const <AttachmentDraftItem>[],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
                ] else ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                ],
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: widget.allowedStatuses
                      .map(
                        (status) => ChoiceChip(
                          label: Text(_medicalRecordStatusLabel(status)),
                          selected: _status == status,
                          onSelected: (_) => setState(() => _status = status),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: PawlySpacing.md),
                DropdownButtonFormField<String>(
                  initialValue: _recordType,
                  decoration: const InputDecoration(labelText: 'Тип записи'),
                  items: widget.allowedTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(_medicalRecordTypeLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _recordType = value);
                  },
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _titleController,
                  label: 'Заголовок',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Укажи заголовок.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _descriptionController,
                  label: 'Описание',
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: PawlySpacing.sm),
                _DateButton(
                  label: _startedAt == null
                      ? 'Дата начала'
                      : 'Дата начала: ${_formatDate(_startedAt!)}',
                  onTap: () async {
                    final picked = await _pickDate(
                      context,
                      initialDate: _startedAt ?? DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _startedAt = picked);
                    }
                  },
                ),
                if (_status == 'RESOLVED') ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  _DateButton(
                    label: _resolvedAt == null
                        ? 'Дата закрытия'
                        : 'Дата закрытия: ${_formatDate(_resolvedAt!)}',
                    onTap: () async {
                      final picked = await _pickDate(
                        context,
                        initialDate:
                            _resolvedAt ?? _startedAt ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _resolvedAt = picked);
                      }
                    },
                    secondary: true,
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
      UpsertMedicalRecordInput(
        recordType: _recordType,
        status: _status,
        title: _titleController.text.trim(),
        description: _nonEmpty(_descriptionController.text),
        startedAtIso: _toStoredDate(_startedAt)?.toIso8601String(),
        resolvedAtIso: _toStoredDate(_resolvedAt)?.toIso8601String(),
        attachmentFileIds: _attachments
            .map((attachment) => attachment.fileId)
            .toList(growable: false),
        rowVersion: widget.initialRecord?.rowVersion,
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

  DateTime? _toStoredDate(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day, 12);
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

class PetMedicalRecordDetailsPage extends ConsumerWidget {
  const PetMedicalRecordDetailsPage({
    required this.petId,
    required this.recordId,
    super.key,
  });

  final String petId;
  final String recordId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordRef = PetMedicalRecordRef(petId: petId, recordId: recordId);
    final recordAsync = ref.watch(petMedicalRecordDetailsProvider(recordRef));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Запись медкарты'),
        actions: recordAsync.maybeWhen(
          data: (record) => <Widget>[
            if (record.canEdit)
              IconButton(
                onPressed: () => _editRecord(context, ref, record),
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Редактировать',
              ),
            if (record.canDelete)
              IconButton(
                onPressed: () => _deleteRecord(context, ref, record),
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Удалить',
              ),
          ],
          orElse: () => const <Widget>[],
        ),
      ),
      body: recordAsync.when(
        data: (record) => _MedicalRecordDetailsView(
          record: record,
          onRefresh: () async {
            ref.invalidate(petMedicalRecordDetailsProvider(recordRef));
            await ref.read(petMedicalRecordDetailsProvider(recordRef).future);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _MedicalRecordsErrorView(
          onRetry: () =>
              ref.invalidate(petMedicalRecordDetailsProvider(recordRef)),
        ),
      ),
    );
  }

  Future<void> _editRecord(
    BuildContext context,
    WidgetRef ref,
    MedicalRecord record,
  ) async {
    final state =
        ref.read(petMedicalRecordsControllerProvider(petId)).asData?.value;
    final input = await Navigator.of(context).push<UpsertMedicalRecordInput>(
      MaterialPageRoute<UpsertMedicalRecordInput>(
        builder: (context) => _MedicalRecordComposerPage(
          petId: petId,
          allowedStatuses: state?.bootstrap.enums.medicalRecordStatuses ??
              const <String>['ACTIVE', 'RESOLVED'],
          allowedTypes: state?.bootstrap.enums.medicalRecordTypes ??
              const <String>['CLINICAL_NOTE'],
          initialRecord: record,
          title: 'Редактировать запись',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(petMedicalRecordsControllerProvider(petId).notifier)
          .updateMedicalRecord(
            recordId: recordId,
            input: input,
          );
      ref.invalidate(
        petMedicalRecordDetailsProvider(
          PetMedicalRecordRef(petId: petId, recordId: recordId),
        ),
      );
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
            _mutationErrorMessage(
              error,
              'Не удалось обновить запись медкарты.',
            ),
          ),
        ),
      );
    }
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    MedicalRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить запись?'),
            content: const Text(
              'Запись медкарты будет удалена. Это действие нельзя отменить.',
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
          .read(petMedicalRecordsControllerProvider(petId).notifier)
          .deleteMedicalRecord(
            recordId: record.id,
            rowVersion: record.rowVersion,
          );
      ref.invalidate(
        petMedicalRecordDetailsProvider(
          PetMedicalRecordRef(petId: petId, recordId: recordId),
        ),
      );
      ref.invalidate(petHealthHomeProvider(petId));
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(
              error,
              'Не удалось удалить запись медкарты.',
            ),
          ),
        ),
      );
    }
  }
}

class _MedicalRecordDetailsView extends StatelessWidget {
  const _MedicalRecordDetailsView({
    required this.record,
    required this.onRefresh,
  });

  final MedicalRecord record;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          PawlyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  record.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: <Widget>[
                    PawlyBadge(
                      label: _medicalRecordStatusLabel(record.status),
                      tone: _medicalRecordStatusTone(record.status),
                    ),
                    PawlyBadge(
                      label: _medicalRecordTypeLabel(record.recordType),
                      tone: PawlyBadgeTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_detailsLines(record).isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Основное',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _detailsLines(record)
                    .map(
                      (line) => _MedicalRecordDetailsRow(
                        label: line.$1,
                        value: line.$2,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (_nonEmpty(record.description) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Описание',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(value),
            ),
          ],
          if (record.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            Builder(
              builder: (context) {
                final viewerItems = record.attachments
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
                    children: List<Widget>.generate(record.attachments.length,
                        (index) {
                      final attachment = record.attachments[index];
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

  List<(String, String)> _detailsLines(MedicalRecord record) {
    return <(String, String)>[
      if (_dateValue(record.startedAt) case final value?)
        ('Дата начала', value),
      if (_dateValue(record.resolvedAt) case final value?)
        ('Дата закрытия', value),
    ];
  }
}

class _MedicalRecordDetailsRow extends StatelessWidget {
  const _MedicalRecordDetailsRow({
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

class _MedicalRecordsNoAccessView extends StatelessWidget {
  const _MedicalRecordsNoAccessView({required this.onRetry});

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
                'Нет доступа к медкарте',
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

class _MedicalRecordsErrorView extends StatelessWidget {
  const _MedicalRecordsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить медкарту'),
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

Future<DateTime?> _pickDate(
  BuildContext context, {
  required DateTime initialDate,
}) {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: DateTime(2000),
    lastDate: DateTime.now().add(const Duration(days: 3650)),
  );
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day.$month.$year';
}

String? _dateValue(DateTime? value) =>
    value == null ? null : _formatDate(value);

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

String _medicalRecordStatusLabel(String status) {
  return switch (status) {
    'ACTIVE' => 'Активна',
    'RESOLVED' => 'Закрыта',
    _ => status,
  };
}

PawlyBadgeTone _medicalRecordStatusTone(String status) {
  return switch (status) {
    'ACTIVE' => PawlyBadgeTone.info,
    'RESOLVED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

String _medicalRecordTypeLabel(String type) {
  return switch (type) {
    'DIAGNOSIS' => 'Диагноз',
    'ALLERGY' => 'Аллергия',
    'CHRONIC_CONDITION' => 'Хроническое',
    'INJURY' => 'Травма',
    'SURGERY' => 'Операция',
    'CLINICAL_NOTE' => 'Клиническая запись',
    _ => type,
  };
}
