import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/services/friend_catalog.dart';

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
  required bool isContactable,
}) {
  return Friend(
    contactIdentifier: contactIdentifier,
    notes: '',
    frequency: Frequency.fromValue(7),
    isContactable: isContactable,
  );
}

Hangout _hangout({
  required String contactIdentifier,
  required String displayName,
  required DateTime when,
}) {
  return Hangout(
    contacts: [
      EncodableContact(
        displayName: displayName,
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
  test('buildFriendCatalogEntries prefers live contact names', () {
    final entries = buildFriendCatalogEntries(
      friends: [
        _friend(contactIdentifier: 'a', isContactable: true),
        _friend(contactIdentifier: 'b', isContactable: false),
      ],
      contacts: [
        _contact(id: 'a', displayName: 'Alex'),
        _contact(id: 'b', displayName: 'Blake'),
      ],
      hangouts: [
        _hangout(
          contactIdentifier: 'a',
          displayName: 'Old Alex',
          when: DateTime(2024, 1, 1),
        ),
      ],
    );

    expect(entries, [
      {
        'contactIdentifier': 'a',
        'displayName': 'Alex',
      },
    ]);
  });

  test(
      'buildFriendCatalogEntries uses hangout names when contacts are unavailable',
      () {
    final now = DateTime.now();
    final entries = buildFriendCatalogEntries(
      friends: [
        _friend(contactIdentifier: 'a', isContactable: true),
        _friend(contactIdentifier: 'b', isContactable: true),
        _friend(contactIdentifier: 'c', isContactable: true),
      ],
      contacts: const [],
      hangouts: [
        _hangout(
          contactIdentifier: 'a',
          displayName: 'Alex From Hangout',
          when: now.subtract(const Duration(days: 2)),
        ),
        _hangout(
          contactIdentifier: 'a',
          displayName: 'Alex Latest',
          when: now,
        ),
        _hangout(
          contactIdentifier: 'b',
          displayName: 'Blake',
          when: now,
        ),
      ],
    );

    expect(entries, [
      {
        'contactIdentifier': 'a',
        'displayName': 'Alex Latest',
      },
      {
        'contactIdentifier': 'b',
        'displayName': 'Blake',
      },
    ]);
  });

  test('encodeFriendCatalogEntries round-trips JSON array', () {
    final encoded = encodeFriendCatalogEntries([
      {
        'contactIdentifier': 'a',
        'displayName': 'Alex',
      },
    ]);
    expect(encoded, '[{"contactIdentifier":"a","displayName":"Alex"}]');
  });
}
