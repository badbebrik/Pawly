import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../pets/data/pets_repository.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../providers/health_controllers.dart';

class PetRemindersPage extends ConsumerWidget {
  const PetRemindersPage({required this.petId, super.key});

  final String petId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accessAsync = ref.watch(petAccessPolicyProvider(petId));

    return accessAsync.when(
      data: (access) {
        if (!access.remindersRead) {
          return const PawlyScreenScaffold(
            title: 'Напоминания',
            body: _ReminderNoAccessView(),
          );
        }

        final remindersAsync = ref.watch(petScheduledItemsProvider(petId));
        final pushSettingsAsync = ref.watch(petPushSettingsProvider(petId));
        return PawlyScreenScaffold(
          title: 'Напоминания',
          actions: <Widget>[
            if (access.remindersWrite) ...<Widget>[
              _ReminderAddButton(
                onTap: () async {
                  final created = await context.pushNamed<bool>(
                    'petReminderCreate',
                    pathParameters: <String, String>{'petId': petId},
                  );
                  if (created == true) {
                    ref.invalidate(petScheduledItemsProvider(petId));
                  }
                },
              ),
              const SizedBox(width: PawlySpacing.sm),
            ],
          ],
          body: remindersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => _ReminderErrorView(
              onRetry: () => ref.invalidate(petScheduledItemsProvider(petId)),
            ),
            data: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(petScheduledItemsProvider(petId));
                await ref.read(petScheduledItemsProvider(petId).future);
              },
              child: _RemindersListView(
                petId: petId,
                access: access,
                items: items,
                pushSettingsAsync: pushSettingsAsync,
              ),
            ),
          ),
        );
      },
      loading: () => const PawlyScreenScaffold(
        title: 'Напоминания',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => PawlyScreenScaffold(
        title: 'Напоминания',
        body: _ReminderErrorView(
          onRetry: () => ref.invalidate(petAccessPolicyProvider(petId)),
        ),
      ),
    );
  }
}

class _ReminderAddButton extends StatelessWidget {
  const _ReminderAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        width: 42,
        height: 42,
        child: Icon(Icons.add_rounded, color: colorScheme.primary),
      ),
    );
  }
}

class _RemindersListView extends StatelessWidget {
  const _RemindersListView({
    required this.petId,
    required this.access,
    required this.items,
    required this.pushSettingsAsync,
  });

  final String petId;
  final PetAccessPolicy access;
  final PetScheduledItemsState items;
  final AsyncValue<PetPushSettings> pushSettingsAsync;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        PawlySpacing.md,
        PawlySpacing.sm,
        PawlySpacing.md,
        PawlySpacing.xl,
      ),
      children: <Widget>[
        _PetReminderSettingsCard(
          petId: petId,
          pushSettingsAsync: pushSettingsAsync,
        ),
        const SizedBox(height: PawlySpacing.md),
        if (!access.remindersWrite) ...<Widget>[
          const _ReminderReadOnlyNotice(),
          const SizedBox(height: PawlySpacing.md),
        ],
        if (items.isEmpty)
          const _EmptyRemindersCard()
        else ...<Widget>[
          if (items.active.isNotEmpty) ...<Widget>[
            _ReminderSectionHeader(
              title: 'Активные',
              count: items.active.length,
            ),
            const SizedBox(height: PawlySpacing.sm),
            ..._buildReminderItems(items.active),
          ],
          if (items.past.isNotEmpty) ...<Widget>[
            if (items.active.isNotEmpty)
              const SizedBox(height: PawlySpacing.lg),
            _ReminderSectionHeader(
              title: 'Прошедшие',
              count: items.past.length,
            ),
            const SizedBox(height: PawlySpacing.sm),
            ..._buildReminderItems(items.past),
          ],
        ],
      ],
    );
  }

  List<Widget> _buildReminderItems(List<ScheduledReminderEntry> entries) {
    return List<Widget>.generate(entries.length, (index) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: index == entries.length - 1 ? 0 : PawlySpacing.md,
        ),
        child: _ReminderListItem(
          petId: petId,
          access: access,
          entry: entries[index],
        ),
      );
    });
  }
}

