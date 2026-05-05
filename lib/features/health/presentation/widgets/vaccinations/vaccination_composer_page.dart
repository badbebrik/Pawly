import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/health_models.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../shared/attachments/data/attachment_input.dart';
import '../../../../shared/attachments/models/attachment_draft_item.dart';
import '../../../../shared/attachments/presentation/widgets/attachment_upload_field.dart';
import '../../../models/shared/health_inputs.dart';
import '../../../models/vaccinations/vaccination_inputs.dart';
import '../../../shared/formatters/health_display_formatters.dart';
import '../../../shared/formatters/health_status_formatters.dart';
import '../form/health_form_fields.dart';
import '../shared/health_common_widgets.dart';
import '../shared/health_date_pickers.dart';
import 'vaccination_targets_picker.dart';

class VaccinationComposerPage extends StatelessWidget {
  const VaccinationComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.vaccinationTargets,
    this.initialVaccination,
    this.title = 'Новая вакцинация',
    this.submitLabel = 'Сохранить вакцинацию',
    super.key,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<HealthDictionaryItem> vaccinationTargets;
  final Vaccination? initialVaccination;
  final String title;
  final String submitLabel;

  @override
  Widget build(BuildContext context) {
    return PawlyScreenScaffold(
      title: title,
      body: _VaccinationComposerSheet(
        petId: petId,
        allowedStatuses: allowedStatuses,
        vaccinationTargets: vaccinationTargets,
        initialVaccination: initialVaccination,
        title: title,
        submitLabel: submitLabel,
        showHeader: false,
      ),
    );
  }
}

class _VaccinationComposerSheet extends ConsumerStatefulWidget {
  const _VaccinationComposerSheet({
    required this.petId,
    required this.allowedStatuses,
    required this.vaccinationTargets,
    this.initialVaccination,
    this.title = 'Новая вакцинация',
    this.submitLabel = 'Сохранить вакцинацию',
    this.showHeader = true,
  });

  final String petId;
  final List<String> allowedStatuses;
  final List<HealthDictionaryItem> vaccinationTargets;
  final Vaccination? initialVaccination;
  final String title;
  final String submitLabel;
  final bool showHeader;

  @override
  ConsumerState<_VaccinationComposerSheet> createState() =>
      _VaccinationComposerSheetState();
}

