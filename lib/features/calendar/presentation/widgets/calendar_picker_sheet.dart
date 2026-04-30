import 'package:flutter/material.dart';

import '../../../../design_system/design_system.dart';
import '../../shared/formatters/calendar_date_formatters.dart';
import 'calendar_controls.dart';

class CalendarPickerSheet extends StatefulWidget {
  const CalendarPickerSheet({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    super.key,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<CalendarPickerSheet> {
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    _visibleMonth = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final height = MediaQuery.sizeOf(context).height * 0.56;
    final monthTitle = calendarMonthTitle(_visibleMonth);

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            0,
            PawlySpacing.md,
            PawlySpacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  PawlySpacing.xs,
                  PawlySpacing.sm,
                  PawlySpacing.sm,
                  PawlySpacing.sm,
                ),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Выберите дату',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: PawlySpacing.xxs),
                          Text(
                            monthTitle,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    CalendarIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _canShowPreviousMonth
                          ? () => setState(() {
                                _visibleMonth = _shiftMonth(_visibleMonth, -1);
                              })
                          : null,
                    ),
                    const SizedBox(width: PawlySpacing.xs),
                    CalendarIconButton(
                      icon: Icons.chevron_right_rounded,
                      onTap: _canShowNextMonth
                          ? () => setState(() {
                                _visibleMonth = _shiftMonth(_visibleMonth, 1);
                              })
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: PawlySpacing.sm),
              Row(
                children: const <Widget>[
                  _WeekdayLabel('Пн'),
                  _WeekdayLabel('Вт'),
                  _WeekdayLabel('Ср'),
                  _WeekdayLabel('Чт'),
                  _WeekdayLabel('Пт'),
                  _WeekdayLabel('Сб'),
                  _WeekdayLabel('Вс'),
                ],
              ),
              const SizedBox(height: PawlySpacing.xs),
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 42,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: PawlySpacing.xs,
                    crossAxisSpacing: PawlySpacing.xs,
                  ),
                  itemBuilder: (context, index) {
                    final date = _dateForGridIndex(index);
                    if (date == null) {
                      return const SizedBox.shrink();
                    }

                    final isSelected =
                        isSameCalendarDate(date, widget.selectedDate);
                    final isToday = isSameCalendarDate(date, DateTime.now());
                    final isEnabled = _isDateEnabled(date);

                    return _MonthDayButton(
                      day: date.day,
                      isSelected: isSelected,
                      isToday: isToday,
                      isEnabled: isEnabled,
                      onTap: isEnabled
                          ? () => Navigator.of(context).pop(date)
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool get _canShowPreviousMonth {
    return !_shiftMonth(
      _visibleMonth,
      -1,
    ).isBefore(DateTime(widget.firstDate.year, widget.firstDate.month));
  }

  bool get _canShowNextMonth {
    return !_shiftMonth(
      _visibleMonth,
      1,
    ).isAfter(DateTime(widget.lastDate.year, widget.lastDate.month));
  }

  DateTime? _dateForGridIndex(int index) {
    final firstDayOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final leadingDays = firstDayOfMonth.weekday - 1;
    final day = index - leadingDays + 1;
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;

    if (day < 1 || day > daysInMonth) {
      return null;
    }

    return DateTime(_visibleMonth.year, _visibleMonth.month, day);
  }

  bool _isDateEnabled(DateTime date) {
    final normalized = normalizeCalendarDate(date);
    return !normalized.isBefore(normalizeCalendarDate(widget.firstDate)) &&
        !normalized.isAfter(normalizeCalendarDate(widget.lastDate));
  }

  DateTime _shiftMonth(DateTime month, int delta) {
    return DateTime(month.year, month.month + delta);
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Center(
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _MonthDayButton extends StatelessWidget {
  const _MonthDayButton({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    required this.onTap,
  });

  final int day;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Ink(
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isToday && !isSelected
                ? colorScheme.primary.withValues(alpha: 0.56)
                : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            '$day',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : isEnabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.32),
                  fontWeight:
                      isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                ),
          ),
        ),
      ),
    );
  }
}
