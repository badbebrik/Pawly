import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/models/pet_access_policy.dart';
import '../../controllers/reminder_actions_controller.dart';
import '../../controllers/reminders_controller.dart';
import '../../models/reminder_models.dart';
import '../../shared/formatters/reminder_display_formatters.dart';
import '../../shared/utils/reminder_source_utils.dart';

Future<void> showReminderDetailsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String petId,
  required PetAccessPolicy access,
  required ReminderListItem item,
}) async {
  final parentContext = context;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final canWrite = access.canWriteScheduledSource(item.sourceType);
  final canDelete = canWrite && isUserManagedReminderSource(item.sourceType);

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(PawlyRadius.xl)),
    ),
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.md,
            PawlySpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                item.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                reminderSourceLabel(item.sourceType),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: PawlySpacing.md),
              _ReminderDetailRow(
                label: 'Старт',
                value: reminderStartLabel(item.startsAt),
              ),
              _ReminderDetailRow(
                label: 'Повтор',
                value: reminderRecurrenceLabel(item.recurrence),
              ),
              if ((item.notePreview ?? '').isNotEmpty) ...<Widget>[
                const SizedBox(height: PawlySpacing.sm),
                Text(
                  item.notePreview!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: PawlySpacing.md),
              Row(
                children: <Widget>[
                  Expanded(
                    child: PawlyButton(
                      label: 'Редактировать',
                      onPressed: canWrite
                          ? () async {
                              Navigator.of(context).pop();
                              final updated =
                                  await parentContext.pushNamed<bool>(
                                'petReminderEdit',
                                pathParameters: <String, String>{
                                  'petId': petId,
                                  'itemId': item.id,
                                },
                              );
                              if (updated == true) {
                                ref.invalidate(
                                  petRemindersControllerProvider(petId),
                                );
                              }
                            }
                          : null,
                      variant: PawlyButtonVariant.secondary,
                    ),
                  ),
                  if (canDelete) ...<Widget>[
                    const SizedBox(width: PawlySpacing.sm),
                    Expanded(
                      child: PawlyButton(
                        label: 'Удалить',
                        onPressed: () => _deleteReminder(
                          context: context,
                          parentContext: parentContext,
                          ref: ref,
                          petId: petId,
                          item: item,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _deleteReminder({
  required BuildContext context,
  required BuildContext parentContext,
  required WidgetRef ref,
  required String petId,
  required ReminderListItem item,
}) async {
  Navigator.of(context).pop();
  final confirmed = await showDialog<bool>(
    context: parentContext,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Удалить напоминание?'),
      content: Text('Напоминание "${item.title}" будет удалено.'),
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
  );
  if (confirmed != true) {
    return;
  }

  try {
    await ref.read(reminderActionsControllerProvider).deleteReminder(
          petId,
          item.id,
          rowVersion: item.rowVersion,
        );
    if (parentContext.mounted) {
      showPawlySnackBar(
        parentContext,
        message: 'Напоминание удалено',
        tone: PawlySnackBarTone.success,
      );
    }
  } catch (_) {
    if (parentContext.mounted) {
      showPawlySnackBar(
        parentContext,
        message: 'Не удалось удалить напоминание',
        tone: PawlySnackBarTone.error,
      );
    }
  }
}

class _ReminderDetailRow extends StatelessWidget {
  const _ReminderDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: PawlySpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: PawlySpacing.sm),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
