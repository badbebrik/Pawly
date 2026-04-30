import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/formatters/calendar_date_formatters.dart';
import 'calendar_controls.dart';
import 'calendar_week_strip.dart';

class CalendarDateHeader extends StatelessWidget {
  const CalendarDateHeader({
    required this.selectedDate,
    required this.onSelectDate,
    required this.onPickDate,
    required this.onToday,
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final Future<void> Function() onPickDate;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = calendarDayTitle(selectedDate);
    final monthTitle = calendarMonthTitle(selectedDate);
    final isToday = isSameCalendarDate(selectedDate, DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    monthTitle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            if (!isToday) ...[
              CalendarHeaderButton(label: 'Сегодня', onTap: onToday),
              const SizedBox(width: PawlySpacing.xs),
            ],
            CalendarIconButton(
              onTap: onPickDate,
              icon: Icons.calendar_month_rounded,
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.md),
        CalendarWeekStrip(
          selectedDate: selectedDate,
          onSelectDate: onSelectDate,
        ),
      ],
    );
  }
}
