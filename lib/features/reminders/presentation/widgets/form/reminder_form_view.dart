import 'package:flutter/material.dart';

import '../../../../../design_system/design_system.dart';
import '../../../models/reminder_form_constants.dart';
import '../../../shared/formatters/reminder_display_formatters.dart';
import '../../../shared/formatters/reminder_form_formatters.dart';
import '../../../shared/validators/reminder_form_validator.dart';
import 'reminder_form_draft.dart';
import 'reminder_form_widgets.dart';

class ReminderFormView extends StatelessWidget {
  const ReminderFormView({
    required this.formKey,
    required this.draft,
    required this.isSubmitting,
    required this.canSubmit,
    required this.canEditRule,
    required this.canSelectManualSource,
    required this.canSelectLogTypeSource,
    required this.canChangeSourceType,
    required this.submitLabel,
    required this.submittingLabel,
    required this.onSelectManualSource,
    required this.onSelectLogTypeSource,
    required this.onOpenLogTypePicker,
    required this.onPickStartsAt,
    required this.onRecurrenceChanged,
    required this.onPickUntilDate,
    required this.onClearUntilDate,
    required this.onPushEnabledChanged,
    required this.onRemindOffsetChanged,
    required this.onSubmit,
    this.showSystemRuleNotice = false,
    super.key,
  });

