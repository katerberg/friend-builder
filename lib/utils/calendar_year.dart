class CalendarYearBounds {
  final DateTime start;
  final DateTime end;
  final int year;

  const CalendarYearBounds({
    required this.start,
    required this.end,
    required this.year,
  });
}

CalendarYearBounds calendarYearBounds([DateTime? referenceDate]) {
  final reference = referenceDate ?? DateTime.now();
  final year = reference.year;
  return CalendarYearBounds(
    year: year,
    start: DateTime(year, 1, 1),
    end: DateTime(year + 1, 1, 1),
  );
}

String formatHangoutCountSubtitle(int year, int hangoutCount) {
  final label = hangoutCount == 1 ? 'hangout' : 'hangouts';
  return '$year · $hangoutCount $label';
}
