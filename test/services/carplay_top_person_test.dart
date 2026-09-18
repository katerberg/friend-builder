import 'dart:typed_data';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/services/carplay_top_person.dart';

Contact _contact({
  required String id,
  required String displayName,
  List<Phone>? phones,
}) {
  return Contact(
    id: id,
    displayName: displayName,
    phones: phones ?? [],
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
  group('resolveCarPlayTopPerson', () {
    test('returns contacts_permission when permission is missing', () async {
      final result = await resolveCarPlayTopPerson(
        missingContactsPermission: true,
        contacts: [],
        friends: [],
        hangouts: [],
        loadPhoto: (_) async => null,
      );

      expect(result.toChannelPayload(), {
        'found': false,
        'reason': 'contacts_permission',
      });
    });

    test('returns found false when no contactable friends exist', () async {
      final result = await resolveCarPlayTopPerson(
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
        loadPhoto: (_) async => null,
      );

      expect(result.toChannelPayload(), {'found': false});
    });

    test('selects the most overdue contactable friend', () async {
      final now = DateTime.now();
      final result = await resolveCarPlayTopPerson(
        missingContactsPermission: false,
        contacts: [
          _contact(
            id: 'alice',
            displayName: 'Alice',
            phones: [Phone('555-111-1111')],
          ),
          _contact(
            id: 'bob',
            displayName: 'Bob',
            phones: [Phone('(555) 222-3333'), Phone('+1 555 444 5555')],
          ),
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
        loadPhoto: (contactIdentifier) async {
          if (contactIdentifier == 'bob') {
            return Uint8List.fromList([1, 2, 3]);
          }
          return null;
        },
      );

      final payload = result.toChannelPayload();
      expect(payload['found'], true);
      expect(payload['contactIdentifier'], 'bob');
      expect(payload['displayName'], 'Bob');
      expect(payload['urgency'], '13 days late');
      expect(payload['hasPhone'], true);
      expect(payload['photoBase64'], isNotNull);
      expect(payload['phones'], [
        {'label': 'mobile', 'number': '5552223333'},
        {'label': 'mobile', 'number': '+15554445555'},
      ]);
    });
  });
}
