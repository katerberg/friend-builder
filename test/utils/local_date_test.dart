import 'package:device_calendar/device_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/utils/local_date.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
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

  group('combineHangoutDateAndTime', () {
    test('keeps the clock time when the calendar day changes', () {
      final existing = DateTime(2024, 8, 22, 15, 42, 7);
      final pickedDay = DateTime(2024, 8, 20);

      expect(
        combineHangoutDateAndTime(pickedDay, existing),
        DateTime(2024, 8, 20, 15, 42, 7),
      );
    });
  });

  group('hangoutWhenFromCalendarEvent', () {
    setUpAll(() {
      tzdata.initializeTimeZones();
    });

    test('iOS all-day UTC midnight keeps the UTC calendar day at local midnight',
        () {
      final utcLocation = tz.getLocation('UTC');
      final event = Event(
        'calendar',
        start: tz.TZDateTime(utcLocation, 2024, 8, 22),
        allDay: true,
      );

      final hangoutWhen =
          hangoutWhenFromCalendarEvent(event, isIos: true);

      expect(hangoutWhen, DateTime(2024, 8, 22));
    });

    test('Android all-day uses provided date components at local midnight', () {
      final losAngeles = tz.getLocation('America/Los_Angeles');
      final event = Event(
        'calendar',
        start: tz.TZDateTime(losAngeles, 2024, 8, 22),
        allDay: true,
      );

      final hangoutWhen =
          hangoutWhenFromCalendarEvent(event, isIos: false);

      expect(hangoutWhen, DateTime(2024, 8, 22));
    });

    test('timed event keeps local wall-clock time', () {
      final utcLocation = tz.getLocation('UTC');
      final event = Event(
        'calendar',
        start: tz.TZDateTime(utcLocation, 2024, 8, 22, 18, 30),
        allDay: false,
      );

      final hangoutWhen = hangoutWhenFromCalendarEvent(event);
      final expected =
          tz.TZDateTime(utcLocation, 2024, 8, 22, 18, 30).toLocal();

      expect(hangoutWhen, expected);
    });
  });
}
