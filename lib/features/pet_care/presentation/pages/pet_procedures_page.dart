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
import '../providers/pet_procedures_controller.dart';
import '../widgets/health_attachments_field.dart';
import '../widgets/health_common_widgets.dart';

class PetProceduresPage extends ConsumerStatefulWidget {
  const PetProceduresPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  ConsumerState<PetProceduresPage> createState() => _PetProceduresPageState();
}

class _PetProceduresPageState extends ConsumerState<PetProceduresPage> {
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  ProcedureBucket _selectedBucket = ProcedureBucket.planned;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(petProceduresControllerProvider(widget.petId));

    return PawlyScreenScaffold(
      title: 'Процедуры',
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? PawlyAddActionButton(
              label: 'Новая процедура',
              tooltip: 'Добавить процедуру',
              onTap: _openCreateSheet,
            )
          : null,
      body: stateAsync.when(
        data: (state) => _ProceduresContent(
          petId: widget.petId,
          state: state,
          searchController: _searchController,
          selectedBucket: _selectedBucket,
          onSearchChanged: _onSearchChanged,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
          onMarkDone: _handleMarkDone,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ProceduresErrorView(
          onRetry: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
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
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .setSearchQuery(value);
    });
  }

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petProceduresControllerProvider(widget.petId)).asData?.value;
    if (state == null) {
      return;
    }

    final input = await Navigator.of(context).push<UpsertProcedureInput>(
      MaterialPageRoute<UpsertProcedureInput>(
        builder: (context) => _ProcedureComposerPage(
          petId: widget.petId,
          allowedStatuses: state.bootstrap.enums.procedureStatuses,
          allowedTypeItems: state.bootstrap.enums.procedureTypeItems,
        ),
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .createProcedure(input: input);
      _invalidateHealthDerivedData(ref, widget.petId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Процедура сохранена.')),
      );
      setState(
        () => _selectedBucket = input.status == 'PLANNED'
            ? ProcedureBucket.planned
            : ProcedureBucket.history,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(error, 'Не удалось сохранить процедуру.'),
          ),
        ),
      );
    }
  }

  Future<void> _handleMarkDone(ProcedureCard card) async {
    final performedAt = await showDialog<DateTime>(
      context: context,
      builder: (context) => _ProcedureCompletionDateDialog(
        initialDate: card.scheduledAt ?? DateTime.now(),
      ),
    );
    if (performedAt == null || !mounted) {
      return;
    }

    try {
      final updated = await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .markProcedureDone(
            procedureId: card.id,
            performedAt: performedAt,
          );
      _invalidateHealthDerivedData(ref, widget.petId);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Процедура "${card.title}" отмечена выполненной.'),
        ),
      );

      final nextDueAt = await showDialog<DateTime>(
        context: context,
        builder: (context) => _NextProcedureDateDialog(
          initialDate: _defaultNextProcedureDate(performedAt),
        ),
      );
      if (nextDueAt == null || !mounted) {
        setState(() => _selectedBucket = ProcedureBucket.history);
        return;
      }

      await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .setNextProcedureDate(
            procedure: updated,
            nextDueAt: nextDueAt,
          );
      _invalidateHealthDerivedData(ref, widget.petId);
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Следующая процедура запланирована: ${_formatDate(nextDueAt)}.',
          ),
        ),
      );
      setState(() => _selectedBucket = ProcedureBucket.planned);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(error, 'Не удалось завершить процедуру.'),
          ),
        ),
      );
    }
  }

  DateTime _defaultNextProcedureDate(DateTime value) {
    return DateTime(
      value.year,
      value.month + 1,
      value.day,
      value.hour,
      value.minute,
    );
  }
}

