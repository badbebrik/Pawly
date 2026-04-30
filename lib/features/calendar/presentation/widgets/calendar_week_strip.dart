import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/design_system.dart';
import '../../controllers/calendar_controller.dart';
import '../../models/calendar_day.dart';
import '../../models/calendar_keys.dart';
import '../../shared/formatters/calendar_date_formatters.dart';

class CalendarWeekStrip extends ConsumerStatefulWidget {
  const CalendarWeekStrip({
    required this.selectedDate,
    required this.onSelectDate,
    super.key,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  ConsumerState<CalendarWeekStrip> createState() => _CalendarWeekStripState();
}

class _CalendarWeekStripState extends ConsumerState<CalendarWeekStrip> {
  static const double _itemWidth = 58;
  static const double _itemSpacing = PawlySpacing.xs;
  static const int _selectedIndex = 15;
  static const int _daysBefore = 15;
  static const int _daysAfter = 15;

  late final ScrollController _scrollController;
  late DateTime _anchorDate;
  double _viewportWidth = 0;

  @override
  void initState() {
    super.initState();
    _anchorDate = normalizeCalendarDate(widget.selectedDate);
    _scrollController = ScrollController();
    _scheduleCenterSelected();
  }

  @override
  void didUpdateWidget(covariant CalendarWeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSelected = normalizeCalendarDate(widget.selectedDate);
    final rangeStart = _anchorDate.subtract(const Duration(days: _daysBefore));
    final rangeEnd = _anchorDate.add(const Duration(days: _daysAfter));
    final isOutsideCurrentRange =
        nextSelected.isBefore(rangeStart) || nextSelected.isAfter(rangeEnd);

    if (isOutsideCurrentRange) {
      _anchorDate = nextSelected;
      _scheduleCenterSelected();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCenterSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      if (!_scrollController.hasClients || _viewportWidth <= 0) {
        return;
      }

      final targetOffset = (_selectedIndex * (_itemWidth + _itemSpacing)) -
          ((_viewportWidth - _itemWidth) / 2);
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );
      _scrollController.jumpTo(clampedOffset);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stripDates = buildCalendarStripDates(
      _anchorDate,
      daysBefore: _daysBefore,
      daysAfter: _daysAfter,
    );
    final markersAsync = ref.watch(
      calendarMarkersProvider(
        CalendarMarkersKey(
          dateFrom: stripDates.first,
          dateTo: stripDates.last,
        ),
      ),
    );
    final markersByDate =
        markersAsync.asData?.value ?? const <String, CalendarMarker>{};
    final today = normalizeCalendarDate(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewportWidth != constraints.maxWidth) {
          _viewportWidth = constraints.maxWidth;
          _scheduleCenterSelected();
        }

        return SizedBox(
          height: 76,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: stripDates.length,
            separatorBuilder: (_, __) => const SizedBox(width: PawlySpacing.xs),
            itemBuilder: (context, index) {
              final date = stripDates[index];
              final marker = markersByDate[formatCalendarApiDate(date)];

              return _CalendarWeekDayButton(
                date: date,
                marker: marker,
                isSelected: isSameCalendarDate(date, widget.selectedDate),
                isToday: isSameCalendarDate(date, today),
                onTap: () => widget.onSelectDate(date),
              );
            },
          ),
        );
      },
    );
  }
}

class _CalendarWeekDayButton extends StatelessWidget {
  const _CalendarWeekDayButton({
    required this.date,
    required this.marker,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
  });

  final DateTime date;
  final CalendarMarker? marker;
  final bool isSelected;
  final bool isToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.xl),
      child: Ink(
        width: _CalendarWeekStripState._itemWidth,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(PawlyRadius.xl),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : isToday
                    ? colorScheme.primary.withValues(alpha: 0.54)
                    : colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: PawlySpacing.xs,
            vertical: PawlySpacing.sm,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                calendarShortWeekdayLabel(date),
                maxLines: 1,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: PawlySpacing.xxs),
              Text(
                '${date.day}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: PawlySpacing.xxs),
              SizedBox(
                height: 5,
                child: marker == null || !marker!.hasEvents
                    ? null
                    : _CalendarMarkerDot(
                        marker: marker!,
                        isSelected: isSelected,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarMarkerDot extends StatelessWidget {
  const _CalendarMarkerDot({
    required this.marker,
    required this.isSelected,
  });

  final CalendarMarker marker;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.onPrimary
              : marker.plannedCount > 0
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant.withValues(alpha: 0.56),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
