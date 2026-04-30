import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../models/calendar_day.dart';
import '../../shared/formatters/calendar_date_formatters.dart';
import '../../shared/formatters/calendar_event_formatters.dart';

class CalendarDayContent extends StatelessWidget {
  const CalendarDayContent({
    required this.response,
    required this.selectedDate,
    required this.petNamesById,
    required this.onOpenOccurrence,
    super.key,
  });

  final CalendarDay response;
  final DateTime selectedDate;
  final Map<String, String> petNamesById;
  final Future<void> Function(CalendarOccurrence occurrence) onOpenOccurrence;

  @override
  Widget build(BuildContext context) {
    if (response.isEmpty) {
      return CalendarNoEventsView(selectedDate: selectedDate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        CalendarSectionHeader(title: 'События', count: response.items.length),
        const SizedBox(height: PawlySpacing.sm),
        ...response.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: PawlySpacing.md),
            child: CalendarEventCard(
              item: item,
              petName: petNamesById[item.petId],
              onTap: () => onOpenOccurrence(item),
            ),
          ),
        ),
      ],
    );
  }
}

class CalendarSectionHeader extends StatelessWidget {
  const CalendarSectionHeader({
    required this.title,
    required this.count,
    super.key,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        Text(
          calendarEventsCountLabel(count),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class CalendarEventCard extends StatelessWidget {
  const CalendarEventCard({
    required this.item,
    this.petName,
    this.onTap,
    super.key,
  });

  final CalendarOccurrence item;
  final String? petName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final timeLabel = calendarEventTimeLabel(item.scheduledFor);
    final metaParts = <String>[
      if (petName != null && petName!.isNotEmpty) petName!,
      calendarItemTypeLabel(item.sourceType),
    ];

    return InkWell(
      onTap: onTap,
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
              SizedBox(
                width: 56,
                child: Text(
                  timeLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0,
                  ),
                ),
              ),
              const SizedBox(width: PawlySpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            item.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: PawlySpacing.sm),
                        Icon(
                          calendarItemIcon(item.sourceType),
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: PawlySpacing.xxs),
                    Text(
                      metaParts.join(' · '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (item.note != null && item.note!.isNotEmpty) ...[
                      const SizedBox(height: PawlySpacing.sm),
                      Text(
                        item.note!,
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

class CalendarNoEventsView extends StatelessWidget {
  const CalendarNoEventsView({
    required this.selectedDate,
    super.key,
  });

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatted = calendarEmptyDayLabel(selectedDate);

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'На $formatted нет событий',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              'Здесь появятся напоминания, визиты и процедуры питомцев.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarLoadingView extends StatelessWidget {
  const CalendarLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: PawlySpacing.xxl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class CalendarErrorView extends StatelessWidget {
  const CalendarErrorView({
    required this.onRetry,
    super.key,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Не удалось загрузить календарь',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: PawlySpacing.xs),
            Text(
              'Попробуйте повторить запрос ещё раз.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
    );
  }
}
