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
import '../providers/pet_vaccinations_controller.dart';
import '../widgets/health_attachments_field.dart';
import '../widgets/health_common_widgets.dart';

class PetVaccinationsPage extends ConsumerStatefulWidget {
  const PetVaccinationsPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetVaccinationsPage> createState() =>
      _PetVaccinationsPageState();
}

class _PetVaccinationsPageState extends ConsumerState<PetVaccinationsPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  VaccinationBucket _selectedBucket = VaccinationBucket.planned;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      petVaccinationsControllerProvider(widget.petId),
    );

    return PawlyScreenScaffold(
      title: 'Вакцинации',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новая вакцина',
              tooltip: 'Добавить вакцинацию',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => _VaccinationsContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petVaccinationsControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petVaccinationsControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
          onMarkDone: _handleMarkDone,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _VaccinationsErrorView(
          onRetry: () => ref
              .read(petVaccinationsControllerProvider(widget.petId).notifier)
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
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petVaccinationsControllerProvider(widget.petId)).value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertVaccinationInput>(
      MaterialPageRoute<UpsertVaccinationInput>(
        builder: (context) => _VaccinationComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.vaccinationStatuses,
          vaccinationTargets: state.bootstrap.enums.vaccinationTargets,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .createVaccination(input: input);
      _invalidateHealthDerivedData(ref, widget.petId);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Вакцинация сохранена.')),
      );
      setState(
        () => _selectedBucket = input.status == 'PLANNED'
            ? VaccinationBucket.planned
            : VaccinationBucket.history,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    }
  }

  Future<void> _handleMarkDone(VaccinationCard card) async {
    final administeredAt = await showDialog<DateTime>(
      context: context,
      builder: (context) => _CompletionDateDialog(
        initialDate: card.scheduledAt ?? DateTime.now(),
      ),
    );
    if (administeredAt == null || !mounted) {
      return;
    }

    try {
      final updated = await ref
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .markVaccinationDone(
            vaccinationId: card.id,
            administeredAt: administeredAt,
          );
      _invalidateHealthDerivedData(ref, widget.petId);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Вакцина "${card.vaccineName}" отмечена выполненной.'),
        ),
      );

      final nextDueAt = await showDialog<DateTime>(
        context: context,
        builder: (context) => _RevaccinationDateDialog(
          initialDate: _defaultRevaccinationDate(administeredAt),
        ),
      );
      if (nextDueAt == null || !mounted) {
        setState(() => _selectedBucket = VaccinationBucket.history);
        return;
      }

      await ref
          .read(petVaccinationsControllerProvider(widget.petId).notifier)
          .setRevaccinationDate(
            vaccination: updated,
            nextDueAt: nextDueAt,
          );
      _invalidateHealthDerivedData(ref, widget.petId);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Дата и время ревакцинации сохранены: ${_formatDate(nextDueAt)}.',
          ),
        ),
      );
      setState(() => _selectedBucket = VaccinationBucket.planned);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage(error))),
      );
    }
  }

  DateTime _defaultRevaccinationDate(DateTime value) {
    return DateTime(
      value.year + 1,
      value.month,
      value.day,
      value.hour,
      value.minute,
    );
  }

  String _errorMessage(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }

    return 'Не удалось выполнить действие с вакцинацией.';
  }
}

class _VaccinationComposerPage extends StatelessWidget {
  const _VaccinationComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.vaccinationTargets,
    this.initialVaccination,
    this.title = 'Новая вакцинация',
    this.submitLabel = 'Сохранить вакцинацию',
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

class _VaccinationsContent extends StatelessWidget {
  const _VaccinationsContent({
    required this.petId,
    required this.state,
    required this.searchController,
    required this.selectedBucket,
    required this.onSearchChanged,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
    required this.onMarkDone,
  });

  final String petId;
  final PetVaccinationsState state;
  final TextEditingController searchController;
  final VaccinationBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<VaccinationBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<VaccinationCard> onMarkDone;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _VaccinationsNoAccessView(onRetry: () {
        onRetry();
      });
    }

