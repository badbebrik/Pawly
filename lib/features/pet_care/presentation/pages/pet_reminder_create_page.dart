import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/data/pets_repository.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import '../providers/health_controllers.dart';
import 'pet_log_type_picker_page.dart';

class PetReminderCreatePage extends ConsumerStatefulWidget {
  const PetReminderCreatePage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetReminderCreatePage> createState() =>
      _PetReminderCreatePageState();
}

class _PetReminderCreatePageState extends ConsumerState<PetReminderCreatePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _intervalController;
  DateTime _startsAt = DateTime.now().add(const Duration(hours: 1));
  String _sourceType = 'MANUAL';
  String? _selectedLogTypeId;
  String? _selectedLogTypeLabel;
  String _recurrenceRule = _noRecurrenceValue;
  DateTime? _untilDate;
  bool _pushEnabled = true;
  int? _remindOffsetMinutes = 0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _noteController = TextEditingController();
    _intervalController = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return accessAsync.when(
      data: (access) {
        if (!access.remindersWrite) {
          return const PawlyScreenScaffold(
            title: 'Новое напоминание',
            body: _ReminderFormNoAccessView(),
          );
        }
        return _buildForm(context, theme, colorScheme, access);
      },
      loading: () => const PawlyScreenScaffold(
        title: 'Новое напоминание',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const PawlyScreenScaffold(
        title: 'Новое напоминание',
        body: _ReminderFormNoAccessView(),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    ThemeData theme,
    ColorScheme colorScheme,
    PetAccessPolicy access,
  ) {
    final canSubmit =
        !_isSubmitting && access.canWriteScheduledSource(_sourceType);

    return PawlyScreenScaffold(
      title: 'Новое напоминание',
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.sm,
            PawlySpacing.md,
            PawlySpacing.xl,
          ),
          children: <Widget>[
            _ReminderFormSection(
              title: 'Тип',
              child: Column(
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _ReminderOptionCard(
                          title: 'Ручное',
                          subtitle: 'Разовое правило',
                          icon: Icons.notifications_none_rounded,
                          isSelected: _sourceType == 'MANUAL',
                          onTap: _isSubmitting || !access.petWrite
                              ? null
                              : () {
                                  setState(() {
                                    _sourceType = 'MANUAL';
                                    _selectedLogTypeId = null;
                                    _selectedLogTypeLabel = null;
                                  });
                                },
                        ),
                      ),
                      const SizedBox(width: PawlySpacing.sm),
                      Expanded(
                        child: _ReminderOptionCard(
                          title: 'По записи',
                          subtitle: 'Для типа записи',
                          icon: Icons.list_alt_rounded,
                          isSelected: _sourceType == 'LOG_TYPE',
                          onTap: _isSubmitting || !access.logWrite
                              ? null
                              : () => setState(() {
                                    _sourceType = 'LOG_TYPE';
                                  }),
                        ),
                      ),
                    ],
                  ),
                  if (_sourceType == 'LOG_TYPE') ...<Widget>[
                    const SizedBox(height: PawlySpacing.sm),
                    _ReminderPickerRow(
                      title: 'Тип записи',
                      value: _selectedLogTypeLabel ?? 'Не выбран',
                      actionLabel:
                          _selectedLogTypeId == null ? 'Выбрать' : 'Изменить',
                      onTap: _isSubmitting ? null : _openLogTypePicker,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PawlySpacing.md),
            _ReminderFormSection(
              title: 'Описание',
              child: Column(
                children: <Widget>[
                  PawlyTextField(
                    controller: _titleController,
                    label: 'Название',
                    hintText: 'Например, Взвесить питомца',
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isSubmitting,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Укажите название';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: PawlySpacing.sm),
                  PawlyTextField(
                    controller: _noteController,
                    label: 'Заметка',
                    hintText: 'Необязательно',
                    maxLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    enabled: !_isSubmitting,
                  ),
                ],
              ),
            ),
            const SizedBox(height: PawlySpacing.md),
            _ReminderFormSection(
              title: 'Расписание',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _ReminderPickerRow(
                    title: 'Дата и время',
                    value: _formatDateTime(_startsAt),
                    actionLabel: 'Изменить',
                    onTap: _isSubmitting ? null : _pickStartsAt,
                  ),
                  const SizedBox(height: PawlySpacing.md),
                  Text(
                    'Повтор',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xs),
                  _ReminderChoiceWrap<String>(
                    values: const <String>[
                      _noRecurrenceValue,
                      'DAILY',
                      'WEEKLY',
                      'MONTHLY',
                      'YEARLY',
                    ],
                    selectedValue: _recurrenceRule,
                    labelBuilder: _recurrenceLabel,
                    onChanged: _isSubmitting
                        ? null
                        : (value) {
                            setState(() {
                              _recurrenceRule = value;
                              if (value == _noRecurrenceValue) {
                                _untilDate = null;
                              }
                            });
                          },
                  ),
                  if (_recurrenceRule != _noRecurrenceValue) ...[
                    const SizedBox(height: PawlySpacing.sm),
                    PawlyTextField(
                      controller: _intervalController,
                      label: 'Интервал',
                      hintText: '1',
                      keyboardType: TextInputType.number,
                      enabled: !_isSubmitting,
                      validator: (value) {
                        if (_recurrenceRule == _noRecurrenceValue) {
                          return null;
                        }
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed <= 0) {
                          return 'Интервал должен быть больше 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: PawlySpacing.sm),
                    _ReminderPickerRow(
                      title: 'Повторять до',
                      value: _untilDate == null
                          ? 'Без даты окончания'
                          : _formatDate(_untilDate!),
                      actionLabel: _untilDate == null ? 'Выбрать' : 'Изменить',
                      onTap: _isSubmitting ? null : _pickUntilDate,
                      secondaryActionLabel:
                          _untilDate == null ? null : 'Сбросить',
                      onSecondaryTap: _isSubmitting || _untilDate == null
                          ? null
                          : () => setState(() => _untilDate = null),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PawlySpacing.md),
            _ReminderFormSection(
              title: 'Уведомление',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          _pushEnabled ? 'Включено' : 'Выключено',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Switch(
                        value: _pushEnabled,
                        onChanged: _isSubmitting
                            ? null
                            : (value) => setState(() {
                                  _pushEnabled = value;
                                }),
                      ),
                    ],
                  ),
                  if (_pushEnabled) ...[
                    const SizedBox(height: PawlySpacing.sm),
                    Text(
                      'Когда напомнить',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: PawlySpacing.xs),
                    _ReminderChoiceWrap<int>(
                      values: const <int>[0, 15, 30, 60, 1440],
                      selectedValue: _remindOffsetMinutes ?? 0,
                      labelBuilder: _remindOffsetLabel,
                      onChanged: _isSubmitting
                          ? null
                          : (value) => setState(() {
                                _remindOffsetMinutes = value;
                              }),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: PawlySpacing.lg),
            PawlyButton(
              label: _isSubmitting ? 'Создаём...' : 'Создать напоминание',
              onPressed: canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openLogTypePicker() async {
    final selectedTypeId = await context.pushNamed<String>(
      'petLogTypePicker',
      pathParameters: <String, String>{'petId': widget.petId},
    );
    if (selectedTypeId == null || !mounted) {
      return;
    }
    if (selectedTypeId == noLogTypeSelectionId) {
      return;
    }

    final bootstrap = await ref.read(
      petLogComposerBootstrapProvider(widget.petId).future,
    );
    if (!mounted) {
      return;
    }

    final allTypes = <dynamic>[
      ...bootstrap.recentLogTypes,
      ...bootstrap.systemLogTypes,
      ...bootstrap.customLogTypes,
    ];
    String? selectedName;
    for (final item in allTypes) {
      if (item.id == selectedTypeId) {
        selectedName = item.name as String;
        break;
      }
    }

    setState(() {
      _selectedLogTypeId = selectedTypeId;
      _selectedLogTypeLabel = selectedName;
      if (_titleController.text.trim().isEmpty && selectedName != null) {
        _titleController.text = selectedName;
      }
    });
  }

  Future<void> _pickStartsAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startsAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startsAt),
    );
    if (time == null) {
      return;
    }

    setState(() {
      _startsAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _pickUntilDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _untilDate ?? _startsAt,
      firstDate: _startsAt,
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) {
      return;
    }

    setState(() {
      _untilDate = DateTime(date.year, date.month, date.day, 23, 59, 59);
    });
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_sourceType == 'LOG_TYPE' && _selectedLogTypeId == null) {
      _showError('Выберите тип записи для напоминания.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ref.read(healthRepositoryProvider).createScheduledItem(
            widget.petId,
            input: UpsertScheduledItemInput(
              sourceType: _sourceType,
              sourceId: _sourceType == 'LOG_TYPE' ? _selectedLogTypeId : null,
              title: _titleController.text.trim(),
              note: _noteController.text.trim().isEmpty
                  ? null
                  : _noteController.text.trim(),
              startsAtIso: _startsAt.toUtc().toIso8601String(),
              pushEnabled: _pushEnabled,
              remindOffsetMinutes:
                  _pushEnabled ? (_remindOffsetMinutes ?? 0) : null,
              recurrence: _recurrenceRule == _noRecurrenceValue
                  ? null
                  : ScheduledItemRecurrenceInput(
                      rule: _recurrenceRule,
                      interval: int.parse(_intervalController.text.trim()),
                      untilIso: _untilDate?.toUtc().toIso8601String(),
                    ),
            ),
          );

      ref.invalidate(petScheduledItemsProvider(widget.petId));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('Не удалось создать напоминание.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ReminderFormNoAccessView extends StatelessWidget {
  const _ReminderFormNoAccessView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: DecoratedBox(
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
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Нет доступа',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'У вас нет права создавать напоминания для этого питомца.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReminderFormSection extends StatelessWidget {
  const _ReminderFormSection({required this.title, required this.child});

  final String title;
  final Widget child;

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
        padding: const EdgeInsets.all(PawlySpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.sm),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReminderOptionCard extends StatelessWidget {
  const _ReminderOptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary.withValues(alpha: 0.10)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(PawlyRadius.lg),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary.withValues(alpha: 0.72)
                : colorScheme.outlineVariant.withValues(alpha: 0.64),
          ),
        ),
        padding: const EdgeInsets.all(PawlySpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              icon,
              size: 22,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: PawlySpacing.sm),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.xxxs),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderPickerRow extends StatelessWidget {
  const _ReminderPickerRow({
    required this.title,
    required this.value,
    required this.actionLabel,
    required this.onTap,
    this.secondaryActionLabel,
    this.onSecondaryTap,
  });

  final String title;
  final String value;
  final String actionLabel;
  final VoidCallback? onTap;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(PawlyRadius.lg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.64),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.sm),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xxxs),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (secondaryActionLabel != null) ...[
              TextButton(
                onPressed: onSecondaryTap,
                child: Text(secondaryActionLabel!),
              ),
              const SizedBox(width: PawlySpacing.xxs),
            ],
            TextButton(onPressed: onTap, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}

class _ReminderChoiceWrap<T> extends StatelessWidget {
  const _ReminderChoiceWrap({
    required this.values,
    required this.selectedValue,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selectedValue;
  final String Function(T value) labelBuilder;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: PawlySpacing.xs,
      runSpacing: PawlySpacing.xs,
      children: values.map((value) {
        return _ReminderChoicePill(
          label: labelBuilder(value),
          isSelected: value == selectedValue,
          onTap: onChanged == null ? null : () => onChanged!(value),
        );
      }).toList(growable: false),
    );
  }
}

class _ReminderChoicePill extends StatelessWidget {
  const _ReminderChoicePill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foregroundColor =
        isSelected ? colorScheme.onPrimary : colorScheme.onSurface;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.48),
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.84),
            width: isSelected ? 1.4 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.md,
          vertical: PawlySpacing.sm,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: foregroundColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

const String _noRecurrenceValue = '__none__';

String _recurrenceLabel(String value) {
  return switch (value) {
    _noRecurrenceValue => 'Без повтора',
    'DAILY' => 'Каждый день',
    'WEEKLY' => 'Неделя',
    'MONTHLY' => 'Месяц',
    'YEARLY' => 'Год',
    _ => value,
  };
}

String _remindOffsetLabel(int value) {
  return switch (value) {
    0 => 'В момент',
    15 => '15 мин',
    30 => '30 мин',
    60 => '1 час',
    1440 => '1 день',
    _ => '$value мин',
  };
}

String _formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month.$year в $hour:$minute';
}

String _formatDate(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day.$month.$year';
}
