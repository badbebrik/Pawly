import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../logs/controllers/logs_controller.dart';
import '../../../logs/models/log_constants.dart';
import '../../../pets/controllers/pets_controller.dart';
import '../../../pets/models/pet_access_policy.dart';
import '../../controllers/reminder_create_controller.dart';
import '../../shared/utils/reminder_date_picker.dart';
import '../../shared/utils/reminder_log_type_lookup.dart';
import '../widgets/form/reminder_form_draft.dart';
import '../widgets/form/reminder_form_view.dart';

class PetReminderCreatePage extends ConsumerStatefulWidget {
  const PetReminderCreatePage({required this.petId, super.key});

  final String petId;

  @override
  ConsumerState<PetReminderCreatePage> createState() =>
      _PetReminderCreatePageState();
}

class _PetReminderCreatePageState extends ConsumerState<PetReminderCreatePage> {
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
    final accessAsync = ref.watch(petAccessPolicyProvider(widget.petId));
    final isSubmitting = ref.watch(
      reminderCreateControllerProvider(widget.petId).select(
        (value) => value.asData?.value.isSubmitting ?? false,
      ),
    );

    return accessAsync.when(
      data: (access) {
        if (!access.remindersWrite) {
          return const PawlyScreenScaffold(
            title: 'Новое напоминание',
            body: _ReminderFormNoAccessView(),
          );
        }
        return _buildForm(access, isSubmitting: isSubmitting);
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
    PetAccessPolicy access, {
    required bool isSubmitting,
  }) {
    final canSubmit =
        !isSubmitting && access.canWriteScheduledSource(_draft.sourceType);

    return PawlyScreenScaffold(
      title: 'Новое напоминание',
      body: ReminderFormView(
        formKey: _formKey,
        draft: _draft,
        isSubmitting: isSubmitting,
        canSubmit: canSubmit,
        canEditRule: true,
        canSelectManualSource: access.petWrite,
        canSelectLogTypeSource: access.logWrite,
        canChangeSourceType: true,
        submitLabel: 'Создать напоминание',
        submittingLabel: 'Создаём...',
        onSelectManualSource: () {
          setState(() {
            _draft.selectManualSource();
          });
        },
        onSelectLogTypeSource: () => setState(() {
          _draft.selectLogTypeSource();
        }),
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
        onSubmit: _submit,
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

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    if (_draft.sourceType == 'LOG_TYPE' && _draft.selectedLogTypeId == null) {
      _showError('Выберите тип записи для напоминания.');
      return;
    }

    try {
      final saved = await ref
          .read(reminderCreateControllerProvider(widget.petId).notifier)
          .submit(form: _draft.buildForm());
      if (!saved) {
        return;
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showError('Не удалось создать напоминание.');
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
