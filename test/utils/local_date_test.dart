import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/utils/local_date.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  group('normalizeToHangoutDate', () {
    test('normalizes local evening to local noon on the same day', () {
      final evening = DateTime(2024, 8, 22, 23, 47);
      final normalized = normalizeToHangoutDate(evening);

      expect(normalized.year, 2024);
      expect(normalized.month, 8);
      expect(normalized.day, 22);
      expect(normalized.hour, 12);
      expect(normalized.isUtc, isFalse);
    });

    test('normalizes local midnight to local noon on the same day', () {
      final midnight = DateTime(2024, 8, 22);
      final normalized = normalizeToHangoutDate(midnight);

      expect(normalized, DateTime(2024, 8, 22, 12));
    });

    test('converts UTC midnight to local calendar day before normalizing', () {
      final utcMidnight = DateTime.utc(2024, 8, 22);
      final normalized = normalizeToHangoutDate(utcMidnight);
      final expectedLocalDay = utcMidnight.toLocal();

      expect(normalized.year, expectedLocalDay.year);
      expect(normalized.month, expectedLocalDay.month);
      expect(normalized.day, expectedLocalDay.day);
      expect(normalized.hour, 12);
    });
  });

  group('calendarDaysBetween', () {
    test('counts one calendar day across a late-evening boundary', () {
      final yesterdayEvening = DateTime(2024, 8, 21, 23, 30);
      final todayLate = DateTime(2024, 8, 22, 23, 0);

      expect(calendarDaysBetween(yesterdayEvening, todayLate), 1);
    });

    test('returns zero for two times on the same local day', () {
      final morning = DateTime(2024, 8, 22, 1);
      final evening = DateTime(2024, 8, 22, 23);

      expect(calendarDaysBetween(morning, evening), 0);
      expect(isSameHangoutDate(morning, evening), isTrue);
    });
  });

  group('hangoutDateFromCalendarEvent', () {
    setUpAll(() {
      tz.initializeTimeZones();
    });

    test('iOS all-day UTC midnight keeps the UTC calendar day', () {
      final utcLocation = tz.getLocation('UTC');
      final event = Event(
        'calendar',
        start: tz.TZDateTime(utcLocation, 2024, 8, 22),
        allDay: true,
      );

      final hangoutDate = hangoutDateFromCalendarEvent(event, isIos: true);

      expect(hangoutDate, DateTime(2024, 8, 22, 12));
    });

    test('Android all-day uses provided date components', () {
      final losAngeles = tz.getLocation('America/Los_Angeles');
      final event = Event(
        'calendar',
        start: tz.TZDateTime(losAngeles, 2024, 8, 22),
        allDay: true,
      );

      final hangoutDate = hangoutDateFromCalendarEvent(event, isIos: false);

      expect(hangoutDate, DateTime(2024, 8, 22, 12));
    });

    test('timed event uses local wall-clock date', () {
      final utcLocation = tz.getLocation('UTC');
      final event = Event(
        'calendar',
        start: tz.TZDateTime(utcLocation, 2024, 8, 22, 18),
        allDay: false,
      );

      final hangoutDate = hangoutDateFromCalendarEvent(event);
      final expected = normalizeToHangoutDate(
        tz.TZDateTime(utcLocation, 2024, 8, 22, 18).toLocal(),
      );

      expect(hangoutDate, expected);
    });
  });
}
