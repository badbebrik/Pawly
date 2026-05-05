import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/reminder_actions_controller.dart';
import '../../controllers/reminders_controller.dart';
import '../../models/reminder_models.dart';

class ReminderSettingsCard extends ConsumerStatefulWidget {
  const ReminderSettingsCard({
    required this.petId,
    required this.pushSettingsAsync,
    super.key,
  });

  final String petId;
  final AsyncValue<ReminderPushSettings> pushSettingsAsync;

  @override
  ConsumerState<ReminderSettingsCard> createState() =>
      _ReminderSettingsCardState();
}

class _ReminderSettingsCardState extends ConsumerState<ReminderSettingsCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = widget.pushSettingsAsync.isLoading || _isSubmitting;
    final settings = widget.pushSettingsAsync.asData?.value;
    final enabled = settings?.scheduledItemsEnabled ?? true;

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
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Уведомления',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    enabled ? 'Включены для этого питомца' : 'Выключены',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (isBusy)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Switch(
                value: enabled,
                onChanged: (value) => _togglePushSettings(context, value),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _togglePushSettings(BuildContext context, bool value) async {
    final previous =
        widget.pushSettingsAsync.asData?.value.scheduledItemsEnabled ?? true;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(reminderActionsControllerProvider).updatePushSettings(
            widget.petId,
            scheduledItemsEnabled: value,
          );
    } catch (_) {
      if (context.mounted) {
        showPawlySnackBar(
          context,
          message: 'Не удалось обновить настройки push',
          tone: PawlySnackBarTone.error,
        );
      }
      if (previous != value) {
        ref.invalidate(reminderPushSettingsProvider(widget.petId));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
