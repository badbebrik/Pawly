import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../providers/health_controllers.dart';

class PetRemindersPage extends ConsumerWidget {
  const PetRemindersPage({
    required this.petId,
    super.key,
  });

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(petScheduledItemsProvider(petId));
    final pushSettingsAsync = ref.watch(petPushSettingsProvider(petId));

    return Scaffold(
      appBar: AppBar(title: const Text('Напоминания')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.pushNamed<bool>(
            'petReminderCreate',
            pathParameters: <String, String>{'petId': petId},
          );
          if (created == true) {
            ref.invalidate(petScheduledItemsProvider(petId));
          }
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Добавить'),
      ),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Padding(
            padding: const EdgeInsets.all(PawlySpacing.lg),
            child: PawlyCard(
              title: const Text('Не удалось загрузить напоминания'),
              footer: PawlyButton(
                label: 'Повторить',
                onPressed: () => ref.invalidate(petScheduledItemsProvider(petId)),
                variant: PawlyButtonVariant.secondary,
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
        data: (items) => _RemindersListView(
          petId: petId,
          items: items,
          pushSettingsAsync: pushSettingsAsync,
        ),
      ),
    );
  }
}

class _RemindersListView extends StatelessWidget {
  const _RemindersListView({
    required this.petId,
    required this.items,
    required this.pushSettingsAsync,
  });

  final String petId;
  final List<ScheduledItemCard> items;
  final AsyncValue<PetPushSettings> pushSettingsAsync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(PawlySpacing.lg),
      children: <Widget>[
        _PetReminderSettingsCard(
          petId: petId,
          pushSettingsAsync: pushSettingsAsync,
        ),
        const SizedBox(height: PawlySpacing.md),
        if (items.isEmpty)
          const PawlyCard(
            title: Text('Напоминаний пока нет'),
            child: Text(
              'Создай первое правило, чтобы оно появилось в календаре и могло присылать уведомления.',
            ),
          )
        else
          ...List<Widget>.generate(items.length, (index) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : PawlySpacing.md,
              ),
              child: _ReminderListItem(
                petId: petId,
                item: items[index],
              ),
            );
          }),
      ],
    );
  }
}

class _PetReminderSettingsCard extends ConsumerStatefulWidget {
  const _PetReminderSettingsCard({
    required this.petId,
    required this.pushSettingsAsync,
  });

  final String petId;
  final AsyncValue<PetPushSettings> pushSettingsAsync;

  @override
  ConsumerState<_PetReminderSettingsCard> createState() =>
      _PetReminderSettingsCardState();
}

class _PetReminderSettingsCardState
    extends ConsumerState<_PetReminderSettingsCard> {
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isBusy = widget.pushSettingsAsync.isLoading || _isSubmitting;
    final settings = widget.pushSettingsAsync.asData?.value;
    final enabled = settings?.scheduledItemsEnabled ?? true;

    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Уведомления по питомцу',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'Выключает или включает push для всех напоминаний этого питомца только у тебя.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: PawlySpacing.sm),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            onChanged: isBusy
                ? null
                : (value) async {
                    final previous = enabled;
                    setState(() {
                      _isSubmitting = true;
                    });
                    try {
                      await ref.read(healthRepositoryProvider).updatePetPushSettings(
                            widget.petId,
                            scheduledItemsEnabled: value,
                          );
                      ref.invalidate(petPushSettingsProvider(widget.petId));
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Не удалось обновить настройки push'),
                          ),
                        );
                      }
                      if (previous != value) {
                        ref.invalidate(petPushSettingsProvider(widget.petId));
                      }
                    } finally {
                      if (mounted) {
                        setState(() {
                          _isSubmitting = false;
                        });
                      }
                    }
                  },
            title: Text(enabled ? 'Включены' : 'Выключены'),
            secondary: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.notifications_rounded),
          ),
        ],
      ),
    );
  }
}

class _ReminderListItem extends ConsumerWidget {
  const _ReminderListItem({
    required this.petId,
    required this.item,
  });

