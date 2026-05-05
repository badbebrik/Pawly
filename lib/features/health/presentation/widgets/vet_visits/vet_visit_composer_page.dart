import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../logs/models/log_models.dart';
import '../../../../shared/attachments/data/attachment_input.dart';
import '../../../../shared/attachments/models/attachment_draft_item.dart';
import '../../../../shared/attachments/presentation/widgets/attachment_upload_field.dart';
import '../../../models/shared/health_inputs.dart';
import '../../../models/vet_visits/vet_visit_inputs.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../form/health_form_fields.dart';
import '../shared/health_common_widgets.dart';
import '../shared/health_date_pickers.dart';
import 'vet_visit_log_picker_sheet.dart';
import 'vet_visit_selected_logs_section.dart';

class VetVisitComposerPage extends StatelessWidget {
  const VetVisitComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypes,
    this.initialVisit,
    this.title = 'Новый визит',
    this.submitLabel = 'Сохранить визит',
    super.key,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<String> allowedTypes;
  final VetVisit? initialVisit;
  final String title;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return PawlyScreenScaffold(
      title: title,
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
  final _titleController = TextEditingController();
  final _clinicController = TextEditingController();
  final _vetController = TextEditingController();
  final _reasonController = TextEditingController();
  final _resultController = TextEditingController();
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];
  final List<LogListItem> _selectedLogs = <LogListItem>[];

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
    final allowedStatuses = _allowedStatuses;
    _status = initial == null
        ? (allowedStatuses.contains('PLANNED')
            ? 'PLANNED'
            : allowedStatuses.first)
        : initial.status;
    _visitType = initial?.visitType ??
        (widget.allowedTypes.contains('CHECKUP')
            ? 'CHECKUP'
            : widget.allowedTypes.first);
    _titleController.text = initial?.title ?? '';
    _clinicController.text = initial?.clinicName ?? '';
    _vetController.text = initial?.vetName ?? '';
    _reasonController.text = initial?.reasonText ?? '';
    _resultController.text = initial?.resultText ?? '';
    _scheduledAt = initial?.scheduledAt;
    _completedAt = initial?.completedAt;
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
    for (final status in widget.allowedStatuses) {
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
                              label: formatVetVisitStatusLabel(status),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Визит',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _VetVisitTypeField(
                      value: _visitType,
                      allowedTypes: widget.allowedTypes,
                      onChanged: (value) => setState(() => _visitType = value),
                    ),
                    HealthFormTextField(
                      controller: _titleController,
                      label: 'Название',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                if (widget.initialVisit == null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.lg),
                  VetVisitSelectedLogsSection(
                    logs: _selectedLogs,
                    onAddLog: _pickRelatedLog,
                    onRemoveLog: _removeRelatedLog,
                  ),
                ],
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
                              ? 'Дата визита'
                              : 'Дата визита: ${formatHealthDateTime(_scheduledAt!)}',
                          onTap: () async {
                            final picked = await pickHealthDateTime(
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
                          HealthDateButton(
                            label: _completedAt == null
                                ? 'Дата завершения'
                                : 'Дата завершения: ${formatHealthDateTime(_completedAt!)}',
                            onTap: () async {
                              final picked = await pickHealthDateTime(
                                context,
                                initialDate: _completedAt ??
                                    _scheduledAt ??
                                    DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _completedAt = picked);
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
                  title: 'Клиника',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    HealthFormTextField(
                      controller: _clinicController,
                      label: 'Клиника',
                      textCapitalization: TextCapitalization.words,
                    ),
                    HealthFormTextField(
                      controller: _vetController,
                      label: 'Ветеринар',
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Причина',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    HealthFormTextField(
                      controller: _reasonController,
                      label: 'Причина визита',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                if (_status != 'PLANNED') ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  PawlyListSection(
                    title: 'Результат',
                    padding: EdgeInsets.zero,
                    children: <Widget>[
                      HealthFormTextField(
                        controller: _resultController,
                        label: 'Результат визита',
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: PawlySpacing.lg),
                AttachmentUploadField(
                  petId: widget.petId,
                  entityType: 'VET_VISIT',
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
      UpsertVetVisitInput(
        status: _status,
        visitType: _visitType,
        title: nonEmptyHealthText(_titleController.text),
        scheduledAtIso: _scheduledAt?.toIso8601String(),
        completedAtIso: _completedAt?.toIso8601String(),
        clinicName: nonEmptyHealthText(_clinicController.text),
        vetName: nonEmptyHealthText(_vetController.text),
        reasonText: nonEmptyHealthText(_reasonController.text),
        resultText: nonEmptyHealthText(_resultController.text),
        attachments: _attachmentInputs(),
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

  Future<void> _pickRelatedLog() async {
    final selected = await showModalBottomSheet<LogListItem>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => VetVisitLogPickerSheet(
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

class _VetVisitTypeField extends StatelessWidget {
  const _VetVisitTypeField({
    required this.value,
    required this.allowedTypes,
    required this.onChanged,
  });

  final String value;
  final List<String> allowedTypes;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: healthFormRowDecoration(label: 'Тип визита'),
      items: allowedTypes
          .map(
            (type) => DropdownMenuItem<String>(
              value: type,
              child: Text(formatVetVisitTypeLabel(type)),
            ),
          )
          .toList(growable: false),
      onChanged: (value) {
        if (value == null) {
          return;
        }
        onChanged(value);
      },
    );
  }
}
