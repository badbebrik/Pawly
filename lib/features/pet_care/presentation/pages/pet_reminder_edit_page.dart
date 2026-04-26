import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../data/health_repository_models.dart';
import '../providers/health_controllers.dart';
import 'pet_log_type_picker_page.dart';

class PetReminderEditPage extends ConsumerStatefulWidget {
  const PetReminderEditPage({
    required this.petId,
    required this.itemId,
    super.key,
  });

  final String petId;
  final String itemId;

  @override
  ConsumerState<PetReminderEditPage> createState() =>
      _PetReminderEditPageState();
}

class _PetReminderEditPageState extends ConsumerState<PetReminderEditPage> {
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
  String? _loadedItemId;
  int _rowVersion = 0;

  bool get _canEditRule => _isUserManagedRule(_sourceType);

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
    final itemAsync = ref.watch(
      petScheduledItemProvider(
        PetScheduledItemRef(
          petId: widget.petId,
          itemId: widget.itemId,
        ),
      ),
    );

    return PawlyScreenScaffold(
      title: 'Редактировать напоминание',
      body: itemAsync.when(
        data: (item) {
          _applyItem(item);
          final access = accessAsync.asData?.value;
          if (accessAsync.hasError ||
              (access != null &&
                  !access.canWriteScheduledSource(item.sourceType))) {
            return const _ReminderEditNoAccessView();
          }
          if (access == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(PawlySpacing.lg),
              children: <Widget>[
                if (!_canEditRule)
                  Padding(
                    padding: const EdgeInsets.only(bottom: PawlySpacing.md),
                    child: PawlyCard(
                      child: const Text(
                        'Для системных правил можно менять только параметры уведомления.',
                      ),
                    ),
                  ),
                PawlyCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Тип напоминания',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: PawlySpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _sourceType,
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'MANUAL',
                            child: Text('Ручное'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'LOG_TYPE',
                            child: Text('По типу записи'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'PET_EVENT',
                            child: Text('Событие питомца'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'VET_VISIT',
                            child: Text('Визит к врачу'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'VACCINATION',
                            child: Text('Вакцинация'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'PROCEDURE',
                            child: Text('Процедура'),
                          ),
                        ],
                        onChanged: null,
                      ),
                      if (_sourceType == 'LOG_TYPE') ...<Widget>[
                        const SizedBox(height: PawlySpacing.md),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.category_rounded),
                          title: const Text('Тип записи'),
                          subtitle: Text(
                            _selectedLogTypeLabel ?? 'Не выбран',
                          ),
                          trailing: _canEditRule
                              ? TextButton(
                                  onPressed:
                                      _isSubmitting ? null : _openLogTypePicker,
                                  child: const Text('Изменить'),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _titleController,
                  label: 'Название',
                  hintText: 'Например, Взвесить питомца',
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSubmitting && _canEditRule,
                  validator: (value) {
                    if (!_canEditRule) {
                      return null;
                    }
                    if (value == null || value.trim().isEmpty) {
                      return 'Укажите название';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyTextField(
                  controller: _noteController,
                  label: 'Заметка',
                  hintText: 'Необязательно',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !_isSubmitting && _canEditRule,
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyCard(
                  child: Column(
                    children: <Widget>[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_rounded),
                        title: const Text('Дата и время'),
                        subtitle: Text(_formatDateTime(_startsAt)),
                        trailing: _canEditRule
                            ? TextButton(
                                onPressed: _isSubmitting ? null : _pickStartsAt,
                                child: const Text('Изменить'),
                              )
                            : null,
                      ),
                      const SizedBox(height: PawlySpacing.sm),
                      DropdownButtonFormField<String>(
                        initialValue: _recurrenceRule,
                        decoration: const InputDecoration(
                          labelText: 'Повтор',
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: _noRecurrenceValue,
                            child: Text('Без повтора'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'DAILY',
                            child: Text('Каждый день'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'WEEKLY',
                            child: Text('Каждую неделю'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'MONTHLY',
                            child: Text('Каждый месяц'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'YEARLY',
                            child: Text('Каждый год'),
                          ),
                        ],
                        onChanged: !_canEditRule || _isSubmitting
                            ? null
                            : (value) {
                                if (value == null) {
                                  return;
                                }
                                setState(() {
                                  _recurrenceRule = value;
                                  if (value == _noRecurrenceValue) {
                                    _untilDate = null;
                                  }
                                });
                              },
                      ),
                      if (_recurrenceRule != _noRecurrenceValue) ...<Widget>[
                        const SizedBox(height: PawlySpacing.md),
                        PawlyTextField(
                          controller: _intervalController,
                          label: 'Интервал',
                          hintText: '1',
                          keyboardType: TextInputType.number,
                          enabled: !_isSubmitting && _canEditRule,
                          validator: (value) {
                            if (!_canEditRule ||
                                _recurrenceRule == _noRecurrenceValue) {
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
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.event_repeat_rounded),
                          title: const Text('Повторять до'),
                          subtitle: Text(
                            _untilDate == null
                                ? 'Без даты окончания'
                                : _formatDate(_untilDate!),
                          ),
                          trailing: _canEditRule
                              ? Wrap(
                                  spacing: PawlySpacing.xs,
                                  children: <Widget>[
                                    if (_untilDate != null)
                                      TextButton(
                                        onPressed: _isSubmitting
                                            ? null
                                            : () {
                                                setState(() {
                                                  _untilDate = null;
                                                });
                                              },
                                        child: const Text('Сбросить'),
                                      ),
                                    TextButton(
                                      onPressed:
                                          _isSubmitting ? null : _pickUntilDate,
                                      child: const Text('Выбрать'),
                                    ),
                                  ],
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PawlySpacing.md),
                PawlyCard(
                  child: Column(
                    children: <Widget>[
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _pushEnabled,
                        onChanged: _isSubmitting
                            ? null
                            : (value) {
                                setState(() {
                                  _pushEnabled = value;
                                });
                              },
                        title: const Text('Уведомление включено'),
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
                          onChanged: _isSubmitting
                              ? null
                              : (value) {
                                  setState(() {
                                    _remindOffsetMinutes = value;
                                  });
                                },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: PawlySpacing.lg),
                PawlyButton(
                  label: _isSubmitting ? 'Сохраняем...' : 'Сохранить',
                  onPressed: _isSubmitting ? null : _submit,
                  icon: Icons.check_rounded,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: PawlyCard(
              title: const Text('Не удалось загрузить напоминание'),
              footer: PawlyButton(
                label: 'Повторить',
                onPressed: () => ref.invalidate(
                  petScheduledItemProvider(
                    PetScheduledItemRef(
                      petId: widget.petId,
                      itemId: widget.itemId,
                    ),
                  ),
                ),
                variant: PawlyButtonVariant.secondary,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  void _applyItem(ScheduledItem item) {
    if (_loadedItemId == item.id) {
      return;
    }

    _loadedItemId = item.id;
    _rowVersion = item.rowVersion;
    _sourceType = item.sourceType;
    _selectedLogTypeId = item.sourceId;
    _selectedLogTypeLabel = null;
    _titleController.text = item.title;
    _noteController.text = item.note ?? '';
    _startsAt = (item.startsAt ?? DateTime.now()).toLocal();
    _pushEnabled = item.pushEnabled;
    _remindOffsetMinutes = item.remindOffsetMinutes ?? 0;
    _recurrenceRule = item.recurrence?.rule ?? _noRecurrenceValue;
    _intervalController.text = (item.recurrence?.interval ?? 1).toString();
    _untilDate = item.recurrence?.until?.toLocal();

    if (_sourceType == 'LOG_TYPE' && item.sourceId != null) {
      Future<void>.microtask(_resolveLogTypeLabel);
    }
  }

  Future<void> _resolveLogTypeLabel() async {
    final selectedId = _selectedLogTypeId;
    if (selectedId == null) {
      return;
    }
    final bootstrap = await ref.read(
      petLogComposerBootstrapProvider(widget.petId).future,
    );
    if (!mounted) {
      return;
    }

    for (final item in <dynamic>[
      ...bootstrap.recentLogTypes,
      ...bootstrap.systemLogTypes,
      ...bootstrap.customLogTypes,
    ]) {
      if (item.id == selectedId) {
        setState(() {
          _selectedLogTypeLabel = item.name as String;
        });
        return;
      }
    }
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

    String? selectedName;
    for (final item in <dynamic>[
      ...bootstrap.recentLogTypes,
      ...bootstrap.systemLogTypes,
      ...bootstrap.customLogTypes,
    ]) {
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
    if (_canEditRule &&
        _sourceType == 'LOG_TYPE' &&
        _selectedLogTypeId == null) {
      _showError('Выберите тип записи для напоминания.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_canEditRule) {
        await ref.read(healthRepositoryProvider).updateScheduledItem(
              widget.petId,
              widget.itemId,
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
                rowVersion: _rowVersion,
              ),
            );
      } else {
        await ref
            .read(healthRepositoryProvider)
            .updateScheduledItemReminderSettings(
              widget.petId,
              widget.itemId,
              input: UpdateScheduledItemReminderSettingsInput(
                pushEnabled: _pushEnabled,
                remindOffsetMinutes:
                    _pushEnabled ? (_remindOffsetMinutes ?? 0) : null,
                rowVersion: _rowVersion,
              ),
            );
      }

      ref.invalidate(petScheduledItemsProvider(widget.petId));
      ref.invalidate(
        petScheduledItemProvider(
          PetScheduledItemRef(
            petId: widget.petId,
            itemId: widget.itemId,
          ),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('Не удалось сохранить изменения.');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _ReminderEditNoAccessView extends StatelessWidget {
  const _ReminderEditNoAccessView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          title: Text(
            'Нет доступа',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          child: Text(
            'У вас нет права редактировать это напоминание.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

bool _isUserManagedRule(String sourceType) {
  return sourceType == 'MANUAL' ||
      sourceType == 'LOG_TYPE' ||
      sourceType == 'PET_EVENT';
}

const String _noRecurrenceValue = '__none__';

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
