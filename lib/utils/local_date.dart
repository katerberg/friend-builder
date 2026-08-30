import 'dart:io';

import 'package:device_calendar/device_calendar.dart';

/// Local noon for the calendar day of [dateTime] (in local time).
///
/// Hangout dates are calendar days, not instants. Local noon is a stable
/// canonical instant for a day that avoids most DST edge cases.
DateTime normalizeToHangoutDate(DateTime dateTime) {
  final local = dateTime.isUtc ? dateTime.toLocal() : dateTime;
  return DateTime(local.year, local.month, local.day, 12);
}

/// Today as a hangout date (local noon).
DateTime hangoutDateToday() => normalizeToHangoutDate(DateTime.now());

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

/// Calendar event start → hangout date.
///
/// All-day iOS (EventKit) uses UTC date components; converting to local first
/// shifts the day. All-day Android uses the date components as provided.
/// Timed events use local wall-clock date.
///
/// [isIos] overrides [Platform.isIOS] for tests.
DateTime hangoutDateFromCalendarEvent(Event event, {bool? isIos}) {
  final start = event.start;
  if (start == null) {
    return hangoutDateToday();
  }

  if (event.allDay == true) {
    if (isIos ?? Platform.isIOS) {
      final utc = start.toUtc();
      return DateTime(utc.year, utc.month, utc.day, 12);
    }
    return DateTime(start.year, start.month, start.day, 12);
  }

  return normalizeToHangoutDate(start.toLocal());
}