  final String petId;
  final ScheduledItemCard item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PawlyCard(
      onTap: () => _showScheduledItemDetailsSheet(
        context,
        ref,
        petId,
        item,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(PawlyRadius.md),
            ),
            child: Icon(
              _scheduledItemIcon(item.sourceType),
              size: 22,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: PawlySpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xxs),
                Text(
                  _scheduledItemSecondaryLine(item),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if ((item.notePreview ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: PawlySpacing.xs),
                  Text(
                    item.notePreview!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: PawlySpacing.sm),
          Icon(
            Icons.chevron_right_rounded,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

String _scheduledItemSecondaryLine(ScheduledItemCard item) {
  final parts = <String>[
    _scheduledItemStartLabel(item.startsAt),
    _scheduledItemRecurrenceLabel(item.recurrence),
    _scheduledItemReminderLabel(
      pushEnabled: item.pushEnabled,
      remindOffsetMinutes: item.remindOffsetMinutes,
    ),
  ].where((value) => value.isNotEmpty).toList(growable: false);

  return parts.join(' • ');
}

String _scheduledItemStartLabel(DateTime? value) {
  if (value == null) {
    return 'Дата не задана';
  }

  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day.$month в $hour:$minute';
}

String _scheduledItemRecurrenceLabel(ScheduledItemRecurrence? recurrence) {
  if (recurrence == null) {
    return 'Без повтора';
  }

  return switch (recurrence.rule) {
    'DAILY' => recurrence.interval <= 1
        ? 'Каждый день'
        : 'Каждые ${recurrence.interval} дн.',
    'WEEKLY' => recurrence.interval <= 1
        ? 'Каждую неделю'
        : 'Каждые ${recurrence.interval} нед.',
    'MONTHLY' => recurrence.interval <= 1
        ? 'Каждый месяц'
        : 'Каждые ${recurrence.interval} мес.',
    'YEARLY' => recurrence.interval <= 1
        ? 'Каждый год'
        : 'Каждые ${recurrence.interval} г.',
    _ => 'Повтор ${recurrence.rule}',
  };
}

String _scheduledItemReminderLabel({
  required bool pushEnabled,
  required int? remindOffsetMinutes,
}) {
  if (!pushEnabled) {
    return 'Без уведомления';
  }

  if (remindOffsetMinutes == null || remindOffsetMinutes == 0) {
    return 'В момент события';
  }

  if (remindOffsetMinutes % (60 * 24) == 0) {
    final days = remindOffsetMinutes ~/ (60 * 24);
    return days == 1 ? 'За 1 день' : 'За $days дн.';
  }

  if (remindOffsetMinutes % 60 == 0) {
    final hours = remindOffsetMinutes ~/ 60;
    return hours == 1 ? 'За 1 час' : 'За $hours ч.';
  }

  return 'За $remindOffsetMinutes мин.';
}

String _scheduledItemSourceLabel(String sourceType) {
  return switch (sourceType) {
    'MANUAL' => 'Ручное',
    'LOG_TYPE' => 'По типу записи',
    'PET_EVENT' => 'Событие питомца',
    'VET_VISIT' => 'Визит к врачу',
    'VACCINATION' => 'Вакцинация',
    'PROCEDURE' => 'Процедура',
    _ => sourceType,
  };
}

IconData _scheduledItemIcon(String sourceType) {
  return switch (sourceType) {
    'LOG_TYPE' => Icons.monitor_weight_rounded,
    'PET_EVENT' => Icons.celebration_rounded,
    'VET_VISIT' => Icons.local_hospital_rounded,
    'VACCINATION' => Icons.vaccines_rounded,
    'PROCEDURE' => Icons.medical_services_rounded,
    _ => Icons.notifications_active_rounded,
  };
}

Future<void> _showScheduledItemDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  String petId,
  ScheduledItemCard item,
) async {
  final parentContext = context;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final canDelete = _isUserManagedRule(item.sourceType);

  await showModalBottomSheet<void>(
    context: context,
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
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: PawlySpacing.sm),
              Wrap(
                spacing: PawlySpacing.xs,
                runSpacing: PawlySpacing.xs,
                children: <Widget>[
                  _ReminderMetaChip(label: _scheduledItemSourceLabel(item.sourceType)),
                  _ReminderMetaChip(
                    label: _scheduledItemReminderLabel(
                      pushEnabled: item.pushEnabled,
                      remindOffsetMinutes: item.remindOffsetMinutes,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: PawlySpacing.md),
              _ReminderDetailRow(
                label: 'Старт',
                value: _scheduledItemStartLabel(item.startsAt),
              ),
              _ReminderDetailRow(
                label: 'Повтор',
                value: _scheduledItemRecurrenceLabel(item.recurrence),
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
                      onPressed: () async {
                        Navigator.of(context).pop();
                        final updated = await parentContext.pushNamed<bool>(
                          'petReminderEdit',
                          pathParameters: <String, String>{
                            'petId': petId,
                            'itemId': item.id,
                          },
                        );
                        if (updated == true) {
                          ref.invalidate(petScheduledItemsProvider(petId));
                        }
                      },
                      variant: PawlyButtonVariant.secondary,
                    ),
                  ),
                  if (canDelete) ...<Widget>[
                    const SizedBox(width: PawlySpacing.sm),
                    Expanded(
                      child: PawlyButton(
                        label: 'Удалить',
                        onPressed: () async {
                          Navigator.of(context).pop();
                          final confirmed = await showDialog<bool>(
                            context: parentContext,
                            builder: (dialogContext) => AlertDialog(
                              title: const Text('Удалить напоминание?'),
                              content: Text(
                                'Напоминание "${item.title}" будет удалено.',
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
                          );
                          if (confirmed != true) {
                            return;
                          }
                          try {
                            await ref.read(healthRepositoryProvider).deleteScheduledItem(
                                  petId,
                                  item.id,
                                  rowVersion: item.rowVersion,
                                );
                            ref.invalidate(petScheduledItemsProvider(petId));
                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Напоминание удалено'),
                                ),
                              );
                            }
                          } catch (_) {
                            if (parentContext.mounted) {
                              ScaffoldMessenger.of(parentContext).showSnackBar(
                                const SnackBar(
                                  content: Text('Не удалось удалить напоминание'),
                                ),
                              );
                            }
                          }
                        },
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

bool _isUserManagedRule(String sourceType) {
  return sourceType == 'MANUAL' ||
      sourceType == 'LOG_TYPE' ||
      sourceType == 'PET_EVENT';
}

class _ReminderMetaChip extends StatelessWidget {
  const _ReminderMetaChip({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.sm,
          vertical: PawlySpacing.xxs,
        ),
        child: Text(label),
      ),
    );
  }
}

class _ReminderDetailRow extends StatelessWidget {
  const _ReminderDetailRow({
    required this.label,
    required this.value,
  });

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
