import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/models/health_models.dart';
import '../../../../design_system/design_system.dart';
import '../../../chat/presentation/widgets/chat_app_bar_action.dart';
import '../../../pets/presentation/providers/active_pet_controller.dart';
import '../providers/calendar_controllers.dart';

class CalendarPage extends ConsumerStatefulWidget {
  const CalendarPage({super.key});

  @override
  ConsumerState<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends ConsumerState<CalendarPage> {
  @override
  Widget build(BuildContext context) {
    final activePetAsync = ref.watch(activePetControllerProvider);
    final selectedDate = ref.watch(calendarSelectedDateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Календарь'),
        actions: const <Widget>[
          ChatAppBarAction(),
        ],
      ),
      body: activePetAsync.when(
        data: (petId) {
          if (petId == null || petId.isEmpty) {
            return _CalendarEmptyPetView(
              onOpenPets: () => context.go(AppRoutes.pets),
            );
          }

          final dayAsync = ref.watch(
            calendarDayProvider(
                CalendarDayRef(petId: petId, date: selectedDate)),
          );

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                calendarDayProvider(
                    CalendarDayRef(petId: petId, date: selectedDate)),
              );
              await ref.read(
                calendarDayProvider(
                        CalendarDayRef(petId: petId, date: selectedDate))
                    .future,
              );
            },
            child: ListView(
              padding: const EdgeInsets.all(PawlySpacing.lg),
              children: <Widget>[
                _WeekStrip(
                  selectedDate: selectedDate,
                  onSelectDate: _selectDate,
                ),
                const SizedBox(height: PawlySpacing.lg),
                _CalendarDatePickerCard(
                  selectedDate: selectedDate,
                  onPickDate: _pickDate,
                ),
                const SizedBox(height: PawlySpacing.lg),
                dayAsync.when(
                  data: (response) => _CalendarDayContent(
                    response: response,
                    selectedDate: selectedDate,
                  ),
                  loading: () => const _CalendarLoadingView(),
                  error: (error, _) => _CalendarErrorView(
                    onRetry: () {
                      ref.invalidate(
                        calendarDayProvider(
                          CalendarDayRef(petId: petId, date: selectedDate),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _CalendarErrorView(
          onRetry: () =>
              ref.read(activePetControllerProvider.notifier).reload(),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final selectedDate = ref.read(calendarSelectedDateProvider);
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ru'),
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    ref.read(calendarSelectedDateProvider.notifier).setDate(pickedDate);
  }

  void _selectDate(DateTime value) {
    ref.read(calendarSelectedDateProvider.notifier).setDate(value);
  }
}

class _CalendarDatePickerCard extends StatelessWidget {
  const _CalendarDatePickerCard({
    required this.selectedDate,
    required this.onPickDate,
  });

  final DateTime selectedDate;
  final Future<void> Function() onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('d MMMM, EEEE', 'ru');
    final title = _capitalize(formatter.format(selectedDate));

    return PawlyCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: PawlySpacing.md),
          PawlyButton(
            label: 'Выбрать дату',
            onPressed: onPickDate,
            variant: PawlyButtonVariant.secondary,
            icon: Icons.event_rounded,
          ),
        ],
      ),
    );
  }
}

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({
    required this.selectedDate,
    required this.onSelectDate,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final weekDates = buildWeekStripDates(selectedDate);
    final dayLabelFormat = DateFormat('EE', 'ru');
    final isTodayDate = normalizeCalendarDate(DateTime.now());

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: weekDates.length,
        separatorBuilder: (_, __) => const SizedBox(width: PawlySpacing.sm),
        itemBuilder: (context, index) {
          final date = weekDates[index];
          final isSelected = _isSameDate(date, selectedDate);
          final isToday = _isSameDate(date, isTodayDate);

          return InkWell(
            onTap: () => onSelectDate(date),
            borderRadius: BorderRadius.circular(PawlyRadius.lg),
            child: Ink(
              width: 76,
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
  }
}

class _CalendarDayContent extends StatelessWidget {
  const _CalendarDayContent({
    required this.response,
    required this.selectedDate,
  });

  final HealthDayResponse response;
  final DateTime selectedDate;

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
            child: _CalendarEventCard(item: item),
          ),
        ),
      ],
    );
  }
}

class _CalendarEventCard extends StatelessWidget {
  const _CalendarEventCard({required this.item});

  final HealthDayItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PawlyCard(
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
              _itemIcon(item.itemType),
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: PawlySpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: PawlySpacing.xxs),
                  Text(
                    item.subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
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
                      label: _itemTypeLabel(item.itemType),
                      backgroundColor: colorScheme.surfaceContainerHighest,
                      foregroundColor: colorScheme.onSurfaceVariant,
                    ),
                    _InlineBadge(
                      label: _statusLabel(item.status),
                      backgroundColor:
                          _statusBackground(item.status, colorScheme),
                      foregroundColor:
                          _statusForeground(item.status, colorScheme),
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
      default:
        return type;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PLANNED':
        return 'Запланировано';
      case 'DONE':
        return 'Выполнено';
      case 'COMPLETED':
        return 'Завершено';
      case 'CANCELLED':
        return 'Отменено';
      default:
        return status;
    }
  }

  String _timeLabel(DateTime? value) {
    if (value == null) {
      return 'Без времени';
    }
    return DateFormat('HH:mm').format(value.toLocal());
  }

  Color _statusBackground(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'PLANNED':
        return colorScheme.primaryContainer;
      case 'DONE':
      case 'COMPLETED':
        return Colors.green.withValues(alpha: 0.16);
      case 'CANCELLED':
        return colorScheme.errorContainer;
      default:
        return colorScheme.surfaceContainerHighest;
    }
  }

  Color _statusForeground(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'PLANNED':
        return colorScheme.onPrimaryContainer;
      case 'DONE':
      case 'COMPLETED':
        return Colors.green.shade800;
      case 'CANCELLED':
        return colorScheme.onErrorContainer;
      default:
        return colorScheme.onSurfaceVariant;
    }
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
            'На $formatted событий нет',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: PawlySpacing.xs),
          Text(
            'В этом дне нет запланированных визитов, вакцинаций или процедур.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _CalendarEmptyPetView extends StatelessWidget {
  const _CalendarEmptyPetView({required this.onOpenPets});

  final VoidCallback onOpenPets;

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
                'Сначала выберите питомца',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: PawlySpacing.xs),
              Text(
                'Календарь показывает health-события только для активного питомца.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: PawlySpacing.md),
              PawlyButton(
                label: 'Перейти к питомцам',
                onPressed: onOpenPets,
                icon: Icons.pets_rounded,
              ),
            ],
          ),
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