class _ProcedureComposerPage extends StatelessWidget {
  const _ProcedureComposerPage({
    required this.petId,
    required this.allowedStatuses,
    required this.allowedTypeItems,
    this.initialProcedure,
    this.title = 'Новая процедура',
    this.submitLabel = 'Сохранить процедуру',
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

class _ProceduresContent extends StatelessWidget {
  const _ProceduresContent({
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
  final PetProceduresState state;
  final TextEditingController searchController;
  final ProcedureBucket selectedBucket;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ProcedureBucket> onBucketChanged;
  final Future<void> Function() onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<ProcedureCard> onMarkDone;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _ProceduresNoAccessView(onRetry: () {
        onRetry();
      });
    }

    final items = state.itemsFor(selectedBucket);
    final isPlanned = selectedBucket == ProcedureBucket.planned;

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
            hintText: 'Название, препарат, заметки',
            textInputAction: TextInputAction.search,
            prefixIcon: const Icon(Icons.search_rounded),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: PawlySpacing.md),
          HealthBucketSegment<ProcedureBucket>(
            selectedValue: selectedBucket,
            onChanged: onBucketChanged,
            options: <HealthBucketOption<ProcedureBucket>>[
              HealthBucketOption<ProcedureBucket>(
                value: ProcedureBucket.planned,
                label: 'План',
                count: state.plannedItems.length,
              ),
              HealthBucketOption<ProcedureBucket>(
                value: ProcedureBucket.history,
                label: 'История',
                count: state.historyItems.length,
              ),
            ],
          ),
          const SizedBox(height: PawlySpacing.md),
          if (items.isEmpty)
            _ProceduresInlineMessage(
              title:
                  isPlanned ? 'Запланированных процедур нет' : 'История пуста',
              message: isPlanned
                  ? 'Добавьте процедуру, чтобы не потерять дату выполнения.'
                  : 'Выполненные процедуры появятся здесь.',
            )
          else
            ...items.map(
              (item) => _ProcedureListCard(
                petId: petId,
                item: item,
                canWrite: state.canWrite,
                isBusy: state.busyProcedureIds.contains(item.id),
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

class _ProcedureListCard extends StatelessWidget {
  const _ProcedureListCard({
    required this.petId,
    required this.item,
    required this.canWrite,
    required this.isBusy,
    this.onMarkDone,
  });

  final String petId;
  final ProcedureCard item;
  final bool canWrite;
  final bool isBusy;
  final VoidCallback? onMarkDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateLabel = _primaryDateLabel(item);
    final productName = _nonEmpty(item.productName);
    final bodyText = _nonEmpty(item.descriptionPreview);
    final chips = <Widget>[
      if (item.status != 'PLANNED')
        PawlyBadge(
          label: _procedureStatusLabel(item.status),
          tone: _procedureStatusTone(item.status),
        ),
      PawlyBadge(
        label: _procedureTypeItemLabel(item.procedureTypeItem),
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
            'petProcedureDetails',
            pathParameters: <String, String>{
              'petId': petId,
              'procedureId': item.id,
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
                if (productName != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    productName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
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

  String? _primaryDateLabel(ProcedureCard item) {
    final date = switch (item.status) {
      'COMPLETED' => item.performedAt ?? item.scheduledAt,
      _ => item.scheduledAt,
    };
    if (date == null) {
      return null;
    }
    final prefix = switch (item.status) {
      'COMPLETED' => 'Выполнено',
      _ => 'Запланировано',
    };
    return '$prefix ${_formatDate(date)}';
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
                              label: _procedureStatusLabel(status),
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
                      _ProcedureFormTextField(
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
                    _ProcedureFormTextField(
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
                    _ProcedureFormTextField(
                      controller: _descriptionController,
                      label: 'Описание',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    _ProcedureFormTextField(
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
                        if (_status != 'PLANNED') ...<Widget>[
                          const SizedBox(height: PawlySpacing.sm),
                          HealthDateButton(
                            label: _performedAt == null
                                ? 'Дата и время выполнения'
                                : 'Дата и время выполнения: ${_formatDateTime(_performedAt!)}',
                            onTap: () async {
                              final picked = await _pickDateTime(
                                context,
                                initialDate: _performedAt ??
                                    _scheduledAt ??
                                    DateTime.now(),
                              );
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
                                : 'Дата и время повтора: ${_formatDateTime(_nextDueAt!)}',
                            onTap: () async {
                              final picked = await _pickDateTime(
                                context,
                                initialDate: _nextDueAt ??
                                    _performedAt ??
                                    _scheduledAt ??
                                    DateTime.now(),
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
                  title: 'Заметки',
                  padding: EdgeInsets.zero,
                  children: <Widget>[
                    _ProcedureFormTextField(
                      controller: _notesController,
                      label: 'Заметки',
                      maxLines: 3,
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
                          decoration: _procedureRowDecoration(
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Дождитесь окончания загрузки файлов.')),
      );
      return;
    }

    Navigator.of(context).pop(
      UpsertProcedureInput(
        status: _status,
        procedureTypeId: _selectedProcedureTypeId,
        procedureTypeName: _procedureTypeSelection == 'custom'
            ? _nonEmpty(_customProcedureTypeController.text)
            : null,
        title: _titleController.text.trim(),
        description: _nonEmpty(_descriptionController.text),
        productName: _nonEmpty(_productNameController.text),
        scheduledAtIso: _scheduledAt?.toIso8601String(),
        performedAtIso: _performedAt?.toIso8601String(),
        nextDueAtIso: _nextDueAt?.toIso8601String(),
        notes: _nonEmpty(_notesController.text),
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
          .uploadFiles(widget.petId, files: files, entityType: 'PROCEDURE');
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
          .uploadXFiles(widget.petId, files: files, entityType: 'PROCEDURE');
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
}

class _ProcedureFormTextField extends StatelessWidget {
  const _ProcedureFormTextField({
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
      decoration: _procedureRowDecoration(label: label),
    );
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
      decoration: _procedureRowDecoration(label: 'Тип процедуры'),
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

InputDecoration _procedureRowDecoration({required String label}) {
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

class _ProcedureCompletionDateDialog extends StatefulWidget {
  const _ProcedureCompletionDateDialog({
    required this.initialDate,
  });

  final DateTime initialDate;

  @override
  State<_ProcedureCompletionDateDialog> createState() =>
      _ProcedureCompletionDateDialogState();
}

class _ProcedureCompletionDateDialogState
    extends State<_ProcedureCompletionDateDialog> {
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
          const Text('Укажите дату и время, когда процедура была выполнена.'),
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

class _NextProcedureDateDialog extends StatefulWidget {
  const _NextProcedureDateDialog({
    required this.initialDate,
  });

  final DateTime initialDate;

  @override
  State<_NextProcedureDateDialog> createState() =>
      _NextProcedureDateDialogState();
}

class _NextProcedureDateDialogState extends State<_NextProcedureDateDialog> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Дата и время следующей процедуры'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Следующую процедуру можно запланировать сразу. Если дата пока неизвестна, пропустите шаг.',
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

class PetProcedureDetailsPage extends ConsumerWidget {
  const PetProcedureDetailsPage({
    required this.petId,
    required this.procedureId,
    super.key,
  });

  final String petId;
  final String procedureId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final procedureRef = PetProcedureRef(
      petId: petId,
      procedureId: procedureId,
    );
    final procedureAsync = ref.watch(petProcedureDetailsProvider(procedureRef));

    return PawlyScreenScaffold(
      title: 'Процедура',
      actions: procedureAsync.maybeWhen(
        data: (procedure) => <Widget>[
          if (procedure.canEdit)
            IconButton(
              onPressed: () => _editProcedure(context, ref, procedure),
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Редактировать',
            ),
          if (procedure.canDelete)
            IconButton(
              onPressed: () => _deleteProcedure(context, ref, procedure),
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Удалить',
            ),
        ],
        orElse: () => const <Widget>[],
      ),
      body: procedureAsync.when(
        data: (procedure) => _ProcedureDetailsView(
          procedure: procedure,
          onRefresh: () async {
            ref.invalidate(petProcedureDetailsProvider(procedureRef));
            await ref.read(petProcedureDetailsProvider(procedureRef).future);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _ProceduresErrorView(
          onRetry: () =>
              ref.invalidate(petProcedureDetailsProvider(procedureRef)),
        ),
      ),
    );
  }

  Future<void> _editProcedure(
    BuildContext context,
    WidgetRef ref,
    Procedure procedure,
  ) async {
    final state =
        ref.read(petProceduresControllerProvider(petId)).asData?.value;
    final input = await Navigator.of(context).push<UpsertProcedureInput>(
      MaterialPageRoute<UpsertProcedureInput>(
        builder: (context) => _ProcedureComposerPage(
          petId: petId,
          allowedStatuses: state?.bootstrap.enums.procedureStatuses ??
              const <String>['PLANNED', 'COMPLETED'],
          allowedTypeItems: state?.bootstrap.enums.procedureTypeItems ??
              const <HealthDictionaryItem>[],
          initialProcedure: procedure,
          title: 'Редактировать процедуру',
          submitLabel: 'Сохранить изменения',
        ),
      ),
    );
    if (input == null || !context.mounted) return;

    try {
      await ref
          .read(petProceduresControllerProvider(petId).notifier)
          .updateProcedure(
            procedureId: procedureId,
            input: input,
          );
      ref.invalidate(
        petProcedureDetailsProvider(
          PetProcedureRef(petId: petId, procedureId: procedureId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Изменения сохранены.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(error, 'Не удалось обновить процедуру.'),
          ),
        ),
      );
    }
  }

  Future<void> _deleteProcedure(
    BuildContext context,
    WidgetRef ref,
    Procedure procedure,
  ) async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Удалить процедуру?'),
            content: const Text(
              'Запись о процедуре будет удалена. Это действие нельзя отменить.',
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
          .read(petProceduresControllerProvider(petId).notifier)
          .deleteProcedure(
            procedureId: procedure.id,
            rowVersion: procedure.rowVersion,
          );
      ref.invalidate(
        petProcedureDetailsProvider(
          PetProcedureRef(petId: petId, procedureId: procedureId),
        ),
      );
      _invalidateHealthDerivedData(ref, petId);
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _mutationErrorMessage(error, 'Не удалось удалить процедуру.'),
          ),
        ),
      );
    }
  }
}

class _ProcedureDetailsView extends StatelessWidget {
  const _ProcedureDetailsView({
    required this.procedure,
    required this.onRefresh,
  });

  final Procedure procedure;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = _detailsLines(procedure);
    final description = _nonEmpty(procedure.description);
    final notes = _nonEmpty(procedure.notes);

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
                        procedure.title,
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
                            label: _procedureStatusLabel(procedure.status),
                            tone: _procedureStatusTone(procedure.status),
                          ),
                          PawlyBadge(
                            label: _procedureTypeItemLabel(
                              procedure.procedureTypeItem,
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
          if (notes != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyListSection(
              title: 'Заметки',
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(PawlySpacing.md),
                  child: Text(notes, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ],
          if (procedure.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            Builder(
              builder: (context) {
                final viewerItems = procedure.attachments
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
                    procedure.attachments.length,
                    (index) {
                      final attachment = procedure.attachments[index];
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

  List<(String, String)> _detailsLines(Procedure procedure) {
    return <(String, String)>[
      if (_dateValue(procedure.scheduledAt) case final value?)
        ('Дата и время по плану', value),
      if (_dateValue(procedure.performedAt) case final value?)
        ('Дата и время выполнения', value),
      if (_dateValue(procedure.nextDueAt) case final value?)
        ('Дата и время повтора', value),
      if (_nonEmpty(procedure.productName) case final value?)
        ('Препарат или средство', value),
    ];
  }
}

class _ProceduresNoAccessView extends StatelessWidget {
  const _ProceduresNoAccessView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: _ProceduresInlineMessage(
          title: 'Нет доступа',
          message: 'У вас нет права просмотра процедур этого питомца.',
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

class _ProceduresErrorView extends StatelessWidget {
  const _ProceduresErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: _ProceduresInlineMessage(
          title: 'Не удалось загрузить процедуры',
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

class _ProceduresInlineMessage extends StatelessWidget {
  const _ProceduresInlineMessage({
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

String _procedureStatusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирована',
    'COMPLETED' => 'Выполнена',
    _ => status,
  };
}

PawlyBadgeTone _procedureStatusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'COMPLETED' => PawlyBadgeTone.success,
    _ => PawlyBadgeTone.neutral,
  };
}

String _procedureTypeItemLabel(HealthDictionaryItem? item) =>
    item?.name ?? 'Тип не указан';

void _invalidateHealthDerivedData(WidgetRef ref, String petId) {
  ref.invalidate(petHealthHomeProvider(petId));
  ref.invalidate(petLogsControllerProvider(petId));
  ref.invalidate(petAnalyticsMetricsProvider);
  ref.invalidate(petMetricSeriesProvider);
}
