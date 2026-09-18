import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/services/top_due_friend.dart';

Contact _contact({
  required String id,
  required String displayName,
}) {
  return Contact(
    id: id,
    displayName: displayName,
  );
}

Friend _friend({
  required String contactIdentifier,
  required int frequencyDays,
}) {
  return Friend(
    contactIdentifier: contactIdentifier,
    notes: '',
    frequency: Frequency.fromValue(frequencyDays),
    isContactable: true,
  );
}

Hangout _hangout({
  required String contactIdentifier,
  required DateTime when,
}) {
  return Hangout(
    contacts: [
      EncodableContact(
        displayName: contactIdentifier,
        middleName: '',
        givenName: '',
        identifier: contactIdentifier,
        familyName: '',
      ),
    ],
    notes: '',
    when: when,
  );
}

void main() {
  group('resolveTopDueFriend', () {
    test('returns contacts_permission when permission is missing', () {
      final result = resolveTopDueFriend(
        missingContactsPermission: true,
        contacts: [],
        friends: [],
        hangouts: [],
      );

      expect(result.toSnapshotPayload(), {
        'found': false,
        'reason': 'contacts_permission',
      });
    });

    test('returns found false when no contactable friends exist', () {
      final result = resolveTopDueFriend(
        missingContactsPermission: false,
        contacts: [_contact(id: 'a', displayName: 'Alice')],
        friends: [
          Friend(
            contactIdentifier: 'a',
            notes: '',
            frequency: Frequency.fromType('Weekly'),
            isContactable: false,
          ),
        ],
        hangouts: [],
      );

      expect(result.toSnapshotPayload(), {'found': false});
    });

    test('selects the most overdue contactable friend', () {
      final now = DateTime.now();
      final result = resolveTopDueFriend(
        missingContactsPermission: false,
        contacts: [
          _contact(id: 'alice', displayName: 'Alice'),
          _contact(id: 'bob', displayName: 'Bob'),
        ],
        friends: [
          _friend(contactIdentifier: 'alice', frequencyDays: 7),
          _friend(contactIdentifier: 'bob', frequencyDays: 7),
        ],
        hangouts: [
          _hangout(
            contactIdentifier: 'alice',
            when: now.subtract(const Duration(days: 3)),
          ),
          _hangout(
            contactIdentifier: 'bob',
            when: now.subtract(const Duration(days: 20)),
          ),
        ],
      );

      final payload = result.toSnapshotPayload();
      expect(payload['found'], true);
      expect(payload['contactIdentifier'], 'bob');
      expect(payload['displayName'], 'Bob');
      expect(payload['urgency'], '13 days late');
    });
  });
}
