import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/utils/contact_sorting.dart';

void main() {
  group('sortContactsForDisplay', () {
    group('separates contacts by isContactable', () {
      test('puts contactable contacts in hangoutContactIds', () {
        final contacts = [
          SortableContact(
            id: '1',
            displayName: 'Alice',
            frequencyValue: 7,
            lastHangoutDate: DateTime.now().subtract(const Duration(days: 3)),
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, ['1']);
        expect(result.unusedContactIds, isEmpty);
      });

      test('puts non-contactable contacts in unusedContactIds', () {
        final contacts = [
          SortableContact(
            id: '1',
            displayName: 'Alice',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, isEmpty);
        expect(result.unusedContactIds, ['1']);
      });

      test('correctly separates mixed list', () {
        final contacts = [
          SortableContact(
            id: '1',
            displayName: 'Alice',
            frequencyValue: 7,
            lastHangoutDate: DateTime.now(),
            isContactable: true,
          ),
          SortableContact(
            id: '2',
            displayName: 'Bob',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
          SortableContact(
            id: '3',
            displayName: 'Charlie',
            frequencyValue: 7,
            lastHangoutDate: DateTime.now(),
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, containsAll(['1', '3']));
        expect(result.unusedContactIds, ['2']);
      });
    });

    group('sorts unused contacts alphabetically', () {
      test('sorts by displayName ascending', () {
        final contacts = [
          SortableContact(
            id: 'z',
            displayName: 'Zara',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
          SortableContact(
            id: 'a',
            displayName: 'Alice',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
          SortableContact(
            id: 'm',
            displayName: 'Mike',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.unusedContactIds, ['a', 'm', 'z']);
      });
    });

    group('sorts hangout contacts by days left', () {
      test('most overdue contacts appear first (negative days left)', () {
        final now = DateTime.now();
        final contacts = [
          SortableContact(
            id: 'recent',
            displayName: 'Recent',
            frequencyValue: 7,
            lastHangoutDate: now.subtract(const Duration(days: 1)),
            isContactable: true,
          ),
          SortableContact(
            id: 'overdue',
            displayName: 'Overdue',
            frequencyValue: 7,
            lastHangoutDate: now.subtract(const Duration(days: 14)),
            isContactable: true,
          ),
          SortableContact(
            id: 'veryOverdue',
            displayName: 'Very Overdue',
            frequencyValue: 7,
            lastHangoutDate: now.subtract(const Duration(days: 30)),
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, ['veryOverdue', 'overdue', 'recent']);
      });

      test('contacts with no hangout date sort last (far future placeholder)',
          () {
        final now = DateTime.now();
        final contacts = [
          SortableContact(
            id: 'recent',
            displayName: 'Recent',
            frequencyValue: 7,
            lastHangoutDate: now.subtract(const Duration(days: 1)),
            isContactable: true,
          ),
          SortableContact(
            id: 'never',
            displayName: 'Never Seen',
            frequencyValue: 7,
            lastHangoutDate: null,
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds.last, 'never');
      });

      test('respects different frequency values', () {
        final now = DateTime.now();
        final contacts = [
          SortableContact(
            id: 'weekly',
            displayName: 'Weekly Friend',
            frequencyValue: 7,
            lastHangoutDate: now.subtract(const Duration(days: 10)),
            isContactable: true,
          ),
          SortableContact(
            id: 'monthly',
            displayName: 'Monthly Friend',
            frequencyValue: 31,
            lastHangoutDate: now.subtract(const Duration(days: 10)),
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, ['weekly', 'monthly']);
      });

      test('uses weekly (7 days) as default when frequencyValue is null', () {
        final now = DateTime.now();
        final contacts = [
          SortableContact(
            id: 'withFreq',
            displayName: 'With Frequency',
            frequencyValue: 7,
            lastHangoutDate: now.subtract(const Duration(days: 5)),
            isContactable: true,
          ),
          SortableContact(
            id: 'noFreq',
            displayName: 'No Frequency',
            frequencyValue: null,
            lastHangoutDate: now.subtract(const Duration(days: 5)),
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds.length, 2);
      });
    });

    group('tiebreaker by name when days left are equal', () {
      test('sorts alphabetically when days left are the same', () {
        final now = DateTime.now();
        final sameDate = now.subtract(const Duration(days: 3));
        final contacts = [
          SortableContact(
            id: 'z',
            displayName: 'Zara',
            frequencyValue: 7,
            lastHangoutDate: sameDate,
            isContactable: true,
          ),
          SortableContact(
            id: 'a',
            displayName: 'Alice',
            frequencyValue: 7,
            lastHangoutDate: sameDate,
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, ['a', 'z']);
      });
    });

    group('edge cases', () {
      test('handles empty list', () {
        final result = sortContactsForDisplay([]);

        expect(result.hangoutContactIds, isEmpty);
        expect(result.unusedContactIds, isEmpty);
      });

      test('handles all contactable', () {
        final contacts = [
          SortableContact(
            id: '1',
            displayName: 'A',
            frequencyValue: 7,
            lastHangoutDate: DateTime.now(),
            isContactable: true,
          ),
          SortableContact(
            id: '2',
            displayName: 'B',
            frequencyValue: 7,
            lastHangoutDate: DateTime.now(),
            isContactable: true,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds.length, 2);
        expect(result.unusedContactIds, isEmpty);
      });

      test('handles all non-contactable', () {
        final contacts = [
          SortableContact(
            id: '1',
            displayName: 'A',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
          SortableContact(
            id: '2',
            displayName: 'B',
            frequencyValue: null,
            lastHangoutDate: null,
            isContactable: false,
          ),
        ];

        final result = sortContactsForDisplay(contacts);

        expect(result.hangoutContactIds, isEmpty);
        expect(result.unusedContactIds.length, 2);
      });
    });
  });
}
