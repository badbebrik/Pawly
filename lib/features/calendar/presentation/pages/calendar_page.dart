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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: const <Widget>[
          ChatAppBarAction(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
              calendarDayProvider(CalendarDayRef(date: selectedDate)));
          ref.invalidate(petsControllerProvider);
          await ref.read(
            calendarDayProvider(CalendarDayRef(date: selectedDate)).future,
          );
        },
        child: ListView(
          padding: const EdgeInsets.all(PawlySpacing.lg),
          children: <Widget>[
            _CalendarDateHeader(
              selectedDate: selectedDate,
              onSelectDate: _selectDate,
              onPickDate: _pickDate,
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

    if (sourceType == 'VET_VISIT' &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      context.pushNamed(
        'petVetVisitDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'visitId': sourceId,
        },
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

    if (sourceType == 'PROCEDURE' &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      context.pushNamed(
        'petProcedureDetails',
        pathParameters: <String, String>{
          'petId': petId,
          'procedureId': sourceId,
        },
      );
      return;
    }

    if (sourceType == 'LOG_TYPE' &&
        sourceId != null &&
        sourceId.isNotEmpty) {
      context.pushNamed(
        'petLogCreate',
        pathParameters: <String, String>{
          'petId': petId,
        },
        queryParameters: <String, String>{
          'logTypeId': sourceId,
        },
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
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;
  final Future<void> Function() onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('d MMMM, EEEE', 'ru');
    final title = _capitalize(formatter.format(selectedDate));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: PawlySpacing.sm),
            IconButton.filledTonal(
              onPressed: onPickDate,
              icon: const Icon(Icons.calendar_month_rounded),
              tooltip: 'Выбрать дату',
            ),
          ],
        ),
        const SizedBox(height: PawlySpacing.md),
        _WeekStrip(
          selectedDate: selectedDate,
          onSelectDate: onSelectDate,
        ),
      ],
    );
  }
}

class _CalendarPickerSheet extends StatelessWidget {
  const _CalendarPickerSheet({
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height * 0.58;

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
                  PawlySpacing.sm,
                  PawlySpacing.xs,
                  PawlySpacing.sm,
                  PawlySpacing.sm,
                ),
                child: Text(
                  'Выбери дату',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Expanded(
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  onDateChanged: (value) {
                    Navigator.of(context).pop(value);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends StatefulWidget {
  const _WeekStrip({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  State<_WeekStrip> createState() => _WeekStripState();
}

class _WeekStripState extends State<_WeekStrip> {
  static const double _itemWidth = 76;
  static const double _itemSpacing = PawlySpacing.sm;
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
    final dayLabelFormat = DateFormat('EE', 'ru');
    final isTodayDate = normalizeCalendarDate(DateTime.now());

    return LayoutBuilder(
      builder: (context, constraints) {
        if (_viewportWidth != constraints.maxWidth) {
          _viewportWidth = constraints.maxWidth;
          _scheduleCenterSelected(jump: true);
        }

        return SizedBox(
          height: 108,
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            itemCount: stripDates.length,
            separatorBuilder: (_, __) => const SizedBox(width: PawlySpacing.sm),
            itemBuilder: (context, index) {
              final date = stripDates[index];
              final isSelected = _isSameDate(date, widget.selectedDate);
              final isToday = _isSameDate(date, isTodayDate);

              return InkWell(
                onTap: () => widget.onSelectDate(date),
                borderRadius: BorderRadius.circular(PawlyRadius.lg),
                child: Ink(
                  width: _itemWidth,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(PawlyRadius.lg),
                    border: Border.all(
                      color: isToday && !isSelected
                          ? colorScheme.primary
                          : Colors.transparent,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: PawlySpacing.sm,
                      vertical: PawlySpacing.md,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          _capitalize(dayLabelFormat.format(date)),
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: PawlySpacing.xs),
                        Text(
                          '${date.day}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: PawlySpacing.xxs),
                        Text(
                          DateFormat('MMM', 'ru').format(date),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: isSelected
                                ? colorScheme.onPrimary.withValues(alpha: 0.9)
                                : colorScheme.onSurfaceVariant,
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
        Text(
          'События дня',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({
    required this.item,
    this.petName,
    this.onTap,
  });

  final ScheduledItemOccurrence item;
  final String? petName;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rule = item.rule;

    return PawlyCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(PawlyRadius.md),
            ),
            child: Icon(
              _itemIcon(rule.sourceType),
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  rule.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rule.note != null && rule.note!.isNotEmpty) ...[
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    rule.note!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (petName != null && petName!.isNotEmpty) ...[
                  const SizedBox(height: PawlySpacing.xs),
                  Text(
                    petName!,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: PawlySpacing.sm),
                Wrap(
                  spacing: PawlySpacing.xs,
                  runSpacing: PawlySpacing.xs,
                  children: <Widget>[
                    _InlineBadge(
                      label: _timeLabel(item.scheduledFor),
                      backgroundColor: colorScheme.secondaryContainer,
                      foregroundColor: colorScheme.onSecondaryContainer,
                    ),
                    _InlineBadge(
                      label: _itemTypeLabel(rule.sourceType),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
        return Icons.monitor_weight_rounded;
      case 'MANUAL':
        return Icons.notifications_active_rounded;
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
        return 'По типу лога';
      case 'MANUAL':
        return 'Напоминание';
      default:
        return type;
    }
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return 'Без времени';
    }
    return DateFormat('HH:mm').format(value.toLocal());
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(PawlyRadius.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PawlySpacing.sm,
          vertical: PawlySpacing.xs,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _CalendarNoEventsView extends StatelessWidget {
  const _CalendarNoEventsView({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('d MMMM', 'ru').format(selectedDate);

    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'На $formatted нет событий',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ],
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(PawlySpacing.lg),
        child: PawlyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Не удалось загрузить календарь',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                'Попробуй повторить запрос ещё раз.',
                style: Theme.of(context).textTheme.bodyMedium,
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
