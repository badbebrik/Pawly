import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../../../pets/presentation/providers/active_pet_controller.dart';
import '../../../pets/presentation/providers/active_pet_details_controller.dart';
import '../../../pets/presentation/providers/pets_controller.dart';
import '../providers/calendar_controllers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final petsState = ref.watch(petsControllerProvider).asData?.value;
    final petItems = petsState?.items ?? const [];
    final petNamesById = <String, String>{
      for (final item in petItems) item.id: item.name,
    };
    final dayAsync = ref.watch(
      calendarDayProvider(CalendarDayRef(date: selectedDate)),
    );

    return PawlyScreenScaffold(
      title: 'Календарь',
      actions: const <Widget>[ChatAppBarAction()],
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            calendarDayProvider(CalendarDayRef(date: selectedDate)),
          );
          ref.invalidate(calendarMarkersProvider);
          ref.invalidate(petsControllerProvider);
          await ref.read(
            calendarDayProvider(CalendarDayRef(date: selectedDate)).future,
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            PawlySpacing.md,
            PawlySpacing.sm,
            PawlySpacing.md,
            PawlySpacing.xl,
          ),
          children: <Widget>[
            _CalendarDateHeader(
              selectedDate: selectedDate,
              onSelectDate: _selectDate,
              onPickDate: _pickDate,
              onToday: _jumpToToday,
            ),
            const SizedBox(height: PawlySpacing.lg),
            dayAsync.when(
              data: (response) => _CalendarDayContent(
                response: response,
                selectedDate: selectedDate,
                petNamesById: petNamesById,
                onOpenOccurrence: _openOccurrence,
              ),
              loading: () => const _CalendarLoadingView(),
              error: (error, _) => _CalendarErrorView(
                onRetry: () {
                  ref.invalidate(
                    calendarDayProvider(CalendarDayRef(date: selectedDate)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selectedDate = ref.read(calendarSelectedDateProvider);
    final now = DateTime.now();

    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return _CalendarPickerSheet(
          selectedDate: selectedDate,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
        );
      },
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    ref.read(calendarSelectedDateProvider.notifier).setDate(pickedDate);
  }

  void _selectDate(DateTime value) {
    ref.read(calendarSelectedDateProvider.notifier).setDate(value);
  }

  void _jumpToToday() {
    ref.read(calendarSelectedDateProvider.notifier).jumpToToday();
  }

  Future<void> _openOccurrence(ScheduledItemOccurrence occurrence) async {
    final petId = occurrence.petId;
    if (petId.isEmpty) {
      return;
    }

    await ref.read(activePetControllerProvider.notifier).selectPet(petId);
    ref.invalidate(activePetDetailsControllerProvider);

    if (!mounted) {
      return;
    }

    final rule = occurrence.rule;
    final sourceType = rule.sourceType;
    final sourceId = rule.sourceId;

    if (sourceType == 'VET_VISIT' && sourceId != null && sourceId.isNotEmpty) {
      context.pushNamed(
        'petVetVisitDetails',
        pathParameters: <String, String>{'petId': petId, 'visitId': sourceId},
      );
      return;
    }

    if (sourceType == 'VACCINATION' &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      context.pushNamed(
        'petVaccinationDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'vaccinationId': sourceId,
        },
      );
      return;
    }

    if (sourceType == 'PROCEDURE' && sourceId != null && sourceId.isNotEmpty) {
      context.pushNamed(
        'petProcedureDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'procedureId': sourceId,
        },
      );
      return;
    }

    if (sourceType == 'LOG_TYPE' && sourceId != null && sourceId.isNotEmpty) {
      context.pushNamed(
        'petLogCreate',
        pathParameters: <String, String>{'petId': petId},
        queryParameters: <String, String>{'logTypeId': sourceId},
      );
      return;
    }

    if (sourceType == 'MANUAL' || sourceType == 'PET_EVENT') {
      context.pushNamed(
        'petReminderEdit',
        pathParameters: <String, String>{
          'petId': petId,
          'itemId': occurrence.scheduledItemId,
        },
      );
      return;
    }

    context.pushNamed(
      'petReminders',
      pathParameters: <String, String>{'petId': petId},
    );
  }
}

class _CalendarDateHeader extends StatelessWidget {
  const _CalendarDateHeader({
    required this.selectedDate,
    required this.onSelectDate,
    required this.onPickDate,
    required this.onToday,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final Future<void> Function() onPickDate;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatter = DateFormat('d MMMM, EEEE', 'ru');
    final title = _capitalize(formatter.format(selectedDate));
    final monthTitle = _capitalize(
      DateFormat('LLLL yyyy', 'ru').format(selectedDate),
    );
    final isToday = _isSameDate(selectedDate, DateTime.now());

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
              _CalendarHeaderButton(label: 'Сегодня', onTap: onToday),
              const SizedBox(width: PawlySpacing.xs),
            ],
            _CalendarIconButton(
              onTap: onPickDate,
              icon: Icons.calendar_month_rounded,
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.md),
        _WeekStrip(selectedDate: selectedDate, onSelectDate: onSelectDate),
      ],
    );
  }
}

