import 'package:intl/intl.dart';

DateTime normalizeCalendarDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool isSameCalendarDate(DateTime left, DateTime right) {
  return left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}

List<DateTime> buildCalendarStripDates(
  DateTime selectedDate, {
  int daysBefore = 15,
  int daysAfter = 15,
}) {
  final normalized = normalizeCalendarDate(selectedDate);
  final start = normalized.subtract(Duration(days: daysBefore));
  final total = daysBefore + daysAfter + 1;

  return List<DateTime>.generate(
    total,
    (index) => start.add(Duration(days: index)),
    growable: false,
  );
}

String formatCalendarApiDate(DateTime value) {
  return DateFormat('yyyy-MM-dd').format(normalizeCalendarDate(value));
}

String calendarDayTitle(DateTime value) {
  return capitalizeCalendarText(DateFormat('d MMMM, EEEE', 'ru').format(value));
}

String calendarMonthTitle(DateTime value) {
  return capitalizeCalendarText(DateFormat('LLLL yyyy', 'ru').format(value));
}

String calendarShortWeekdayLabel(DateTime value) {
  return capitalizeCalendarText(DateFormat('EE', 'ru').format(value));
}

String calendarEventTimeLabel(DateTime? value) {
  if (value == null) {
    return 'Весь день';
  }
  return DateFormat('HH:mm').format(value.toLocal());
}

String calendarEmptyDayLabel(DateTime value) {
  return DateFormat('d MMMM', 'ru').format(value);
}

String calendarEventsCountLabel(int count) {
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

String capitalizeCalendarText(String value) {
  if (value.isEmpty) {
    return value;
  }
  return value[0].toUpperCase() + value.substring(1);
}
