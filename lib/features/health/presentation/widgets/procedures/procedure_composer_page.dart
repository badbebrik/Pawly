import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../shared/attachments/data/attachment_input.dart';
import '../../../../shared/attachments/models/attachment_draft_item.dart';
import '../../../../shared/attachments/presentation/widgets/attachment_upload_field.dart';
import '../../../models/procedures/procedure_inputs.dart';
import '../../../models/shared/health_inputs.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../form/health_form_fields.dart';
import '../shared/health_common_widgets.dart';
import '../shared/health_date_pickers.dart';

class ProcedureComposerPage extends StatelessWidget {
  const ProcedureComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypeItems,
    this.initialProcedure,
    this.title = 'Новая процедура',
    this.submitLabel = 'Сохранить процедуру',
    super.key,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<HealthDictionaryItem> allowedTypeItems;
  final Procedure? initialProcedure;
  final String title;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return PawlyScreenScaffold(
      title: title,
      body: _ProcedureComposerSheet(
        petId: petId,
        allowedStatuses: allowedStatuses,
        allowedTypeItems: allowedTypeItems,
        initialProcedure: initialProcedure,
        title: title,
        submitLabel: submitLabel,
        showHeader: false,
      ),
    );
  }
}

class _ProcedureComposerSheet extends ConsumerStatefulWidget {
  const _ProcedureComposerSheet({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypeItems,
    this.initialProcedure,
    this.title = 'Новая процедура',
    this.submitLabel = 'Сохранить процедуру',
    this.showHeader = true,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<HealthDictionaryItem> allowedTypeItems;
  final Procedure? initialProcedure;
  final String title;
  final String submitLabel;
  final bool showHeader;

  @override
  ConsumerState<_ProcedureComposerSheet> createState() =>
      _ProcedureComposerSheetState();
}

class _ProcedureComposerSheetState
    extends ConsumerState<_ProcedureComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _notesController = TextEditingController();
  final _customProcedureTypeController = TextEditingController();
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];

  late String _status;
  late String _procedureTypeSelection;
  DateTime? _scheduledAt;
  DateTime? _performedAt;
  DateTime? _nextDueAt;
  bool _pushEnabled = true;
  int? _remindOffsetMinutes = 0;
  late bool _shouldSendReminder;
  bool _isUploadingAttachments = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProcedure;
    final allowedStatuses = _allowedStatuses;
    _status = initial == null
        ? (allowedStatuses.contains('PLANNED')
            ? 'PLANNED'
            : allowedStatuses.first)
        : initial.status;
    _procedureTypeSelection = _initialProcedureTypeSelection(initial);
    _titleController.text = initial?.title ?? '';
    _descriptionController.text = initial?.description ?? '';
    _productNameController.text = initial?.productName ?? '';
    _notesController.text = initial?.notes ?? '';
    _scheduledAt = initial?.scheduledAt;
    _performedAt = initial?.performedAt;
    _nextDueAt = initial?.nextDueAt;
    _shouldSendReminder = initial == null;
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

