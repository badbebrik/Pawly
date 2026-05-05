import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../logs/controllers/logs_controller.dart';
import '../../../logs/models/log_constants.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../controllers/reminder_edit_controller.dart';
import '../../controllers/reminders_controller.dart';
import '../../models/reminder_models.dart';
import '../../models/reminder_ref.dart';
import '../../shared/utils/reminder_date_picker.dart';
import '../../shared/utils/reminder_log_type_lookup.dart';
import '../widgets/form/reminder_form_draft.dart';
import '../widgets/form/reminder_form_view.dart';

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
  late final ReminderFormDraft _draft;

  @override
  void initState() {
    super.initState();
    _draft = ReminderFormDraft();
  }

  @override
  void dispose() {
    _draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reminderRef = ReminderRef(
      petId: widget.petId,
      itemId: widget.itemId,
    );
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));
    final itemAsync = ref.watch(reminderDetailsProvider(reminderRef));
    final isSubmitting = ref.watch(
      reminderEditControllerProvider(reminderRef).select(
        (value) => value.asData?.value.isSubmitting ?? false,
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
          return ReminderFormView(
            formKey: _formKey,
            draft: _draft,
            isSubmitting: isSubmitting,
            canSubmit: !isSubmitting,
            canEditRule: _draft.canEditRule,
            canSelectManualSource: false,
            canSelectLogTypeSource: false,
            canChangeSourceType: false,
            submitLabel: 'Сохранить',
            submittingLabel: 'Сохраняем...',
            showSystemRuleNotice: !_draft.canEditRule,
            onSelectManualSource: null,
            onSelectLogTypeSource: null,
            onOpenLogTypePicker: _openLogTypePicker,
            onPickStartsAt: _pickStartsAt,
            onRecurrenceChanged: (value) {
              setState(() {
                _draft.setRecurrenceRule(value);
              });
            },
            onPickUntilDate: _pickUntilDate,
            onClearUntilDate: () => setState(() => _draft.untilDate = null),
            onPushEnabledChanged: (value) => setState(() {
              _draft.pushEnabled = value;
            }),
            onRemindOffsetChanged: (value) => setState(() {
              _draft.remindOffsetMinutes = value;
            }),
            onSubmit: () => _submit(reminderRef),
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
                  reminderDetailsProvider(
                    ReminderRef(
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

  void _applyItem(ReminderDetails item) {
    final didPopulate = _draft.populateFromReminderOnce(item);

    if (didPopulate &&
        _draft.sourceType == 'LOG_TYPE' &&
        item.sourceId != null) {
      Future<void>.microtask(_resolveLogTypeLabel);
    }
  }

  Future<void> _resolveLogTypeLabel() async {
    final selectedId = _draft.selectedLogTypeId;
    if (selectedId == null) {
      return;
    }
    final bootstrap = await ref.read(
      petLogComposerBootstrapProvider(widget.petId).future,
    );
    if (!mounted) {
      return;
    }

    final selectedName = findReminderLogTypeName(bootstrap, selectedId);
    if (selectedName != null) {
      setState(() {
        _draft.selectedLogTypeLabel = selectedName;
      });
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

    final selectedName = findReminderLogTypeName(bootstrap, selectedTypeId);

    setState(() {
      _draft.setLogTypePickerResult(selectedTypeId, selectedName);
    });
  }

  Future<void> _pickStartsAt() async {
    final value = await pickReminderStartsAt(
      context,
      initialValue: _draft.startsAt,
    );
    if (value == null || !mounted) {
      return;
    }

    setState(() => _draft.startsAt = value);
  }

  Future<void> _pickUntilDate() async {
    final value = await pickReminderUntilDate(
      context,
      startsAt: _draft.startsAt,
      initialValue: _draft.untilDate,
    );
    if (value == null || !mounted) {
      return;
    }

    setState(() => _draft.untilDate = value);
  }

  Future<void> _submit(ReminderRef reminderRef) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_draft.canEditRule &&
        _draft.sourceType == 'LOG_TYPE' &&
        _draft.selectedLogTypeId == null) {
      _showError('Выберите тип записи для напоминания.');
      return;
    }

    try {
      final controller = ref.read(
        reminderEditControllerProvider(reminderRef).notifier,
      );
      final saved = _draft.canEditRule
          ? await controller.submitRule(
              form: _draft.buildForm(includeRowVersion: true),
            )
          : await controller.submitReminderSettings(
              pushEnabled: _draft.pushEnabled,
              remindOffsetMinutes:
                  _draft.pushEnabled ? (_draft.remindOffsetMinutes ?? 0) : null,
              rowVersion: _draft.rowVersion,
            );
      if (!saved) {
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showError('Не удалось сохранить изменения.');
    }
  }

  void _showError(String message) {
    showPawlySnackBar(
      context,
      message: message,
      tone: PawlySnackBarTone.error,
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
