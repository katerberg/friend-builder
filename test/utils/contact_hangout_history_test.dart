import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/utils/contact_hangout_history.dart';

Hangout _hangoutAt(DateTime when, {List<EncodableContact>? contacts}) {
  return Hangout(
    contacts: contacts ?? [],
    notes: '',
    when: when,
  );
}

EncodableContact _contact(String identifier, String displayName) {
  return EncodableContact(
    displayName: displayName,
    middleName: '',
    givenName: displayName,
    identifier: identifier,
    familyName: '',
  );
}

void main() {
  group('hangoutsOpenableInHistory', () {
    final now = DateTime(2026, 9, 11, 12);

    test('keeps hangouts on or after the 365-day cutoff', () {
      final cutoff = now.subtract(historyOpenableWindow);
      final recent = _hangoutAt(now.subtract(const Duration(days: 10)));
      final onCutoff = _hangoutAt(cutoff);
      final older = _hangoutAt(cutoff.subtract(const Duration(days: 1)));

      final result = hangoutsOpenableInHistory(
        [older, onCutoff, recent],
        now: now,
      );

      expect(result, [recent, onCutoff]);
    });

    test('sorts newest first', () {
      final older = _hangoutAt(now.subtract(const Duration(days: 40)));
      final newer = _hangoutAt(now.subtract(const Duration(days: 2)));
      final middle = _hangoutAt(now.subtract(const Duration(days: 15)));

      final result = hangoutsOpenableInHistory(
        [older, newer, middle],
        now: now,
      );

      expect(result.map((hangout) => hangout.id).toList(),
          [newer.id, middle.id, older.id]);
    });

    test('includes group hangouts in the openable window', () {
      final groupHangout = _hangoutAt(
        now.subtract(const Duration(days: 5)),
        contacts: [
          _contact('a', 'Alex'),
          _contact('b', 'Blake'),
        ],
      );
      final tooOld = _hangoutAt(
        now.subtract(const Duration(days: 400)),
        contacts: [
          _contact('a', 'Alex'),
          _contact('c', 'Casey'),
        ],
      );

      final result = hangoutsOpenableInHistory(
        [tooOld, groupHangout],
        now: now,
      );

      expect(result, [groupHangout]);
      expect(result.first.contacts.length, 2);
    });

    test('returns an empty list when nothing is in the window', () {
      final tooOld = _hangoutAt(now.subtract(const Duration(days: 400)));

      expect(hangoutsOpenableInHistory([tooOld], now: now), isEmpty);
    });
  });
}
