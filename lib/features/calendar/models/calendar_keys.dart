class CalendarDayKey {
  const CalendarDayKey({
    required this.date,
  });

  final DateTime date;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CalendarDayKey && other.date == date;
  }

  @override
  int get hashCode => date.hashCode;
}

class CalendarMarkersKey {
  const CalendarMarkersKey({
    required this.dateFrom,
    required this.dateTo,
  });

  final DateTime dateFrom;
  final DateTime dateTo;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is CalendarMarkersKey &&
            other.dateFrom == dateFrom &&
            other.dateTo == dateTo;
  }

  @override
  int get hashCode => Object.hash(dateFrom, dateTo);
}
