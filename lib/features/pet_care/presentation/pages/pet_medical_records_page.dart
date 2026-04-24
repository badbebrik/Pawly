import 'dart:async';

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
import '../widgets/health_common_widgets.dart';

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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  MedicalRecordBucket _selectedBucket = MedicalRecordBucket.active;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      petMedicalRecordsControllerProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Медкарта',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новая запись',
              tooltip: 'Добавить запись медкарты',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => _MedicalRecordsContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
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

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      ref
          .read(petMedicalRecordsControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
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
          allowedTypeItems: state.bootstrap.enums.medicalRecordTypeItems,
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
    required this.allowedTypeItems,
    this.initialRecord,
    this.title = 'Новая запись',
    this.submitLabel = 'Сохранить запись',
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<HealthDictionaryItem> allowedTypeItems;
  final MedicalRecord? initialRecord;
  final String title;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return PawlyScreenScaffold(
      title: title,
      body: _MedicalRecordComposerSheet(
        petId: petId,
        allowedStatuses: allowedStatuses,
        allowedTypeItems: allowedTypeItems,
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
    required this.searchController,
    required this.selectedBucket,
    required this.onSearchChanged,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
  });

  final String petId;
  final PetMedicalRecordsState state;
  final TextEditingController searchController;
  final MedicalRecordBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<MedicalRecordBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _MedicalRecordsNoAccessView(onRetry: onRetry);
    }

    final items = state.itemsFor(selectedBucket);
    final isActive = selectedBucket == MedicalRecordBucket.active;

    return RefreshIndicator(
      onRefresh: onRetry,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          PawlyTextField(
            controller: searchController,
            hintText: 'Название, описание',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<MedicalRecordBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<MedicalRecordBucket>>[
              HealthBucketOption<MedicalRecordBucket>(
                value: MedicalRecordBucket.active,
                label: 'Активные',
                count: state.activeItems.length,
              ),
              HealthBucketOption<MedicalRecordBucket>(
                value: MedicalRecordBucket.archive,
                label: 'Архив',
                count: state.archiveItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            _MedicalRecordsInlineMessage(
              title: isActive ? 'Активных записей нет' : 'Архив пуст',
              message: isActive
                  ? 'Добавьте запись, чтобы важная медицинская информация была под рукой.'
                  : 'Закрытые записи появятся здесь.',
            )
          else
            ...items.map(
              (item) => _MedicalRecordListCard(
                petId: petId,
                item: item,
              ),
            ),
          if (state.nextCursorFor(selectedBucket) != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyButton(
              label: state.isLoadingMore(selectedBucket)
                  ? 'Загрузка...'
                  : 'Загрузить еще',
              onPressed:
                  state.isLoadingMore(selectedBucket) ? null : onLoadMore,
              variant: PawlyButtonVariant.secondary,
            ),
          ],
        ],
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
    final colorScheme = theme.colorScheme;
    final dateLabel = _dateLine(item);
    final bodyText = _nonEmpty(item.descriptionPreview);
    final chips = <Widget>[
      if (item.status != 'ACTIVE')
        PawlyBadge(
          label: _medicalRecordStatusLabel(item.status),
          tone: _medicalRecordStatusTone(item.status),
        ),
      PawlyBadge(
        label: _medicalRecordTypeItemLabel(item.recordTypeItem),
        tone: PawlyBadgeTone.neutral,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.sm),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        child: InkWell(
          onTap: () => context.pushNamed(
            'petMedicalRecordDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'recordId': item.id,
            },
          ),
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(PawlyRadius.xl),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.72),
              ),
            ),
            padding: const EdgeInsets.all(PawlySpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (dateLabel != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    dateLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                if (bodyText != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    bodyText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: PawlySpacing.sm),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: chips,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _dateLine(MedicalRecordCard item) {
    final date = switch (item.status) {
      'RESOLVED' => item.resolvedAt ?? item.startedAt,
      _ => item.startedAt,
    };
    if (date == null) {
      return null;
    }
    final prefix = switch (item.status) {
      'RESOLVED' => 'Закрыто',
      _ => 'С',
    };
    return '$prefix ${_formatDate(date)}';
  }
}

class _MedicalRecordComposerSheet extends ConsumerStatefulWidget {
  const _MedicalRecordComposerSheet({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypeItems,
    this.initialRecord,
    this.title = 'Новая запись',
    this.submitLabel = 'Сохранить запись',
    this.showHeader = true,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<HealthDictionaryItem> allowedTypeItems;
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
  final _customRecordTypeController = TextEditingController();
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];

  late String _status;
  late String _recordTypeSelection;
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
    _recordTypeSelection = _initialRecordTypeSelection(initial);
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
    _customRecordTypeController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> get _recordTypeOptions {
    final items = <HealthDictionaryItem>[
      ...widget.allowedTypeItems.where((item) => !item.isArchived),
    ];
    final initialItem = widget.initialRecord?.recordTypeItem;
    if (initialItem != null &&
        !items.any((item) => item.id == initialItem.id)) {
      items.add(initialItem);
    }

    return <DropdownMenuItem<String>>[
      ...items.map(
        (item) => DropdownMenuItem<String>(
          value: 'item:${item.id}',
          child: Text(item.name),
        ),
      ),
      const DropdownMenuItem<String>(
        value: 'custom',
        child: Text('Другой тип'),
      ),
    ];
  }

  String? get _selectedRecordTypeId {
    if (!_recordTypeSelection.startsWith('item:')) {
      return null;
    }
    return _recordTypeSelection.substring('item:'.length);
  }

  String _initialRecordTypeSelection(MedicalRecord? initial) {
    final initialItem = initial?.recordTypeItem;
    if (initialItem != null) {
      return 'item:${initialItem.id}';
    }

    final activeItems =
        widget.allowedTypeItems.where((item) => !item.isArchived);
    if (activeItems.isNotEmpty) {
      return 'item:${activeItems.first.id}';
    }

    return 'custom';
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
                PawlyListSection(
                  title: 'Статус',
                  padding: const EdgeInsets.all(PawlySpacing.sm),
                  children: <Widget>[
                    HealthBucketSegment<String>(
                      selectedValue: _status,
                      onChanged: (status) => setState(() => _status = status),
                      options: widget.allowedStatuses
                          .map(
                            (status) => HealthBucketOption<String>(
                              value: status,
                              label: _medicalRecordStatusLabel(status),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Запись',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _MedicalRecordTypeField(
                      value: _recordTypeSelection,
                      items: _recordTypeOptions,
                      onChanged: (value) =>
                          setState(() => _recordTypeSelection = value),
                    ),
                    if (_recordTypeSelection == 'custom')
                      _MedicalRecordFormTextField(
                        controller: _customRecordTypeController,
                        label: 'Свой тип записи',
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Укажите тип записи.';
                          }
                          return null;
                        },
                      ),
                    _MedicalRecordFormTextField(
                      controller: _titleController,
                      label: 'Заголовок',
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Укажите заголовок.';
                        }
                        return null;
                      },
                    ),
                    _MedicalRecordFormTextField(
                      controller: _descriptionController,
                      label: 'Описание',
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Даты',
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  children: <Widget>[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        HealthDateButton(
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
                          HealthDateButton(
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
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.lg),
                HealthAttachmentsField(
                  attachments: _attachments,
                  isUploading: _isUploadingAttachments,
                  enabled: true,
                  onAddFiles: _pickAndUploadAttachments,
                  onAddFromGallery: _pickAndUploadFromGallery,
                  onAddFromCamera: _pickAndUploadFromCamera,
                  onRemove: _removeAttachment,
                  onRename: _renameAttachment,
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
        recordTypeId: _selectedRecordTypeId,
        recordTypeName: _recordTypeSelection == 'custom'
            ? _nonEmpty(_customRecordTypeController.text)
            : null,
        status: _status,
        title: _titleController.text.trim(),
        description: _nonEmpty(_descriptionController.text),
        startedAtIso: _toStoredDate(_startedAt)?.toIso8601String(),
        resolvedAtIso: _toStoredDate(_resolvedAt)?.toIso8601String(),
        attachments: _attachmentInputs(),
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
          .uploadFiles(widget.petId,
              files: files, entityType: 'MEDICAL_RECORD');
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
    final files = await ref
        .read(mediaPickerServiceProvider)
        .pickAttachmentImagesFromGallery();
    if (files.isEmpty || !mounted) {
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
    await _uploadPickedImages(<XFile>[file]);
  }

  Future<void> _uploadPickedImages(List<XFile> files) async {
    setState(() {
      _isUploadingAttachments = true;
    });

    try {
      final uploaded =
          await ref.read(healthFileUploadServiceProvider).uploadXFiles(
                widget.petId,
                files: files,
                entityType: 'MEDICAL_RECORD',
              );
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

  DateTime? _toStoredDate(DateTime? value) {
    if (value == null) return null;
    return DateTime(value.year, value.month, value.day, 12);
  }
}

class _MedicalRecordFormTextField extends StatelessWidget {
  const _MedicalRecordFormTextField({
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final int maxLines;
  final FormFieldValidator<String>? validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      textCapitalization: textCapitalization,
      decoration: _medicalRecordRowDecoration(label: label),
    );
  }
}

class _MedicalRecordTypeField extends StatelessWidget {
  const _MedicalRecordTypeField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: _medicalRecordRowDecoration(label: 'Тип записи'),
      items: items,
      onChanged: (value) {
        if (value == null) {
          return;
        }
        onChanged(value);
      },
    );
  }
}

InputDecoration _medicalRecordRowDecoration({required String label}) {
  return InputDecoration(
    labelText: label,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: PawlySpacing.md,
      vertical: PawlySpacing.sm,
    ),
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
  );
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

    return PawlyScreenScaffold(
      title: 'Запись медкарты',
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
          allowedTypeItems: state?.bootstrap.enums.medicalRecordTypeItems ??
              const <HealthDictionaryItem>[],
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
    final theme = Theme.of(context);
    final details = _detailsLines(record);
    final description = _nonEmpty(record.description);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          PawlyListSection(
            children: <Widget>[
              SizedBox(
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        record.title,
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
                            label: _medicalRecordStatusLabel(record.status),
                            tone: _medicalRecordStatusTone(record.status),
                          ),
                          PawlyBadge(
                            label: _medicalRecordTypeItemLabel(
                              record.recordTypeItem,
                            ),
                            tone: PawlyBadgeTone.neutral,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (details.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            HealthDetailsSection(
              title: 'Основное',
              children: details
                  .map(
                    (line) => HealthDetailsRow(
                      label: line.$1,
                      value: line.$2,
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (description != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Описание',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(description, style: theme.textTheme.bodyLarge),
                ),
              ],
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

                return PawlyListSection(
                  title: 'Вложения',
                  children: List<Widget>.generate(
                    record.attachments.length,
                    (index) {
                      final attachment = record.attachments[index];
                      final viewerItem = viewerItems[index];
                      final imageIndex = imageItems.indexWhere(
                        (item) =>
                            item.url == viewerItem.url &&
                            item.title == viewerItem.title,
                      );

                      return PawlyListTile(
                        title: viewerItem.title,
                        subtitle: attachment.addedAt == null
                            ? attachment.fileType
                            : '${attachment.fileType} • ${_formatDate(attachment.addedAt!)}',
                        leadingIcon: switch (viewerItem.kind) {
                          AttachmentKind.image => Icons.photo_rounded,
                          AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
                          AttachmentKind.other => Icons.description_rounded,
                        },
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
                    },
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

class _MedicalRecordsNoAccessView extends StatelessWidget {
  const _MedicalRecordsNoAccessView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: _MedicalRecordsInlineMessage(
          title: 'Нет доступа',
          message: 'У вас нет права просмотра медкарты этого питомца.',
          action: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
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
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: _MedicalRecordsInlineMessage(
          title: 'Не удалось загрузить медкарту',
          message: 'Попробуйте обновить экран через несколько секунд.',
          action: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
        ),
      ),
    );
  }
}

class _MedicalRecordsInlineMessage extends StatelessWidget {
  const _MedicalRecordsInlineMessage({
    required this.title,
    required this.message,
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

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
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (action != null) ...<Widget>[
              const SizedBox(height: PawlySpacing.md),
              action!,
            ],
          ],
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

String _medicalRecordTypeItemLabel(HealthDictionaryItem? item) =>
    item?.name ?? 'Тип не указан';