class _CalendarPickerSheet extends StatefulWidget {
  const _CalendarPickerSheet({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CalendarPickerSheet> createState() => _CalendarPickerSheetState();
}

class _CalendarPickerSheetState extends State<_CalendarPickerSheet> {
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
    final monthTitle = _capitalize(
      DateFormat('LLLL yyyy', 'ru').format(_visibleMonth),
    );

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
                    _CalendarIconButton(
                      icon: Icons.chevron_left_rounded,
                      onTap: _canShowPreviousMonth
                          ? () => setState(() {
                                _visibleMonth = _shiftMonth(_visibleMonth, -1);
                              })
                          : null,
                    ),
                    const SizedBox(width: PawlySpacing.xs),
                    _CalendarIconButton(
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

                    final isSelected = _isSameDate(date, widget.selectedDate);
                    final isToday = _isSameDate(date, DateTime.now());
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

class _CalendarHeaderButton extends StatelessWidget {
  const _CalendarHeaderButton({required this.label, required this.onTap});

  final String label;
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
          borderRadius: BorderRadius.circular(PawlyRadius.pill),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.72),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.sm,
          vertical: PawlySpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _CalendarIconButton extends StatelessWidget {
  const _CalendarIconButton({required this.onTap, required this.icon});

  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(PawlyRadius.pill),
      child: Opacity(
        opacity: isEnabled ? 1 : 0.36,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.72),
            ),
          ),
          child: Icon(icon, size: 21, color: colorScheme.onSurface),
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerStatefulWidget {
  const _WeekStrip({required this.selectedDate, required this.onSelectDate});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  ConsumerState<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends ConsumerState<_WeekStrip> {
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
    _scheduleCenterSelected(jump: true);
  }

  @override
  void didUpdateWidget(covariant _WeekStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextSelected = normalizeCalendarDate(widget.selectedDate);
    final rangeStart = _anchorDate.subtract(const Duration(days: _daysBefore));
    final rangeEnd = _anchorDate.add(const Duration(days: _daysAfter));
    final isOutsideCurrentRange =
        nextSelected.isBefore(rangeStart) || nextSelected.isAfter(rangeEnd);

    if (isOutsideCurrentRange) {
      _anchorDate = nextSelected;
      _scheduleCenterSelected(jump: true);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleCenterSelected({bool jump = false}) {
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

      if (jump) {
        _scrollController.jumpTo(clampedOffset);
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final stripDates = buildCalendarStripDates(
      _anchorDate,
      daysBefore: _daysBefore,
      daysAfter: _daysAfter,
    );
    final markersAsync = ref.watch(
      calendarMarkersProvider(
        CalendarMarkersRef(
          dateFrom: stripDates.first,
          dateTo: stripDates.last,
        ),
      ),
    );
    final markersByDate = markersAsync.asData?.value.markersByDate ??
        const <String, CalendarDateMarker>{};
    final dayLabelFormat = DateFormat('EE', 'ru');
    final isTodayDate = normalizeCalendarDate(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewportWidth != constraints.maxWidth) {
          _viewportWidth = constraints.maxWidth;
          _scheduleCenterSelected(jump: true);
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
              final isSelected = _isSameDate(date, widget.selectedDate);
              final isToday = _isSameDate(date, isTodayDate);
              final marker = markersByDate[formatCalendarApiDate(date)];

              return InkWell(
                onTap: () => widget.onSelectDate(date),
                borderRadius: BorderRadius.circular(PawlyRadius.xl),
                child: Ink(
                  width: _itemWidth,
                  decoration: BoxDecoration(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.surface,
                    borderRadius: BorderRadius.circular(PawlyRadius.xl),
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : isToday
                              ? colorScheme.primary.withValues(alpha: 0.54)
                              : colorScheme.outlineVariant
                                  .withValues(alpha: 0.72),
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
                          _capitalize(dayLabelFormat.format(date)),
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
                          child: marker == null || !marker.hasEvents
                              ? null
                              : _CalendarMarkerDot(
                                  marker: marker,
                                  isSelected: isSelected,
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _CalendarMarkerDot extends StatelessWidget {
  const _CalendarMarkerDot({
    required this.marker,
    required this.isSelected,
  });

  final CalendarDateMarker marker;
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

class _CalendarDayContent extends StatelessWidget {
  const _CalendarDayContent({
    required this.response,
    required this.selectedDate,
    required this.petNamesById,
    required this.onOpenOccurrence,
  });

  final ScheduledDayResponse response;
  final DateTime selectedDate;
  final Map<String, String> petNamesById;
  final Future<void> Function(ScheduledItemOccurrence occurrence)
      onOpenOccurrence;

  @override
  Widget build(BuildContext context) {
    if (response.items.isEmpty) {
      return _CalendarNoEventsView(selectedDate: selectedDate);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _CalendarSectionHeader(title: 'События', count: response.items.length),
        const SizedBox(height: PawlySpacing.sm),
        ...response.items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: PawlySpacing.md),
            child: _CalendarEventCard(
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

class _CalendarSectionHeader extends StatelessWidget {
  const _CalendarSectionHeader({required this.title, required this.count});

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
          _eventsCountLabel(count),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.item, this.petName, this.onTap});

  final ScheduledItemOccurrence item;
  final String? petName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rule = item.rule;
    final timeLabel = _timeLabel(item.scheduledFor);
    final metaParts = <String>[
      if (petName != null && petName!.isNotEmpty) petName!,
      _itemTypeLabel(rule.sourceType),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      timeLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
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
                            rule.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: PawlySpacing.sm),
                        Icon(
                          _itemIcon(rule.sourceType),
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
                    if (rule.note != null && rule.note!.isNotEmpty) ...[
                      const SizedBox(height: PawlySpacing.sm),
                      Text(
                        rule.note!,
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

  IconData _itemIcon(String type) {
    switch (type) {
      case 'VET_VISIT':
        return Icons.local_hospital_rounded;
      case 'VACCINATION':
        return Icons.vaccines_rounded;
      case 'PROCEDURE':
        return Icons.medical_services_rounded;
      case 'LOG_TYPE':
        return Icons.list_alt_rounded;
      case 'MANUAL':
        return Icons.notifications_none_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  String _itemTypeLabel(String type) {
    switch (type) {
      case 'VET_VISIT':
        return 'Визит';
      case 'VACCINATION':
        return 'Вакцинация';
      case 'PROCEDURE':
        return 'Процедура';
      case 'LOG_TYPE':
        return 'Запись';
      case 'MANUAL':
        return 'Напоминание';
      default:
        return type;
    }
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return 'Весь день';
    }
    return DateFormat('HH:mm').format(value.toLocal());
  }
}

class _CalendarNoEventsView extends StatelessWidget {
  const _CalendarNoEventsView({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final formatted = DateFormat('d MMMM', 'ru').format(selectedDate);

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

class _CalendarLoadingView extends StatelessWidget {
  const _CalendarLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: PawlySpacing.xxl),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _CalendarErrorView extends StatelessWidget {
  const _CalendarErrorView({required this.onRetry});

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

bool _isSameDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

String _capitalize(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}

String _eventsCountLabel(int count) {
  final lastTwo = count % 100;
  final last = count % 10;

  if (lastTwo >= 11 && lastTwo <= 14) {
    return '$count событий';
  }
  if (last == 1) {
    return '$count событие';
  }
  if (last >= 2 && last <= 4) {
    return '$count события';
  }
  return '$count событий';
}
