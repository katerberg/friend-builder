import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/calendar_year_stats.dart';

void main() {
  group('monthIndexFromSqliteMonth', () {
    test('maps sqlite month string to zero-based index', () {
      expect(monthIndexFromSqliteMonth('01'), 0);
      expect(monthIndexFromSqliteMonth('12'), 11);
    });
  });

  group('buildMonthlyCountsFromQueryRows', () {
    test('fills monthly buckets from query rows', () {
      final counts = buildMonthlyCountsFromQueryRows([
        {'month': '01', 'hangoutCount': 3},
        {'month': '06', 'hangoutCount': 5},
      ]);

      expect(counts[0], 3);
      expect(counts[5], 5);
      expect(counts[1], 0);
    });
  });

  group('sqliteWeekdayToMondayFirstIndex', () {
    test('maps sqlite Sunday to index 6', () {
      expect(sqliteWeekdayToMondayFirstIndex(0), 6);
    });

    test('maps sqlite Monday to index 0', () {
      expect(sqliteWeekdayToMondayFirstIndex(1), 0);
    });

    test('maps sqlite Saturday to index 5', () {
      expect(sqliteWeekdayToMondayFirstIndex(6), 5);
    });
  });

  group('buildWeekdayCountsFromQueryRows', () {
    test('fills weekday buckets from query rows', () {
      final counts = buildWeekdayCountsFromQueryRows([
        {'weekday': '0', 'hangoutCount': 2},
        {'weekday': '1', 'hangoutCount': 4},
      ]);

      expect(counts[6], 2);
      expect(counts[0], 4);
      expect(counts[1], 0);
    });
  });

  group('GroupSoloCounts', () {
    test('total sums solo and group counts', () {
      const counts = GroupSoloCounts(soloCount: 3, groupCount: 7);
      expect(counts.total, 10);
      expect(counts.isEmpty, isFalse);
    });

    test('isEmpty when both counts are zero', () {
      const counts = GroupSoloCounts(soloCount: 0, groupCount: 0);
      expect(counts.isEmpty, isTrue);
    });
  });

  group('countsAreAllZero', () {
    test('returns true when every count is zero', () {
      expect(countsAreAllZero([0, 0, 0]), isTrue);
    });

    test('returns false when any count is non-zero', () {
      expect(countsAreAllZero([0, 2, 0]), isFalse);
    });
  });
}
