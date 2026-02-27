import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import '../providers/pet_health_home_controllers.dart';
import '../providers/pet_procedures_controller.dart';

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
  ProcedureBucket _selectedBucket = ProcedureBucket.planned;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(petProceduresControllerProvider(widget.petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Процедуры')),
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Новая процедура'),
            )
          : null,
      body: stateAsync.when(
        data: (state) => _ProceduresContent(
          petId: widget.petId,
          state: state,
          selectedBucket: _selectedBucket,
          onBucketChanged: (bucket) => setState(() => _selectedBucket = bucket),
          onRetry: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
              .reload(),
          onLoadMore: () => ref
              .read(petProceduresControllerProvider(widget.petId).notifier)
              .loadMore(_selectedBucket),
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

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petProceduresControllerProvider(widget.petId)).asData?.value;
    if (state == null) {
      return;
    }

    final input = await showModalBottomSheet<UpsertProcedureInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProcedureComposerSheet(
        allowedStatuses: state.bootstrap.enums.procedureStatuses,
        allowedTypes: state.bootstrap.enums.procedureTypes,
      ),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      await ref
          .read(petProceduresControllerProvider(widget.petId).notifier)
          .createProcedure(input: input);
      ref.invalidate(petHealthHomeProvider(widget.petId));
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
}

class _ProceduresContent extends StatelessWidget {
  const _ProceduresContent({
    required this.petId,
    required this.state,
    required this.selectedBucket,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
  });

  final String petId;
  final PetProceduresState state;
  final ProcedureBucket selectedBucket;
  final ValueChanged<ProcedureBucket> onBucketChanged;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _ProceduresNoAccessView(onRetry: onRetry);
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
              ? 'Профилактические и лечебные процедуры'
              : 'Профилактические и лечебные процедуры · только просмотр',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Wrap(
          spacing: PawlySpacing.sm,
          runSpacing: PawlySpacing.sm,
          children: <Widget>[
            _ProcedureBucketChip(
              label: 'План',
              count: state.plannedItems.length,
              selected: selectedBucket == ProcedureBucket.planned,
              onTap: () => onBucketChanged(ProcedureBucket.planned),
            ),
            _ProcedureBucketChip(
              label: 'История',
              count: state.historyItems.length,
              selected: selectedBucket == ProcedureBucket.history,
              onTap: () => onBucketChanged(ProcedureBucket.history),
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.lg),
        if (items.isEmpty)
          PawlyCard(
            child: Text(
              selectedBucket == ProcedureBucket.planned
                  ? 'Запланированных процедур пока нет.'
                  : 'История процедур пока пуста.',
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: _ProcedureListCard(
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

class _ProcedureBucketChip extends StatelessWidget {
  const _ProcedureBucketChip({
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

class _ProcedureListCard extends StatelessWidget {
  const _ProcedureListCard({
    required this.petId,
    required this.item,
  });

  final String petId;
  final ProcedureCard item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PawlyCard(
      onTap: () => context.pushNamed(
        'petProcedureDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'procedureId': item.id,
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
                label: _procedureStatusLabel(item.status),
                tone: _procedureStatusTone(item.status),
              ),
              PawlyBadge(
                label: _procedureTypeLabel(item.procedureType),
                tone: PawlyBadgeTone.neutral,
              ),
            ],
          ),
          if (_primaryDateLabel(item) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            _ProcedureInfoLine(
              icon: Icons.event_rounded,
              text: value,
            ),
          ],
          if (_nonEmpty(item.productName) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.xs),
            _ProcedureInfoLine(
              icon: Icons.medication_rounded,
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
          if (_nonEmpty(item.notesPreview) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            Text(
              value,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _primaryDateLabel(ProcedureCard item) {
    final parts = <String>[
      if (_dateValue(item.scheduledAt) case final scheduled?) 'План $scheduled',
      if (_dateValue(item.performedAt) case final performed?)
        'Выполнено $performed',
      if (_dateValue(item.nextDueAt) case final next?) 'Повтор $next',
    ];
    if (parts.isEmpty) {
      return null;
    }
    return parts.join(' · ');
  }
}

class _ProcedureInfoLine extends StatelessWidget {
  const _ProcedureInfoLine({
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

class _ProcedureComposerSheet extends StatefulWidget {
  const _ProcedureComposerSheet({
    required this.allowedStatuses,
    required this.allowedTypes,
    this.initialProcedure,
    this.title = 'Новая процедура',
    this.submitLabel = 'Сохранить процедуру',
  });

  final List<String> allowedStatuses;
  final List<String> allowedTypes;
  final Procedure? initialProcedure;
  final String title;
  final String submitLabel;

  @override
  State<_ProcedureComposerSheet> createState() =>
      _ProcedureComposerSheetState();
}

class _ProcedureComposerSheetState extends State<_ProcedureComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _productNameController = TextEditingController();
  final _notesController = TextEditingController();

  late String _status;
  late String _procedureType;
  DateTime? _scheduledAt;
  DateTime? _performedAt;
  DateTime? _nextDueAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialProcedure;
    _status = initial?.status ??
        (widget.allowedStatuses.contains('PLANNED')
            ? 'PLANNED'
            : widget.allowedStatuses.first);
    _procedureType = initial?.procedureType ??
        (widget.allowedTypes.contains('DEWORMING')
            ? 'DEWORMING'
            : widget.allowedTypes.first);
    _titleController.text = initial?.title ?? '';
    _descriptionController.text = initial?.description ?? '';
    _productNameController.text = initial?.productName ?? '';
    _notesController.text = initial?.notes ?? '';
    _scheduledAt = initial?.scheduledAt;
    _performedAt = initial?.performedAt;
    _nextDueAt = initial?.nextDueAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _productNameController.dispose();
    _notesController.dispose();
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
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: widget.allowedStatuses
                      .map(
                        (status) => ChoiceChip(
                          label: Text(_procedureStatusLabel(status)),
                          selected: _status == status,
                          onSelected: (_) => setState(() => _status = status),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: PawlySpacing.md),
                DropdownButtonFormField<String>(
                  value: _procedureType,
                  decoration: const InputDecoration(labelText: 'Тип процедуры'),
                  items: widget.allowedTypes
                      .map(
                        (type) => DropdownMenuItem<String>(
                          value: type,
                          child: Text(_procedureTypeLabel(type)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _procedureType = value);
                  },
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _titleController,
                  label: 'Название',
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Укажи название процедуры.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _descriptionController,
                  label: 'Описание',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _productNameController,
                  label: 'Препарат или средство',
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: PawlySpacing.sm),
                _DateButton(
                  label: _scheduledAt == null
                      ? 'Дата по плану'
                      : 'Дата по плану: ${_formatDate(_scheduledAt!)}',
                  onTap: () async {
                    final picked = await _pickDate(
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
                    label: _performedAt == null
                        ? 'Дата выполнения'
                        : 'Дата выполнения: ${_formatDate(_performedAt!)}',
                    onTap: () async {
                      final picked = await _pickDate(
                        context,
                        initialDate:
                            _performedAt ?? _scheduledAt ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _performedAt = picked);
                      }
                    },
                    secondary: true,
                  ),
                ],
                if (_status == 'DONE') ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  _DateButton(
                    label: _nextDueAt == null
                        ? 'Дата повтора'
                        : 'Дата повтора: ${_formatDate(_nextDueAt!)}',
                    onTap: () async {
                      final picked = await _pickDate(
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
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: _notesController,
                  label: 'Заметки',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: widget.submitLabel,
                  onPressed: _submit,
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

    Navigator.of(context).pop(
      UpsertProcedureInput(
        status: _status,
        procedureType: _procedureType,
        title: _titleController.text.trim(),
        description: _nonEmpty(_descriptionController.text),
        productName: _nonEmpty(_productNameController.text),
        scheduledAtIso: _toStoredDate(_scheduledAt)?.toIso8601String(),
        performedAtIso: _toStoredDate(_performedAt)?.toIso8601String(),
        nextDueAtIso: _toStoredDate(_nextDueAt)?.toIso8601String(),
        notes: _nonEmpty(_notesController.text),
        rowVersion: widget.initialProcedure?.rowVersion,
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Процедура'),
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
    final input = await showModalBottomSheet<UpsertProcedureInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _ProcedureComposerSheet(
        allowedStatuses: state?.bootstrap.enums.procedureStatuses ??
            const <String>['PLANNED', 'DONE', 'CANCELLED'],
        allowedTypes:
            state?.bootstrap.enums.procedureTypes ?? const <String>['OTHER'],
        initialProcedure: procedure,
        title: 'Редактировать процедуру',
        submitLabel: 'Сохранить изменения',
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
      ref.invalidate(petHealthHomeProvider(petId));
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
                  procedure.title,
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
                      label: _procedureStatusLabel(procedure.status),
                      tone: _procedureStatusTone(procedure.status),
                    ),
                    PawlyBadge(
                      label: _procedureTypeLabel(procedure.procedureType),
                      tone: PawlyBadgeTone.neutral,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_detailsLines(procedure).isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Основное',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _detailsLines(procedure)
                    .map(
                      (line) => _ProcedureDetailsRow(
                        label: line.$1,
                        value: line.$2,
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
          if (_nonEmpty(procedure.description) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Описание',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(value),
            ),
          ],
          if (_nonEmpty(procedure.notes) case final value?) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Заметки',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(value),
            ),
          ],
          if (procedure.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Вложения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                children: procedure.attachments
                    .map(
                      (attachment) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          attachment.fileType.startsWith('image/')
                              ? Icons.photo_rounded
                              : Icons.description_rounded,
                        ),
                        title: Text(attachment.fileName ?? 'Файл'),
                        subtitle: Text(
                          attachment.addedAt == null
                              ? attachment.fileType
                              : '${attachment.fileType} • ${_formatDate(attachment.addedAt!)}',
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<(String, String)> _detailsLines(Procedure procedure) {
    return <(String, String)>[
      if (_dateValue(procedure.scheduledAt) case final value?)
        ('Дата по плану', value),
      if (_dateValue(procedure.performedAt) case final value?)
        ('Дата выполнения', value),
      if (_dateValue(procedure.nextDueAt) case final value?)
        ('Дата повтора', value),
      if (_nonEmpty(procedure.productName) case final value?)
        ('Препарат или средство', value),
    ];
  }
}

class _ProcedureDetailsRow extends StatelessWidget {
  const _ProcedureDetailsRow({
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

class _ProceduresNoAccessView extends StatelessWidget {
  const _ProceduresNoAccessView({required this.onRetry});

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
                'Нет доступа к процедурам',
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

class _ProceduresErrorView extends StatelessWidget {
  const _ProceduresErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить процедуры'),
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

String _procedureStatusLabel(String status) {
  return switch (status) {
    'PLANNED' => 'Запланирована',
    'DONE' => 'Выполнена',
    'CANCELLED' => 'Отменена',
    _ => status,
  };
}

PawlyBadgeTone _procedureStatusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'DONE' => PawlyBadgeTone.success,
    'CANCELLED' => PawlyBadgeTone.warning,
    _ => PawlyBadgeTone.neutral,
  };
}

String _procedureTypeLabel(String type) {
  return switch (type) {
    'PARASITE_TREATMENT' => 'Паразиты',
    'DEWORMING' => 'Дегельминтизация',
    'HYGIENE' => 'Гигиена',
    'WOUND_CARE' => 'Обработка',
    'GROOMING' => 'Груминг',
    'OTHER' => 'Другое',
    _ => type,
  };
}
