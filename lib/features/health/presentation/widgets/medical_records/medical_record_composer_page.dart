import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../shared/attachments/data/attachment_input.dart';
import '../../../../shared/attachments/models/attachment_draft_item.dart';
import '../../../../shared/attachments/presentation/widgets/attachment_upload_field.dart';
import '../../../models/medical_records/medical_record_inputs.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../form/health_form_fields.dart';
import '../shared/health_common_widgets.dart';
import '../shared/health_date_pickers.dart';

class MedicalRecordComposerPage extends StatelessWidget {
  const MedicalRecordComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypeItems,
    this.initialRecord,
    this.title = 'Новая запись',
    this.submitLabel = 'Сохранить запись',
    super.key,
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
      initial?.attachments.map(
            (attachment) => AttachmentDraftItem.fromStoredAttachment(
              fileId: attachment.fileId,
              fileName: attachment.fileName,
              fileType: attachment.fileType,
            ),
          ) ??
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
                              label: formatMedicalRecordStatusLabel(status),
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
                      HealthFormTextField(
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
                    HealthFormTextField(
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
                    HealthFormTextField(
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
                              : 'Дата начала: ${formatHealthDate(_startedAt!)}',
                          onTap: () async {
                            final picked = await pickHealthDate(
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
                                : 'Дата закрытия: ${formatHealthDate(_resolvedAt!)}',
                            onTap: () async {
                              final picked = await pickHealthDate(
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
                AttachmentUploadField(
                  petId: widget.petId,
                  entityType: 'MEDICAL_RECORD',
                  attachments: _attachments,
                  isUploading: _isUploadingAttachments,
                  enabled: true,
                  onChanged: _setAttachments,
                  onUploadingChanged: _setUploadingAttachments,
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
      showPawlySnackBar(
        context,
        message: 'Дождитесь окончания загрузки файлов.',
        tone: PawlySnackBarTone.error,
      );
      return;
    }

    Navigator.of(context).pop(
      UpsertMedicalRecordInput(
        recordTypeId: _selectedRecordTypeId,
        recordTypeName: _recordTypeSelection == 'custom'
            ? nonEmptyHealthText(_customRecordTypeController.text)
            : null,
        status: _status,
        title: _titleController.text.trim(),
        description: nonEmptyHealthText(_descriptionController.text),
        startedAtIso: _toStoredDate(_startedAt)?.toIso8601String(),
        resolvedAtIso: _toStoredDate(_resolvedAt)?.toIso8601String(),
        attachments: _attachmentInputs(),
        rowVersion: widget.initialRecord?.rowVersion,
      ),
    );
  }

  void _setAttachments(List<AttachmentDraftItem> attachments) {
    setState(() {
      _attachments
        ..clear()
        ..addAll(attachments);
    });
  }

  void _setUploadingAttachments(bool value) {
    setState(() => _isUploadingAttachments = value);
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
      decoration: healthFormRowDecoration(label: 'Тип записи'),
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
