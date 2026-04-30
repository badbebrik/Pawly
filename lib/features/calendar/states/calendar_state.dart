import '../shared/formatters/calendar_date_formatters.dart';

class CalendarState {
  const CalendarState({
    required this.selectedDate,
  });

  factory CalendarState.initial() {
    return CalendarState(
      selectedDate: normalizeCalendarDate(DateTime.now()),
    );
  }

  final DateTime selectedDate;

  CalendarState copyWith({
    DateTime? selectedDate,
  }) {
    return CalendarState(
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }
}