class _ReminderSectionHeader extends StatelessWidget {
  const _ReminderSectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
        ),
        Text(
          count.toString(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
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

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(PawlyRadius.xl),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        children: <Widget>[
          Padding(
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
                    onChanged: (value) async {
                      final previous = enabled;
                      setState(() => _isSubmitting = true);
                      try {
                        await ref
                            .read(healthRepositoryProvider)
                            .updatePetPushSettings(
                              widget.petId,
                              scheduledItemsEnabled: value,
                            );
                        ref.invalidate(petPushSettingsProvider(widget.petId));
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Не удалось обновить настройки push',
                              ),
                            ),
                          );
                        }
                        if (previous != value) {
                          ref.invalidate(petPushSettingsProvider(widget.petId));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isSubmitting = false);
                        }
                      }
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReminderListItem extends ConsumerWidget {
  const _ReminderListItem({
    required this.petId,
    required this.access,
    required this.entry,
  });

  final String petId;
  final PetAccessPolicy access;
  final ScheduledReminderEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = entry.item;

    return InkWell(
      onTap: () => _showScheduledItemDetailsSheet(
        context,
        ref,
        petId,
        access,
        item,
      ),
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: Ink(
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _ReminderTimeBadge(value: entry.displayAt),
              const SizedBox(width: PawlySpacing.md),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if ((item.notePreview ?? '').isNotEmpty) ...<Widget>[
                      const SizedBox(height: PawlySpacing.sm),
                      Text(
                        item.notePreview!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReminderTimeBadge extends StatelessWidget {
  const _ReminderTimeBadge({required this.value});

  final DateTime? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final local = value?.toLocal();

    return SizedBox(
      width: 56,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            local == null
                ? '--:--'
                : '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          if (local != null) ...<Widget>[
            const SizedBox(height: PawlySpacing.xxs),
            Text(
              '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyRemindersCard extends StatelessWidget {
  const _EmptyRemindersCard();

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
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: Column(
          children: <Widget>[
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.62,
                ),
                borderRadius: BorderRadius.circular(PawlyRadius.xl),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.64),
                ),
              ),
              child: Icon(
                Icons.notifications_none_rounded,
                size: 34,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: PawlySpacing.md),
            Text(
              'Напоминаний пока нет',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              'Создайте первое правило, чтобы оно появилось в календаре.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

String _scheduledItemSecondaryLine(ScheduledItemCard item) {
  final parts = <String>[
    _scheduledItemSourceLabel(item.sourceType),
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

Future<void> _showScheduledItemDetailsSheet(
  BuildContext context,
  WidgetRef ref,
  String petId,
  PetAccessPolicy access,
  ScheduledItemCard item,
) async {
  final parentContext = context;
  final theme = Theme.of(context);
  final colorScheme = theme.colorScheme;
  final canWrite = access.canWriteScheduledSource(item.sourceType);
  final canDelete = canWrite && _isUserManagedRule(item.sourceType);

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
                _scheduledItemSourceLabel(item.sourceType),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
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
                                  petScheduledItemsProvider(petId),
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
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(false),
                                  child: const Text('Отмена'),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(true),
                                  child: const Text('Удалить'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed != true) {
                            return;
                          }
                          try {
                            await ref
                                .read(healthRepositoryProvider)
                                .deleteScheduledItem(
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
                                  content: Text(
                                    'Не удалось удалить напоминание',
                                  ),
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

class _ReminderNoAccessView extends StatelessWidget {
  const _ReminderNoAccessView();

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
                  'У вас нет права просмотра напоминаний этого питомца.',
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

class _ReminderReadOnlyNotice extends StatelessWidget {
  const _ReminderReadOnlyNotice();

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
        child: Row(
          children: <Widget>[
            Icon(
              Icons.lock_outline_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: PawlySpacing.sm),
            Expanded(
              child: Text(
                'Редактирование недоступно',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderErrorView extends StatelessWidget {
  const _ReminderErrorView({required this.onRetry});

  final VoidCallback onRetry;

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
                  'Не удалось загрузить напоминания',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: PawlySpacing.xs),
                Text(
                  'Попробуйте обновить экран ещё раз.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
      ),
    );
  }
}