  List<String> get _allowedStatuses {
    final statuses = <String>[];
    for (final rawStatus in widget.allowedStatuses) {
      final status = rawStatus.trim().toUpperCase();
      if (!const <String>{'PLANNED', 'COMPLETED'}.contains(status) ||
          statuses.contains(status)) {
        continue;
      }
      statuses.add(status);
    }
    return statuses.isEmpty ? const <String>['PLANNED', 'COMPLETED'] : statuses;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _productNameController.dispose();
    _notesController.dispose();
    _customProcedureTypeController.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> get _procedureTypeOptions {
    final items = <HealthDictionaryItem>[
      ...widget.allowedTypeItems.where((item) => !item.isArchived),
    ];
    final initialItem = widget.initialProcedure?.procedureTypeItem;
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

  String? get _selectedProcedureTypeId {
    if (!_procedureTypeSelection.startsWith('item:')) {
      return null;
    }
    return _procedureTypeSelection.substring('item:'.length);
  }

  String _initialProcedureTypeSelection(Procedure? initial) {
    final initialItem = initial?.procedureTypeItem;
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
                      options: _allowedStatuses
                          .map(
                            (status) => HealthBucketOption<String>(
                              value: status,
                              label: formatProcedureStatusLabel(status),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Процедура',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _ProcedureTypeField(
                      value: _procedureTypeSelection,
                      items: _procedureTypeOptions,
                      onChanged: (value) =>
                          setState(() => _procedureTypeSelection = value),
                    ),
                    if (_procedureTypeSelection == 'custom')
                      HealthFormTextField(
                        controller: _customProcedureTypeController,
                        label: 'Свой тип процедуры',
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) {
                            return 'Укажите тип процедуры.';
                          }
                          return null;
                        },
                      ),
                    HealthFormTextField(
                      controller: _titleController,
                      label: 'Название',
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Укажите название процедуры.';
                        }
                        return null;
                      },
                    ),
                    HealthFormTextField(
                      controller: _descriptionController,
                      label: 'Описание',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    HealthFormTextField(
                      controller: _productNameController,
                      label: 'Препарат или средство',
                      textCapitalization: TextCapitalization.words,
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
                          label: _scheduledAt == null
                              ? 'Дата и время по плану'
                              : 'Дата и время по плану: ${formatHealthDateTime(_scheduledAt!)}',
                          onTap: () async {
                            final picked = await pickHealthDateTime(
                              context,
                              initialDate: _scheduledAt ?? DateTime.now(),
                            );
                            if (!mounted) {
                              return;
                            }
                            if (picked != null) {
                              setState(() => _scheduledAt = picked);
                            }
                          },
                        ),
                        if (_status != 'PLANNED') ...<Widget>[
                          const SizedBox(height: PawlySpacing.sm),
                          HealthDateButton(
                            label: _performedAt == null
                                ? 'Дата и время выполнения'
                                : 'Дата и время выполнения: ${formatHealthDateTime(_performedAt!)}',
                            onTap: () async {
                              final picked = await pickHealthDateTime(
                                context,
                                initialDate: _performedAt ??
                                    _scheduledAt ??
                                    DateTime.now(),
                              );
                              if (!mounted) {
                                return;
                              }
                              if (picked != null) {
                                setState(() => _performedAt = picked);
                              }
                            },
                            secondary: true,
                          ),
                        ],
                        if (_status == 'COMPLETED') ...<Widget>[
                          const SizedBox(height: PawlySpacing.sm),
                          HealthDateButton(
                            label: _nextDueAt == null
                                ? 'Дата и время повтора'
                                : 'Дата и время повтора: ${formatHealthDateTime(_nextDueAt!)}',
                            onTap: () async {
                              final picked = await pickHealthDateTime(
                                context,
                                initialDate: _nextDueAt ??
                                    _performedAt ??
                                    _scheduledAt ??
                                    DateTime.now(),
                              );
                              if (!mounted) {
                                return;
                              }
                              if (picked != null) {
                                setState(() => _nextDueAt = picked);
                              }
                            },
                            secondary: true,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Заметки',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    HealthFormTextField(
                      controller: _notesController,
                      label: 'Заметки',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.lg),
                AttachmentUploadField(
                  petId: widget.petId,
                  entityType: 'PROCEDURE',
                  attachments: _attachments,
                  isUploading: _isUploadingAttachments,
                  enabled: true,
                  onChanged: _setAttachments,
                  onUploadingChanged: _setUploadingAttachments,
                ),
                if (_status == 'PLANNED') ...<Widget>[
                  const SizedBox(height: PawlySpacing.lg),
                  PawlyListSection(
                    title: 'Напоминание',
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: PawlySpacing.md,
                        ),
                        value: _pushEnabled,
                        onChanged: (value) {
                          setState(() {
                            _pushEnabled = value;
                            _shouldSendReminder = true;
                          });
                        },
                        title: const Text('Напоминание включено'),
                      ),
                      if (_pushEnabled)
                        DropdownButtonFormField<int>(
                          initialValue: _remindOffsetMinutes ?? 0,
                          decoration: healthFormRowDecoration(
                            label: 'Когда напомнить',
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
      showPawlySnackBar(
        context,
        message: 'Дождитесь окончания загрузки файлов.',
        tone: PawlySnackBarTone.error,
      );
      return;
    }

    Navigator.of(context).pop(
      UpsertProcedureInput(
        status: _status,
        procedureTypeId: _selectedProcedureTypeId,
        procedureTypeName: _procedureTypeSelection == 'custom'
            ? nonEmptyHealthText(_customProcedureTypeController.text)
            : null,
        title: _titleController.text.trim(),
        description: nonEmptyHealthText(_descriptionController.text),
        productName: nonEmptyHealthText(_productNameController.text),
        scheduledAtIso: _scheduledAt?.toIso8601String(),
        performedAtIso: _performedAt?.toIso8601String(),
        nextDueAtIso: _nextDueAt?.toIso8601String(),
        notes: nonEmptyHealthText(_notesController.text),
        attachments: _attachmentInputs(),
        reminder: _status == 'PLANNED' && _shouldSendReminder
            ? HealthEntityReminderInput(
                pushEnabled: _pushEnabled,
                remindOffsetMinutes:
                    _pushEnabled ? (_remindOffsetMinutes ?? 0) : null,
              )
            : null,
        rowVersion: widget.initialProcedure?.rowVersion,
      ),
    );
  }

  void _setAttachments(List<AttachmentDraftItem> attachments) {
    if (!mounted) {
      return;
    }
    setState(() {
      _attachments
        ..clear()
        ..addAll(attachments);
    });
  }

  void _setUploadingAttachments(bool value) {
    if (!mounted || _isUploadingAttachments == value) {
      return;
    }
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
}

class _ProcedureTypeField extends StatelessWidget {
  const _ProcedureTypeField({
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
      decoration: healthFormRowDecoration(label: 'Тип процедуры'),
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
