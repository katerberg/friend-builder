import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/utils/calendar_year.dart';

void main() {
  group('calendarYearBounds', () {
    test('returns Jan 1 through Jan 1 next year for reference date', () {
      final bounds = calendarYearBounds(DateTime(2026, 6, 15));

      expect(bounds.year, 2026);
      expect(bounds.start, DateTime(2026, 1, 1));
      expect(bounds.end, DateTime(2027, 1, 1));
    });

    test('uses current year when reference date is omitted', () {
      final bounds = calendarYearBounds();

      expect(bounds.year, DateTime.now().year);
      expect(bounds.start, DateTime(bounds.year, 1, 1));
      expect(bounds.end, DateTime(bounds.year + 1, 1, 1));
    });
  });

  group('formatHangoutCountSubtitle', () {
    test('uses singular hangout label for count of 1', () {
      expect(formatHangoutCountSubtitle(2026, 1), '2026 · 1 hangout');
    });

    test('uses plural hangouts label for other counts', () {
      expect(formatHangoutCountSubtitle(2026, 0), '2026 · 0 hangouts');
      expect(formatHangoutCountSubtitle(2026, 47), '2026 · 47 hangouts');
    });
  });
}