    final items = state.itemsFor(selectedBucket);
    final isPlanned = selectedBucket == VaccinationBucket.planned;

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
            hintText: 'Вакцина, клиника, врач',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<VaccinationBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<VaccinationBucket>>[
              HealthBucketOption<VaccinationBucket>(
                value: VaccinationBucket.planned,
                label: 'План',
                count: state.plannedItems.length,
              ),
              HealthBucketOption<VaccinationBucket>(
                value: VaccinationBucket.history,
                label: 'История',
                count: state.historyItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            _VaccinationsInlineMessage(
              title: isPlanned ? 'Плановых вакцинаций нет' : 'История пуста',
              message: isPlanned
                  ? 'Добавьте первую запись, чтобы не потерять дату прививки.'
                  : 'Выполненные вакцинации появятся здесь.',
            )
          else
            ...items.map(
              (item) => _VaccinationListCard(
                petId: petId,
                item: item,
                canWrite: state.canWrite,
                isBusy: state.busyVaccinationIds.contains(item.id),
                onMarkDone:
                    item.status == 'PLANNED' ? () => onMarkDone(item) : null,
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

class _VaccinationListCard extends StatelessWidget {
  const _VaccinationListCard({
    required this.petId,
    required this.item,
    required this.canWrite,
    required this.isBusy,
    this.onMarkDone,
  });

  final String petId;
  final VaccinationCard item;
  final bool canWrite;
  final bool isBusy;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = _primaryDateLabel(item);
    final chips = <Widget>[
      if (item.status != 'PLANNED')
        PawlyBadge(
          label: _statusLabel(item.status),
          tone: _statusTone(item.status),
        ),
      for (final target in item.targets)
        PawlyBadge(
          label: target.name,
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
            'petVaccinationDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'vaccinationId': item.id,
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
                        item.vaccineName,
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
                if ((item.notesPreview ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    item.notesPreview!.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ],
                if (chips.isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Wrap(
                    spacing: PawlySpacing.xs,
                    runSpacing: PawlySpacing.xs,
                    children: chips,
                  ),
                ],
                if (onMarkDone != null && canWrite) ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  PawlyButton(
                    label: isBusy ? 'Сохраняем...' : 'Отметить выполненной',
                    onPressed: isBusy ? null : onMarkDone,
                    fullWidth: false,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _primaryDateLabel(VaccinationCard item) {
    final date = switch (item.status) {
      'COMPLETED' => item.administeredAt ?? item.scheduledAt,
      _ => item.scheduledAt,
    };

    if (date == null) {
      return null;
    }

    final prefix = switch (item.status) {
      'COMPLETED' => 'Сделано',
      _ => 'Запланировано',
    };
    return '$prefix ${_formatDate(date)}';
  }
}

class _VaccinationsInlineMessage extends StatelessWidget {
  const _VaccinationsInlineMessage({
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
      initial?.attachments.map(AttachmentDraftItem.fromHealthAttachment) ??
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
                              label: _statusLabel(status),
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
                    _VaccinationFormTextField(
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
                    _VaccinationTargetPickerRow(
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
                                : 'Дата и время по плану: ${_formatDateTime(_scheduledAt!)}',
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
                        if (_status == 'COMPLETED') ...<Widget>[
                          if (_scheduledAt != null) ...<Widget>[
                            PawlyListTile(
                              title: 'Дата и время по плану',
                              subtitle: _formatDateTime(_scheduledAt!),
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
                                : 'Дата и время выполнения: ${_formatDateTime(_administeredAt!)}',
                            onTap: () async {
                              final picked = await _pickDateTime(
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
                                : 'Дата и время ревакцинации: ${_formatDateTime(_nextDueAt!)}',
                            onTap: () async {
                              final picked = await _pickDateTime(
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
                    _VaccinationFormTextField(
                      controller: _clinicController,
                      label: 'Клиника',
                      textCapitalization: TextCapitalization.words,
                    ),
                    _VaccinationFormTextField(
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
                    _VaccinationFormTextField(
                      controller: _notesController,
                      label: 'Заметки',
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
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
    final result = await showModalBottomSheet<_VaccinationTargetSelection>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VaccinationTargetsSheet(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Укажите дату и время выполнения вакцинации.'),
        ),
      );
      return;
    }

    if (_isUploadingAttachments) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дождитесь окончания загрузки файлов.')),
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
          .uploadFiles(widget.petId, files: files, entityType: 'VACCINATION');
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
      final uploaded = await ref
          .read(healthFileUploadServiceProvider)
          .uploadXFiles(widget.petId, files: files, entityType: 'VACCINATION');
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

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _VaccinationFormTextField extends StatelessWidget {
  const _VaccinationFormTextField({
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
      decoration: InputDecoration(
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
      ),
    );
  }
}

class _VaccinationTargetPickerRow extends StatelessWidget {
  const _VaccinationTargetPickerRow({
    required this.targets,
    required this.selectedIds,
    required this.customNames,
    required this.onTap,
  });

  final List<HealthDictionaryItem> targets;
  final Set<String> selectedIds;
  final List<String> customNames;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedLabels = _selectedTargetLabels();
    final summary = switch (selectedLabels.length) {
      0 => 'Не выбраны',
      1 => selectedLabels.first,
      2 => selectedLabels.join(', '),
      _ => '${selectedLabels.length} целей',
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Цели вакцинации',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxxs),
                    Text(
                      summary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: selectedLabels.isEmpty
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurface,
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

  List<String> _selectedTargetLabels() {
    final labels = <String>[
      for (final target in targets)
        if (selectedIds.contains(target.id)) target.name,
      ...customNames,
    ];
    return labels;
  }
}

class _VaccinationTargetSelection {
  const _VaccinationTargetSelection({
    required this.selectedIds,
    required this.customNames,
  });

  final Set<String> selectedIds;
  final List<String> customNames;
}

class _VaccinationTargetsSheet extends StatefulWidget {
  const _VaccinationTargetsSheet({
    required this.targets,
    required this.selectedIds,
    required this.customNames,
  });

  final List<HealthDictionaryItem> targets;
  final Set<String> selectedIds;
  final List<String> customNames;

  @override
  State<_VaccinationTargetsSheet> createState() =>
      _VaccinationTargetsSheetState();
}

class _VaccinationTargetsSheetState extends State<_VaccinationTargetsSheet> {
  final _searchController = TextEditingController();
  final _customController = TextEditingController();
  late final Set<String> _selectedIds = <String>{...widget.selectedIds};
  late final List<String> _customNames = <String>[...widget.customNames];
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final filteredTargets = _filteredTargets();

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PawlySpacing.lg,
                  0,
                  PawlySpacing.lg,
                  PawlySpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Цели вакцинации',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.md),
                    PawlyTextField(
                      controller: _searchController,
                      hintText: 'Найти цель',
                      prefixIcon: const Icon(Icons.search_rounded),
                      onChanged: (value) {
                        setState(() => _searchQuery = value.trim());
                      },
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: PawlyTextField(
                            controller: _customController,
                            hintText: 'Своя цель',
                            textCapitalization: TextCapitalization.sentences,
                            onFieldSubmitted: (_) => _addCustomTarget(),
                          ),
                        ),
                        const SizedBox(width: PawlySpacing.sm),
                        IconButton.filledTonal(
                          onPressed: _addCustomTarget,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Добавить цель',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    if (_customNames.isNotEmpty) ...<Widget>[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          PawlySpacing.lg,
                          0,
                          PawlySpacing.lg,
                          PawlySpacing.xs,
                        ),
                        child: Text(
                          'Свои цели',
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      for (final name in _customNames)
                        _VaccinationCustomTargetRow(
                          name: name,
                          onRemove: () {
                            setState(() => _customNames.remove(name));
                          },
                        ),
                    ],
                    if (filteredTargets.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(PawlySpacing.lg),
                        child: Text(
                          'Подходящих целей нет.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    else
                      for (final target in filteredTargets)
                        CheckboxListTile(
                          value: _selectedIds.contains(target.id),
                          onChanged: (_) => _toggleTarget(target.id),
                          title: Text(target.name),
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PawlySpacing.lg,
                  PawlySpacing.sm,
                  PawlySpacing.lg,
                  PawlySpacing.lg,
                ),
                child: PawlyButton(
                  label: 'Готово',
                  onPressed: () {
                    Navigator.of(context).pop(
                      _VaccinationTargetSelection(
                        selectedIds: _selectedIds,
                        customNames: _customNames,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<HealthDictionaryItem> _filteredTargets() {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) {
      return widget.targets;
    }
    return widget.targets
        .where((target) => target.name.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _toggleTarget(String targetId) {
    setState(() {
      if (_selectedIds.contains(targetId)) {
        _selectedIds.remove(targetId);
      } else {
        _selectedIds.add(targetId);
      }
    });
  }

  void _addCustomTarget() {
    final name = _customController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final exists = _customNames.any(
          (item) => item.toLowerCase() == name.toLowerCase(),
        ) ||
        widget.targets.any(
          (item) => item.name.toLowerCase() == name.toLowerCase(),
        );
    setState(() {
      if (!exists) {
        _customNames.add(name);
      }
      _customController.clear();
    });
  }
}

class _VaccinationCustomTargetRow extends StatelessWidget {
  const _VaccinationCustomTargetRow({
    required this.name,
    required this.onRemove,
  });

  final String name;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle_rounded),
      title: Text(name),
      trailing: IconButton(
        onPressed: onRemove,
        icon: const Icon(Icons.close_rounded),
        tooltip: 'Удалить цель',
      ),
    );
  }
}

class _CompletionDateDialog extends StatefulWidget {
  const _CompletionDateDialog({
    required this.initialDate,
  });

  final DateTime initialDate;

  @override
  State<_CompletionDateDialog> createState() => _CompletionDateDialogState();
}

class _CompletionDateDialogState extends State<_CompletionDateDialog> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Отметить выполненной'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('Укажите дату и время, когда вакцинация была выполнена.'),
          const SizedBox(height: PawlySpacing.md),
          Text(
            _formatDateTime(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: PawlySpacing.sm),
          TextButton.icon(
            onPressed: () async {
              final picked = await _pickDateTime(
                context,
                initialDate: _selectedDate,
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.event_rounded),
            label: const Text('Изменить дату и время'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _RevaccinationDateDialog extends StatefulWidget {
  const _RevaccinationDateDialog({
    required this.initialDate,
  });

  final DateTime initialDate;

  @override
  State<_RevaccinationDateDialog> createState() =>
      _RevaccinationDateDialogState();
}

class _RevaccinationDateDialogState extends State<_RevaccinationDateDialog> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Дата и время ревакцинации'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Следующую прививку можно запланировать сразу. Если дата пока неизвестна, пропустите шаг.',
          ),
          const SizedBox(height: PawlySpacing.md),
          if (_selectedDate != null)
            Text(
              _formatDateTime(_selectedDate!),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          const SizedBox(height: PawlySpacing.sm),
          TextButton.icon(
            onPressed: () async {
              final picked = await _pickDateTime(
                context,
                initialDate: _selectedDate ?? widget.initialDate,
                firstDate: widget.initialDate,
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Выбрать дату и время'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Пропустить'),
        ),
        FilledButton(
          onPressed: _selectedDate == null
              ? null
              : () => Navigator.of(context).pop(_selectedDate),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class PetVaccinationDetailsPage extends ConsumerWidget {
  const PetVaccinationDetailsPage({
    required this.petId,
    required this.vaccinationId,
    super.key,
  });

  final String petId;
  final String vaccinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vaccinationRef = PetVaccinationRef(
      petId: petId,
      vaccinationId: vaccinationId,
    );
    final vaccinationAsync = ref.watch(
      petVaccinationDetailsProvider(vaccinationRef),
    );

    return PawlyScreenScaffold(
      title: 'Вакцина',
      actions: vaccinationAsync.maybeWhen(
        data: (vaccination) => <Widget>[
          if (vaccination.canEdit)
            IconButton(
              onPressed: () => _editVaccination(context, ref, vaccination),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (vaccination.canDelete)
            IconButton(
              onPressed: () => _deleteVaccination(context, ref, vaccination),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: vaccinationAsync.when(
        data: (vaccination) => _VaccinationDetailsView(
          vaccination: vaccination,
          onRefresh: () async {
            ref.invalidate(petVaccinationDetailsProvider(vaccinationRef));
            await ref
                .read(petVaccinationDetailsProvider(vaccinationRef).future);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _VaccinationsErrorView(
          onRetry: () => ref.invalidate(
            petVaccinationDetailsProvider(vaccinationRef),
          ),
        ),
      ),
    );
  }

  Future<void> _editVaccination(
    BuildContext context,
    WidgetRef ref,
    Vaccination vaccination,
  ) async {
    final enums = ref
        .read(petVaccinationsControllerProvider(petId))
        .asData
        ?.value
        .bootstrap
        .enums;
    final statuses =
        enums?.vaccinationStatuses ?? const <String>['PLANNED', 'COMPLETED'];
    final targets = enums?.vaccinationTargets ?? const <HealthDictionaryItem>[];

    final input = await Navigator.of(context).push<UpsertVaccinationInput>(
      MaterialPageRoute<UpsertVaccinationInput>(
        builder: (context) => _VaccinationComposerPage(
          petId: petId,
          allowedStatuses: statuses,
          vaccinationTargets: targets,
          initialVaccination: vaccination,
          title: 'Редактировать вакцинацию',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(petVaccinationsControllerProvider(petId).notifier)
          .updateVaccination(
            vaccinationId: vaccinationId,
            input: input,
          );
      ref.invalidate(
        petVaccinationDetailsProvider(
          PetVaccinationRef(petId: petId, vaccinationId: vaccinationId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменения сохранены.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_mutationErrorMessage(
                error, 'Не удалось обновить вакцинацию.'))),
      );
    }
  }

  Future<void> _deleteVaccination(
    BuildContext context,
    WidgetRef ref,
    Vaccination vaccination,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Удалить вакцинацию?'),
              content: const Text(
                'Запись о вакцинации будет удалена. Это действие нельзя отменить.',
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
            );
          },
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      await ref
          .read(petVaccinationsControllerProvider(petId).notifier)
          .deleteVaccination(
            vaccinationId: vaccination.id,
            rowVersion: vaccination.rowVersion,
          );
      ref.invalidate(
        petVaccinationDetailsProvider(
          PetVaccinationRef(petId: petId, vaccinationId: vaccinationId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      if (!context.mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(_mutationErrorMessage(
                error, 'Не удалось удалить вакцинацию.'))),
      );
    }
  }
}

class _VaccinationDetailsView extends StatelessWidget {
  const _VaccinationDetailsView({
    required this.vaccination,
    required this.onRefresh,
  });

  final Vaccination vaccination;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canMutate = vaccination.canEdit || vaccination.canDelete;
    final mainRows = <Widget>[
      if (_dateValue(vaccination.scheduledAt) case final value?)
        HealthDetailsRow(
          label: 'По плану',
          value: value,
        ),
      if (_dateValue(vaccination.administeredAt) case final value?)
        HealthDetailsRow(
          label: 'Выполнена',
          value: value,
        ),
      if (_dateValue(vaccination.nextDueAt) case final value?)
        HealthDetailsRow(
          label: 'Ревакцинация',
          value: value,
        ),
      if (vaccination.targets.isNotEmpty)
        HealthDetailsRow(
          label: 'Цели',
          value: vaccination.targets.map((target) => target.name).join(', '),
        ),
      if (_textValue(vaccination.clinicName) case final value?)
        HealthDetailsRow(
          label: 'Клиника',
          value: value,
        ),
      if (_textValue(vaccination.vetName) case final value?)
        HealthDetailsRow(
          label: 'Врач',
          value: value,
        ),
    ];
    final notes = vaccination.notes?.trim() ?? '';

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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor(vaccination.status)
                              .withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.vaccines_rounded,
                          color: _statusColor(vaccination.status),
                        ),
                      ),
                      const SizedBox(width: PawlySpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              vaccination.vaccineName,
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
                                  label: _statusLabel(vaccination.status),
                                  tone: _statusTone(vaccination.status),
                                ),
                                if (!canMutate)
                                  const PawlyBadge(
                                    label: 'Только просмотр',
                                    tone: PawlyBadgeTone.warning,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (mainRows.isNotEmpty)
            HealthDetailsSection(
              title: 'Основное',
              children: mainRows,
            ),
          if (notes.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Заметки',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(
                    notes,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (vaccination.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            Builder(
              builder: (context) {
                final viewerItems = vaccination.attachments
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
                    vaccination.attachments.length,
                    (index) {
                      final attachment = vaccination.attachments[index];
                      final viewerItem = viewerItems[index];
                      final imageIndex = imageItems.indexWhere(
                        (item) =>
                            item.url == viewerItem.url &&
                            item.title == viewerItem.title,
                      );

                      return _VaccinationAttachmentRow(
                        attachment: attachment,
                        viewerItem: viewerItem,
                        imageItems: imageItems,
                        imageIndex: imageIndex,
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
}

class _VaccinationAttachmentRow extends StatelessWidget {
  const _VaccinationAttachmentRow({
    required this.attachment,
    required this.viewerItem,
    required this.imageItems,
    required this.imageIndex,
  });

  final HealthAttachment attachment;
  final AttachmentViewerItem viewerItem;
  final List<AttachmentViewerItem> imageItems;
  final int imageIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openAttachmentUrl(
          context,
          fileId: attachment.fileId,
          fileType: attachment.fileType,
          fileName: viewerItem.title,
          previewUrl: attachment.previewUrl,
          downloadUrl: attachment.downloadUrl,
          imageGalleryItems: imageItems,
          initialImageIndex: imageIndex >= 0 ? imageIndex : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.md,
            vertical: PawlySpacing.sm,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.46),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  switch (viewerItem.kind) {
                    AttachmentKind.image => Icons.photo_rounded,
                    AttachmentKind.pdf => Icons.picture_as_pdf_rounded,
                    AttachmentKind.other => Icons.description_rounded,
                  },
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: PawlySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      viewerItem.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xxxs),
                    Text(
                      attachment.addedAt == null
                          ? attachment.fileType
                          : '${attachment.fileType} • ${_formatDate(attachment.addedAt!)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PawlySpacing.xs),
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

class _VaccinationsNoAccessView extends StatelessWidget {
  const _VaccinationsNoAccessView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: _VaccinationsInlineMessage(
          title: 'Нет доступа',
          message: 'У вас нет права просмотра вакцинаций этого питомца.',
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

class _VaccinationsErrorView extends StatelessWidget {
  const _VaccinationsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: _VaccinationsInlineMessage(
          title: 'Не удалось загрузить вакцинации',
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

Future<DateTime?> _pickDateTime(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
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

String? _dateValue(DateTime? value) {
  if (value == null) {
    return null;
  }
  return _formatDateTime(value);
}

String? _textValue(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

String _mutationErrorMessage(Object error, String fallback) {
  if (error is StateError) {
    return error.message.toString();
  }
  return fallback;
}

String _statusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирована',
    'COMPLETED' => 'Выполнена',
    _ => status,
  };
}

PawlyBadgeTone _statusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'COMPLETED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'PLANNED' => const Color(0xFF2B7FFF),
    'COMPLETED' => const Color(0xFF1C8D62),
    _ => const Color(0xFF94A3B8),
  };
}

void _invalidateHealthDerivedData(WidgetRef ref, String petId) {
  ref.invalidate(petHealthHomeProvider(petId));
  ref.invalidate(petLogsControllerProvider(petId));
  ref.invalidate(petAnalyticsMetricsProvider);
  ref.invalidate(petMetricSeriesProvider);
}
