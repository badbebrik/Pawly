import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../../data/health_repository_models.dart';
import '../providers/health_controllers.dart';
import '../providers/pet_health_home_controllers.dart';
import '../providers/pet_vaccinations_controller.dart';

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
  VaccinationBucket _selectedBucket = VaccinationBucket.planned;

  @override
  Widget build(BuildContext context) {
    final stateAsync = ref.watch(
      petVaccinationsControllerProvider(widget.petId),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Вакцинации')),
      floatingActionButton: stateAsync.asData?.value.canWrite == true
          ? FloatingActionButton.extended(
              onPressed: _openCreateSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Новая вакцина'),
            )
          : null,
      body: stateAsync.when(
        data: (state) => _VaccinationsContent(
          petId: widget.petId,
          state: state,
          selectedBucket: _selectedBucket,
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

  Future<void> _openCreateSheet() async {
    final state =
        ref.read(petVaccinationsControllerProvider(widget.petId)).value;
    if (state == null) {
      return;
    }

    final input = await showModalBottomSheet<UpsertVaccinationInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VaccinationComposerSheet(
        allowedStatuses: state.bootstrap.enums.vaccinationStatuses,
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
            'Дата ревакцинации сохранена: ${_formatDate(nextDueAt)}.',
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

class _VaccinationsContent extends StatelessWidget {
  const _VaccinationsContent({
    required this.petId,
    required this.state,
    required this.selectedBucket,
    required this.onBucketChanged,
    required this.onRetry,
    required this.onLoadMore,
    required this.onMarkDone,
  });

  final String petId;
  final PetVaccinationsState state;
  final VaccinationBucket selectedBucket;
  final ValueChanged<VaccinationBucket> onBucketChanged;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final ValueChanged<VaccinationCard> onMarkDone;

  @override
  Widget build(BuildContext context) {
    if (!state.canRead) {
      return _VaccinationsNoAccessView(onRetry: onRetry);
    }

    final theme = Theme.of(context);
    final items = state.itemsFor(selectedBucket);
    final isPlanned = selectedBucket == VaccinationBucket.planned;

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
              ? 'План вакцинации и история прививок'
              : 'План вакцинации и история прививок · только просмотр',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: PawlySpacing.md),
        Wrap(
          spacing: PawlySpacing.sm,
          runSpacing: PawlySpacing.sm,
          children: <Widget>[
            _BucketChip(
              label: 'План',
              count: state.plannedItems.length,
              selected: selectedBucket == VaccinationBucket.planned,
              onTap: () => onBucketChanged(VaccinationBucket.planned),
            ),
            _BucketChip(
              label: 'История',
              count: state.historyItems.length,
              selected: selectedBucket == VaccinationBucket.history,
              onTap: () => onBucketChanged(VaccinationBucket.history),
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.lg),
        if (items.isEmpty)
          PawlyCard(
            child: Text(
              isPlanned
                  ? 'Плановых вакцинаций пока нет. Добавьте первую запись, чтобы не потерять дату прививки.'
                  : 'История вакцинаций пока пуста. Выполненные и отмененные записи появятся здесь.',
              style: theme.textTheme.bodyLarge,
            ),
          )
        else
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: PawlySpacing.md),
              child: _VaccinationListCard(
                petId: petId,
                item: item,
                canWrite: state.canWrite,
                isBusy: state.busyVaccinationIds.contains(item.id),
                onMarkDone:
                    item.status == 'PLANNED' ? () => onMarkDone(item) : null,
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

class _BucketChip extends StatelessWidget {
  const _BucketChip({
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
    final accent = _statusColor(item.status);

    return PawlyCard(
      onTap: () => context.pushNamed(
        'petVaccinationDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'vaccinationId': item.id,
        },
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(PawlyRadius.md),
            ),
            child: Icon(
              Icons.vaccines_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.vaccineName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                PawlyBadge(
                  label: _statusLabel(item.status),
                  tone: _statusTone(item.status),
                ),
                const SizedBox(height: PawlySpacing.sm),
                if (_primaryDateLabel(item) case final dateLabel?)
                  _InfoLine(
                    icon: Icons.event_rounded,
                    text: dateLabel,
                  ),
                if ((item.clinicName ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xs),
                  _InfoLine(
                    icon: Icons.local_hospital_rounded,
                    text: item.clinicName!.trim(),
                  ),
                ],
                if ((item.vetName ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xs),
                  _InfoLine(
                    icon: Icons.person_outline_rounded,
                    text: item.vetName!.trim(),
                  ),
                ],
                if (item.nextDueAt != null) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xs),
                  _InfoLine(
                    icon: Icons.refresh_rounded,
                    text: 'Ревакцинация ${_formatDate(item.nextDueAt!)}',
                  ),
                ],
                if (item.attachmentsCount > 0) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xs),
                  _InfoLine(
                    icon: Icons.attach_file_rounded,
                    text: '${item.attachmentsCount} влож.',
                  ),
                ],
                if ((item.notesPreview ?? '').trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    item.notesPreview!.trim(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.35,
                    ),
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
        ],
      ),
    );
  }

  String? _primaryDateLabel(VaccinationCard item) {
    final date = switch (item.status) {
      'DONE' => item.administeredAt ?? item.scheduledAt,
      'CANCELLED' => item.scheduledAt,
      _ => item.scheduledAt,
    };

    if (date == null) {
      return null;
    }

    final prefix = switch (item.status) {
      'DONE' => 'Сделано',
      'CANCELLED' => 'Было запланировано',
      _ => 'Запланировано',
    };
    return '$prefix ${_formatDate(date)}';
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
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

class _VaccinationComposerSheet extends StatefulWidget {
  const _VaccinationComposerSheet({
    required this.allowedStatuses,
    this.initialVaccination,
    this.title = 'Новая вакцинация',
    this.submitLabel = 'Сохранить вакцинацию',
  });

  final List<String> allowedStatuses;
  final Vaccination? initialVaccination;
  final String title;
  final String submitLabel;

  @override
  State<_VaccinationComposerSheet> createState() =>
      _VaccinationComposerSheetState();
}

class _VaccinationComposerSheetState extends State<_VaccinationComposerSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clinicController = TextEditingController();
  final _vetController = TextEditingController();
  final _notesController = TextEditingController();

  late String _status;
  DateTime? _scheduledAt;
  DateTime? _administeredAt;
  DateTime? _nextDueAt;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialVaccination;
    _status = initial?.status ??
        (widget.allowedStatuses.contains('PLANNED')
            ? 'PLANNED'
            : widget.allowedStatuses.first);
    _nameController.text = initial?.vaccineName ?? '';
    _clinicController.text = initial?.clinicName ?? '';
    _vetController.text = initial?.vetName ?? '';
    _notesController.text = initial?.notes ?? '';
    _scheduledAt = initial?.scheduledAt;
    _administeredAt = initial?.administeredAt;
    _nextDueAt = initial?.nextDueAt;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clinicController.dispose();
    _vetController.dispose();
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
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Запланируйте прививку или сразу внесите выполненную вакцинацию.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: widget.allowedStatuses
                      .map(
                        (status) => ChoiceChip(
                          label: Text(_statusLabel(status)),
                          selected: _status == status,
                          onSelected: (_) => setState(() => _status = status),
                        ),
                      )
                      .toList(growable: false),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
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
                const SizedBox(height: PawlySpacing.sm),
                _DateFieldButton(
                  label: _scheduledAt == null
                      ? 'Плановая дата'
                      : 'Плановая дата: ${_formatDate(_scheduledAt!)}',
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
                if (_status == 'DONE') ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  _DateFieldButton(
                    label: _administeredAt == null
                        ? 'Дата выполнения'
                        : 'Дата выполнения: ${_formatDate(_administeredAt!)}',
                    onTap: () async {
                      final picked = await _pickDate(
                        context,
                        initialDate:
                            _administeredAt ?? _scheduledAt ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _administeredAt = picked);
                      }
                    },
                  ),
                  const SizedBox(height: PawlySpacing.sm),
                  _DateFieldButton(
                    label: _nextDueAt == null
                        ? 'Дата ревакцинации'
                        : 'Дата ревакцинации: ${_formatDate(_nextDueAt!)}',
                    onTap: () async {
                      final picked = await _pickDate(
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
                  controller: _notesController,
                  label: 'Заметки',
                  maxLines: 4,
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

    if (_status == 'DONE' && _administeredAt == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Укажите дату выполнения вакцинации.')),
      );
      return;
    }

    Navigator.of(context).pop(
      UpsertVaccinationInput(
        status: _status,
        vaccineName: _nameController.text.trim(),
        scheduledAtIso: _toStoredDate(_scheduledAt)?.toIso8601String(),
        administeredAtIso: _toStoredDate(_administeredAt)?.toIso8601String(),
        nextDueAtIso: _toStoredDate(_nextDueAt)?.toIso8601String(),
        clinicName: _emptyToNull(_clinicController.text),
        vetName: _emptyToNull(_vetController.text),
        notes: _emptyToNull(_notesController.text),
        rowVersion: widget.initialVaccination?.rowVersion,
      ),
    );
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  DateTime? _toStoredDate(DateTime? value) {
    if (value == null) {
      return null;
    }
    return DateTime(value.year, value.month, value.day, 12);
  }
}

class _DateFieldButton extends StatelessWidget {
  const _DateFieldButton({
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
          const Text('Укажите дату, когда вакцинация была выполнена.'),
          const SizedBox(height: PawlySpacing.md),
          Text(
            _formatDate(_selectedDate),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: PawlySpacing.sm),
          TextButton.icon(
            onPressed: () async {
              final picked = await _pickDate(
                context,
                initialDate: _selectedDate,
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.event_rounded),
            label: const Text('Изменить дату'),
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
      title: const Text('Дата ревакцинации'),
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
              _formatDate(_selectedDate!),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          const SizedBox(height: PawlySpacing.sm),
          TextButton.icon(
            onPressed: () async {
              final picked = await _pickDate(
                context,
                initialDate: _selectedDate ?? widget.initialDate,
                firstDate: widget.initialDate,
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Выбрать дату'),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Вакцина'),
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
    final statuses = ref
            .read(petVaccinationsControllerProvider(petId))
            .asData
            ?.value
            .bootstrap
            .enums
            .vaccinationStatuses ??
        const <String>['PLANNED', 'DONE', 'CANCELLED'];

    final input = await showModalBottomSheet<UpsertVaccinationInput>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => _VaccinationComposerSheet(
        allowedStatuses: statuses,
        initialVaccination: vaccination,
        title: 'Редактировать вакцинацию',
        submitLabel: 'Сохранить изменения',
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
    final canMutate = vaccination.canEdit || vaccination.canDelete;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        children: <Widget>[
          PawlyCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        vaccination.vaccineName,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                    ),
                    const SizedBox(width: PawlySpacing.sm),
                    PawlyBadge(
                      label: _statusLabel(vaccination.status),
                      tone: _statusTone(vaccination.status),
                    ),
                  ],
                ),
                if (!canMutate) ...<Widget>[
                  const SizedBox(height: PawlySpacing.md),
                  const PawlyBadge(
                    label: 'Редактирование недоступно',
                    tone: PawlyBadgeTone.warning,
                  ),
                ],
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
                if (_dateValue(vaccination.scheduledAt) case final value?)
                  _DetailsRow(
                    label: 'План',
                    value: value,
                  ),
                if (_dateValue(vaccination.administeredAt) case final value?)
                  _DetailsRow(
                    label: 'Выполнено',
                    value: value,
                  ),
                if (_dateValue(vaccination.nextDueAt) case final value?)
                  _DetailsRow(
                    label: 'Ревакцинация',
                    value: value,
                  ),
                if (_textValue(vaccination.clinicName) case final value?)
                  _DetailsRow(
                    label: 'Клиника',
                    value: value,
                  ),
                if (_textValue(vaccination.vetName) case final value?)
                  _DetailsRow(
                    label: 'Врач',
                    value: value,
                  ),
              ],
            ),
          ),
          if ((vaccination.notes ?? '').trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Заметки',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Text(vaccination.notes!.trim()),
            ),
          ],
          if (vaccination.attachments.isNotEmpty) ...<Widget>[
            const SizedBox(height: PawlySpacing.md),
            PawlyCard(
              title: Text(
                'Вложения',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                children: vaccination.attachments
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
}

class _DetailsRow extends StatelessWidget {
  const _DetailsRow({
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

class _VaccinationsNoAccessView extends StatelessWidget {
  const _VaccinationsNoAccessView({required this.onRetry});

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
                'Нет доступа к вакцинациям',
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

class _VaccinationsErrorView extends StatelessWidget {
  const _VaccinationsErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: const Text('Не удалось загрузить вакцинации'),
          footer: PawlyButton(
            label: 'Повторить',
            onPressed: onRetry,
            variant: PawlyButtonVariant.secondary,
          ),
          child: const Text(
            'Попробуйте обновить экран чуть позже.',
          ),
        ),
      ),
    );
  }
}

Future<DateTime?> _pickDate(
  BuildContext context, {
  required DateTime initialDate,
  DateTime? firstDate,
}) async {
  return showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate ?? DateTime(2000),
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

String? _dateValue(DateTime? value) {
  if (value == null) {
    return null;
  }
  return _formatDate(value);
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
    'DONE' => 'Выполнена',
    'CANCELLED' => 'Отменена',
    _ => status,
  };
}

PawlyBadgeTone _statusTone(String status) {
  return switch (status) {
    'PLANNED' => PawlyBadgeTone.info,
    'DONE' => PawlyBadgeTone.success,
    'CANCELLED' => PawlyBadgeTone.warning,
    _ => PawlyBadgeTone.neutral,
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'PLANNED' => const Color(0xFF2B7FFF),
    'DONE' => const Color(0xFF1C8D62),
    'CANCELLED' => const Color(0xFFE5A33A),
    _ => const Color(0xFF94A3B8),
  };
}

void _invalidateHealthDerivedData(WidgetRef ref, String petId) {
  ref.invalidate(petHealthHomeProvider(petId));
  ref.invalidate(petLogsControllerProvider(petId));
  ref.invalidate(petAnalyticsMetricsProvider);
  ref.invalidate(petMetricSeriesProvider);
}
