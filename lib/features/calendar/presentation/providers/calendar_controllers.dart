import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/models/health_models.dart';
import '../../../pet_care/presentation/providers/health_controllers.dart';

final calendarSelectedDateProvider =
    NotifierProvider.autoDispose<CalendarSelectedDateController, DateTime>(
  CalendarSelectedDateController.new,
);

final calendarDayProvider = FutureProvider.autoDispose
    .family<ScheduledDayResponse, CalendarDayRef>((ref, args) {
  return ref.read(healthRepositoryProvider).getScheduleDay(
        date: _formatApiDate(args.date),
      );
});

final calendarMarkersProvider = FutureProvider.autoDispose
    .family<CalendarRangeResponse, CalendarMarkersRef>((ref, args) {
  return ref.read(healthRepositoryProvider).getHealthCalendar(
        dateFrom: _formatApiDate(args.dateFrom),
        dateTo: _formatApiDate(args.dateTo),
      );
});

class CalendarDayRef {
  const CalendarDayRef({
    required this.date,
  });

  final DateTime date;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CalendarDayRef && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}

class CalendarMarkersRef {
  const CalendarMarkersRef({
    required this.dateFrom,
    required this.dateTo,
  });

  final DateTime dateFrom;
  final DateTime dateTo;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CalendarMarkersRef &&
            other.dateFrom == dateFrom &&
            other.dateTo == dateTo;
  }

  @override
  int get hashCode => Object.hash(dateFrom, dateTo);
}

class CalendarSelectedDateController extends Notifier<DateTime> {
  @override
  DateTime build() => _normalizeDate(DateTime.now());

  void setDate(DateTime value) {
    state = _normalizeDate(value);
  }

  void jumpToToday() {
    state = _normalizeDate(DateTime.now());
  }
}

DateTime normalizeCalendarDate(DateTime value) => _normalizeDate(value);

List<DateTime> buildWeekStripDates(DateTime selectedDate) {
  final normalized = _normalizeDate(selectedDate);
  final start = normalized.subtract(Duration(days: normalized.weekday - 1));

  return List<DateTime>.generate(
    7,
    (index) => start.add(Duration(days: index)),
    growable: false,
  );
}

List<DateTime> buildCalendarStripDates(
  DateTime selectedDate, {
  int daysBefore = 15,
  int daysAfter = 15,
}) {
  final normalized = _normalizeDate(selectedDate);
  final start = normalized.subtract(Duration(days: daysBefore));
  final total = daysBefore + daysAfter + 1;

  return List<DateTime>.generate(
    total,
    (index) => start.add(Duration(days: index)),
    growable: false,
  );
}

String formatCalendarApiDate(DateTime value) => _formatApiDate(value);

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

String _formatApiDate(DateTime value) {
  return DateFormat('yyyy-MM-dd').format(_normalizeDate(value));
}