  final GlobalKey<FormState> formKey;
  final ReminderFormDraft draft;
  final bool isSubmitting;
  final bool canSubmit;
  final bool canEditRule;
  final bool canSelectManualSource;
  final bool canSelectLogTypeSource;
  final bool canChangeSourceType;
  final String submitLabel;
  final String submittingLabel;
  final VoidCallback? onSelectManualSource;
  final VoidCallback? onSelectLogTypeSource;
  final VoidCallback? onOpenLogTypePicker;
  final VoidCallback? onPickStartsAt;
  final ValueChanged<String> onRecurrenceChanged;
  final VoidCallback? onPickUntilDate;
  final VoidCallback? onClearUntilDate;
  final ValueChanged<bool> onPushEnabledChanged;
  final ValueChanged<int> onRemindOffsetChanged;
  final VoidCallback onSubmit;
  final bool showSystemRuleNotice;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          PawlySpacing.md,
          PawlySpacing.sm,
          PawlySpacing.md,
          PawlySpacing.xl,
        ),
        children: <Widget>[
          if (showSystemRuleNotice) ...<Widget>[
            const _ReminderSystemRuleNotice(),
            const SizedBox(height: PawlySpacing.md),
          ],
          _ReminderSourceSection(
            sourceType: draft.sourceType,
            selectedLogTypeId: draft.selectedLogTypeId,
            selectedLogTypeLabel: draft.selectedLogTypeLabel,
            isSubmitting: isSubmitting,
            canEditRule: canEditRule,
            canSelectManualSource: canSelectManualSource,
            canSelectLogTypeSource: canSelectLogTypeSource,
            canChangeSourceType: canChangeSourceType,
            onSelectManualSource: onSelectManualSource,
            onSelectLogTypeSource: onSelectLogTypeSource,
            onOpenLogTypePicker: onOpenLogTypePicker,
          ),
          const SizedBox(height: PawlySpacing.md),
          ReminderFormSection(
            title: 'Описание',
            child: Column(
              children: <Widget>[
                PawlyTextField(
                  controller: draft.titleController,
                  label: 'Название',
                  hintText: 'Например, Взвесить питомца',
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !isSubmitting && canEditRule,
                  validator: (value) {
                    if (!canEditRule) {
                      return null;
                    }
                    return validateReminderTitle(value);
                  },
                ),
                const SizedBox(height: PawlySpacing.sm),
                PawlyTextField(
                  controller: draft.noteController,
                  label: 'Заметка',
                  hintText: 'Необязательно',
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  enabled: !isSubmitting && canEditRule,
                ),
              ],
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          ReminderFormSection(
            title: 'Расписание',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ReminderPickerRow(
                  title: 'Дата и время',
                  value: formatReminderDateTime(draft.startsAt),
                  actionLabel: 'Изменить',
                  onTap: !isSubmitting && canEditRule ? onPickStartsAt : null,
                ),
                const SizedBox(height: PawlySpacing.md),
                Text(
                  'Повтор',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                ReminderChoiceWrap<String>(
                  values: reminderRecurrenceOptions,
                  selectedValue: draft.recurrenceRule,
                  labelBuilder: reminderRecurrenceOptionLabel,
                  onChanged:
                      !isSubmitting && canEditRule ? onRecurrenceChanged : null,
                ),
                if (draft.recurrenceRule !=
                    noReminderRecurrenceValue) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  PawlyTextField(
                    controller: draft.intervalController,
                    label: 'Интервал',
                    hintText: '1',
                    keyboardType: TextInputType.number,
                    enabled: !isSubmitting && canEditRule,
                    validator: (value) => validateReminderInterval(
                      value,
                      isEnabled: canEditRule &&
                          draft.recurrenceRule != noReminderRecurrenceValue,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.sm),
                  ReminderPickerRow(
                    title: 'Повторять до',
                    value: draft.untilDate == null
                        ? 'Без даты окончания'
                        : formatReminderDate(draft.untilDate!),
                    actionLabel:
                        draft.untilDate == null ? 'Выбрать' : 'Изменить',
                    onTap:
                        !isSubmitting && canEditRule ? onPickUntilDate : null,
                    secondaryActionLabel:
                        draft.untilDate == null ? null : 'Сбросить',
                    onSecondaryTap:
                        !isSubmitting && canEditRule && draft.untilDate != null
                            ? onClearUntilDate
                            : null,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          ReminderFormSection(
            title: 'Уведомление',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        draft.pushEnabled ? 'Включено' : 'Выключено',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Switch(
                      value: draft.pushEnabled,
                      onChanged: isSubmitting ? null : onPushEnabledChanged,
                    ),
                  ],
                ),
                if (draft.pushEnabled) ...<Widget>[
                  const SizedBox(height: PawlySpacing.sm),
                  Text(
                    'Когда напомнить',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xs),
                  ReminderChoiceWrap<int>(
                    values: reminderOffsetMinuteOptions,
                    selectedValue: draft.remindOffsetMinutes ?? 0,
                    labelBuilder: reminderOffsetOptionLabel,
                    onChanged: isSubmitting ? null : onRemindOffsetChanged,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: PawlySpacing.lg),
          PawlyButton(
            label: isSubmitting ? submittingLabel : submitLabel,
            onPressed: canSubmit ? onSubmit : null,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

class _ReminderSourceSection extends StatelessWidget {
  const _ReminderSourceSection({
    required this.sourceType,
    required this.selectedLogTypeId,
    required this.selectedLogTypeLabel,
    required this.isSubmitting,
    required this.canEditRule,
    required this.canSelectManualSource,
    required this.canSelectLogTypeSource,
    required this.canChangeSourceType,
    required this.onSelectManualSource,
    required this.onSelectLogTypeSource,
    required this.onOpenLogTypePicker,
  });

  final String sourceType;
  final String? selectedLogTypeId;
  final String? selectedLogTypeLabel;
  final bool isSubmitting;
  final bool canEditRule;
  final bool canSelectManualSource;
  final bool canSelectLogTypeSource;
  final bool canChangeSourceType;
  final VoidCallback? onSelectManualSource;
  final VoidCallback? onSelectLogTypeSource;
  final VoidCallback? onOpenLogTypePicker;

  @override
  Widget build(BuildContext context) {
    return ReminderFormSection(
      title: 'Тип',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (canChangeSourceType)
            Row(
              children: <Widget>[
                Expanded(
                  child: ReminderOptionCard(
                    title: 'Ручное',
                    subtitle: 'Разовое правило',
                    icon: Icons.notifications_none_rounded,
                    isSelected: sourceType == 'MANUAL',
                    onTap: isSubmitting || !canSelectManualSource
                        ? null
                        : onSelectManualSource,
                  ),
                ),
                const SizedBox(width: PawlySpacing.sm),
                Expanded(
                  child: ReminderOptionCard(
                    title: 'По записи',
                    subtitle: 'Для типа записи',
                    icon: Icons.list_alt_rounded,
                    isSelected: sourceType == 'LOG_TYPE',
                    onTap: isSubmitting || !canSelectLogTypeSource
                        ? null
                        : onSelectLogTypeSource,
                  ),
                ),
              ],
            )
          else
            Text(
              reminderSourceLabel(sourceType),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          if (sourceType == 'LOG_TYPE') ...<Widget>[
            const SizedBox(height: PawlySpacing.sm),
            ReminderPickerRow(
              title: 'Тип записи',
              value: selectedLogTypeLabel ?? 'Не выбран',
              actionLabel: selectedLogTypeId == null ? 'Выбрать' : 'Изменить',
              onTap: isSubmitting || !canEditRule ? null : onOpenLogTypePicker,
            ),
          ],
        ],
      ),
    );
  }
}

class _ReminderSystemRuleNotice extends StatelessWidget {
  const _ReminderSystemRuleNotice();

  @override
  Widget build(BuildContext context) {
    return PawlyCard(
      child: const Text(
        'Для системных правил можно менять только параметры уведомления.',
      ),
    );
  }
}