class _VaccinationComposerSheetState
    extends ConsumerState<_VaccinationComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clinicController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();
  final List<AttachmentDraftItem> _attachments = <AttachmentDraftItem>[];
  final Set<String> _selectedTargetIds = <String>{};
  final List<String> _customTargetNames = <String>[];

  late String _status;
  DateTime? _scheduledAt;
  DateTime? _administeredAt;
  DateTime? _nextDueAt;
  bool _pushEnabled = true;
  int? _remindOffsetMinutes = 0;
  late bool _shouldSendReminder;
  bool _isUploadingAttachments = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialVaccination;
    final allowedStatuses = _allowedStatuses;
    _status = initial == null
        ? (allowedStatuses.contains('PLANNED')
            ? 'PLANNED'
            : allowedStatuses.first)
        : initial.status;
    _nameController.text = initial?.vaccineName ?? '';
    _clinicController.text = initial?.clinicName ?? '';
    _vetController.text = initial?.vetName ?? '';
    _notesController.text = initial?.notes ?? '';
    _selectedTargetIds.addAll(
      initial?.targets.map((target) => target.id) ?? const <String>[],
    );
    _scheduledAt = initial?.scheduledAt;
    _administeredAt = initial?.administeredAt;
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
    _nameController.dispose();
    _clinicController.dispose();
    _vetController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  List<HealthDictionaryItem> get _targetItems {
    final byId = <String, HealthDictionaryItem>{};
    for (final item in widget.vaccinationTargets) {
      if (!item.isArchived) {
        byId[item.id] = item;
      }
    }
    for (final item in widget.initialVaccination?.targets ??
        const <HealthDictionaryItem>[]) {
      byId[item.id] = item;
    }
    return byId.values.toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
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
                  const SizedBox(height: PawlySpacing.xs),
                  Text(
                    'Запланируйте прививку или сразу внесите выполненную вакцинацию.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              label: formatVaccinationStatusLabel(status),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyListSection(
                  title: 'Вакцина',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    HealthFormTextField(
                      controller: _nameController,
                      label: 'Название вакцины',
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Введите название вакцины';
                        }
                        return null;
                      },
                    ),
                    VaccinationTargetPickerRow(
                      targets: _targetItems,
                      selectedIds: _selectedTargetIds,
                      customNames: _customTargetNames,
                      onTap: _openTargetsSheet,
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
                        if (_status != 'COMPLETED')
                          HealthDateButton(
                            label: _scheduledAt == null
                                ? 'Дата и время по плану'
                                : 'Дата и время по плану: ${formatHealthDateTime(_scheduledAt!)}',
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
                        if (_status == 'COMPLETED') ...<Widget>[
                          if (_scheduledAt != null) ...<Widget>[
                            PawlyListTile(
                              title: 'Дата и время по плану',
                              subtitle: formatHealthDateTime(_scheduledAt!),
                              leadingIcon: Icons.schedule_rounded,
                              trailing: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _scheduledAt = null;
                                  });
                                },
                                child: const Text('Сбросить'),
                              ),
                            ),
                            const SizedBox(height: PawlySpacing.sm),
                          ],
                          HealthDateButton(
                            label: _administeredAt == null
                                ? 'Дата и время выполнения'
                                : 'Дата и время выполнения: ${formatHealthDateTime(_administeredAt!)}',
                            onTap: () async {
                              final picked = await pickHealthDateTime(
                                context,
                                initialDate: _administeredAt ??
                                    _scheduledAt ??
                                    DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() => _administeredAt = picked);
                              }
                            },
                          ),
                          const SizedBox(height: PawlySpacing.sm),
                          HealthDateButton(
                            label: _nextDueAt == null
                                ? 'Дата и время ревакцинации'
                                : 'Дата и время ревакцинации: ${formatHealthDateTime(_nextDueAt!)}',
                            onTap: () async {
                              final picked = await pickHealthDateTime(
                                context,
                                initialDate: _nextDueAt ?? DateTime.now(),
                                firstDate: _administeredAt ?? DateTime.now(),
                              );
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
                  title: 'Заметки',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    HealthFormTextField(
                      controller: _notesController,
                      label: 'Заметки',
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
                const SizedBox(height: PawlySpacing.lg),
                AttachmentUploadField(
                  petId: widget.petId,
                  entityType: 'VACCINATION',
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
                    padding: const EdgeInsets.all(PawlySpacing.md),
                    children: <Widget>[
                      Column(
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

  Future<void> _openTargetsSheet() async {
    final result = await showModalBottomSheet<VaccinationTargetSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => VaccinationTargetsSheet(
        targets: _targetItems,
        selectedIds: _selectedTargetIds,
        customNames: _customTargetNames,
      ),
    );

    if (result == null || !mounted) {
      return;
    }

    setState(() {
      _selectedTargetIds
        ..clear()
        ..addAll(result.selectedIds);
      _customTargetNames
        ..clear()
        ..addAll(result.customNames);
    });
  }

  List<HealthDictionaryRefInput> _targetInputs() {
    return <HealthDictionaryRefInput>[
      ..._selectedTargetIds.map((id) => HealthDictionaryRefInput(id: id)),
      ..._customTargetNames.map((name) => HealthDictionaryRefInput(name: name)),
    ];
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_status == 'COMPLETED' && _administeredAt == null) {
      showPawlySnackBar(
        context,
        message: 'Укажите дату и время выполнения вакцинации.',
        tone: PawlySnackBarTone.error,
      );
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
      UpsertVaccinationInput(
        status: _status,
        vaccineName: _nameController.text.trim(),
        targets: _targetInputs(),
        scheduledAtIso: _scheduledAt?.toIso8601String(),
        administeredAtIso: _administeredAt?.toIso8601String(),
        nextDueAtIso: _nextDueAt?.toIso8601String(),
        clinicName: _emptyToNull(_clinicController.text),
        vetName: _emptyToNull(_vetController.text),
        notes: _emptyToNull(_notesController.text),
        attachments: _attachmentInputs(),
        reminder: _status == 'PLANNED' && _shouldSendReminder
            ? HealthEntityReminderInput(
                pushEnabled: _pushEnabled,
                remindOffsetMinutes:
                    _pushEnabled ? (_remindOffsetMinutes ?? 0) : null,
              )
            : null,
        rowVersion: widget.initialVaccination?.rowVersion,
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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
