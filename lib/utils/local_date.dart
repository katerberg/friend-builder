import 'dart:io';

import 'package:device_calendar/device_calendar.dart';

/// Calendar-day difference from [from] to [to] (local dates).
///
/// Uses UTC midnights built from local Y/M/D so DST transitions do not
/// change the day count the way [Duration.inDays] can.
int calendarDaysBetween(DateTime from, DateTime to) {
  final fromLocal = from.isUtc ? from.toLocal() : from;
  final toLocal = to.isUtc ? to.toLocal() : to;
  final fromDay =
      DateTime.utc(fromLocal.year, fromLocal.month, fromLocal.day);
  final toDay = DateTime.utc(toLocal.year, toLocal.month, toLocal.day);
  return toDay.difference(fromDay).inDays;
}

/// Whether [a] and [b] fall on the same local calendar day.
bool isSameHangoutDate(DateTime a, DateTime b) =>
    calendarDaysBetween(a, b) == 0;

/// Calendar day of [date] with the clock time of [timeOfDay].
DateTime combineHangoutDateAndTime(DateTime date, DateTime timeOfDay) {
  final localDate = date.isUtc ? date.toLocal() : date;
  final localTime = timeOfDay.isUtc ? timeOfDay.toLocal() : timeOfDay;
  return DateTime(
    localDate.year,
    localDate.month,
    localDate.day,
    localTime.hour,
    localTime.minute,
    localTime.second,
    localTime.millisecond,
    localTime.microsecond,
  );
}

/// Calendar event start → hangout instant (local).
///
/// All-day iOS (EventKit) uses UTC date components; converting to local first
/// shifts the day. All-day Android uses the date components as provided.
/// Timed events keep the local wall-clock instant.
///
/// [isIos] overrides [Platform.isIOS] for tests.
DateTime hangoutWhenFromCalendarEvent(Event event, {bool? isIos}) {
  final start = event.start;
  if (start == null) {
    return DateTime.now();
  }

  if (event.allDay == true) {
    if (isIos ?? Platform.isIOS) {
      final utc = start.toUtc();
      return DateTime(utc.year, utc.month, utc.day);
    }
    return DateTime(start.year, start.month, start.day);
  }

  return start.toLocal();
}
