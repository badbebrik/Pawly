import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../health/controllers/health_dependencies.dart';
import '../data/calendar_repository.dart';
import '../models/calendar_day.dart';
import '../models/calendar_keys.dart';
import '../shared/formatters/calendar_date_formatters.dart';
import '../states/calendar_state.dart';

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  final healthRepository = ref.watch(healthScheduleRepositoryProvider);
  return CalendarRepository(healthRepository: healthRepository);
});

final calendarControllerProvider =
    NotifierProvider.autoDispose<CalendarController, CalendarState>(
  CalendarController.new,
);

final calendarDayProvider =
    FutureProvider.autoDispose.family<CalendarDay, CalendarDayKey>((ref, args) {
  return ref.read(calendarRepositoryProvider).getDay(args.date);
});

final calendarMarkersProvider = FutureProvider.autoDispose
    .family<Map<String, CalendarMarker>, CalendarMarkersKey>((ref, args) {
  return ref.read(calendarRepositoryProvider).getMarkers(
        dateFrom: args.dateFrom,
        dateTo: args.dateTo,
      );
});

class CalendarController extends Notifier<CalendarState> {
  @override
  CalendarState build() => CalendarState.initial();

  void setDate(DateTime value) {
    state = state.copyWith(selectedDate: normalizeCalendarDate(value));
  }

  void jumpToToday() {
    state = state.copyWith(selectedDate: normalizeCalendarDate(DateTime.now()));
  }
}
