import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../../pets/models/pet_access_policy.dart';
import '../../models/reminder_models.dart';
import '../../shared/formatters/reminder_display_formatters.dart';
import '../../states/reminders_state.dart';
import 'reminder_details_sheet.dart';
import 'reminder_settings_card.dart';
import 'reminders_state_views.dart';

class RemindersListView extends StatelessWidget {
  const RemindersListView({
    required this.petId,
    required this.access,
    required this.items,
    required this.pushSettingsAsync,
    super.key,
  });

  final String petId;
  final PetAccessPolicy access;
  final RemindersState items;
  final AsyncValue<ReminderPushSettings> pushSettingsAsync;

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
        ReminderSettingsCard(
          petId: petId,
          pushSettingsAsync: pushSettingsAsync,
        ),
        const SizedBox(height: PawlySpacing.md),
        if (!access.remindersWrite) ...<Widget>[
          const ReminderReadOnlyNotice(),
          const SizedBox(height: PawlySpacing.md),
        ],
        if (items.isEmpty)
          const EmptyRemindersCard()
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

  List<Widget> _buildReminderItems(List<ReminderEntry> entries) {
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

class _ReminderListItem extends ConsumerWidget {
  const _ReminderListItem({
    required this.petId,
    required this.access,
    required this.entry,
  });

  final String petId;
  final PetAccessPolicy access;
  final ReminderEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final item = entry.item;

    return InkWell(
      onTap: () => showReminderDetailsSheet(
        context: context,
        ref: ref,
        petId: petId,
        access: access,
        item: item,
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
                      reminderSecondaryLine(item),
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
