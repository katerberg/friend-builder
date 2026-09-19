import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
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

void main() {
  test('buildFriendCatalogEntries includes only contactable friends with names',
      () {
    final entries = buildFriendCatalogEntries(
      friends: [
        _friend(contactIdentifier: 'a', isContactable: true),
        _friend(contactIdentifier: 'b', isContactable: false),
        _friend(contactIdentifier: 'missing', isContactable: true),
        _friend(contactIdentifier: 'blank', isContactable: true),
      ],
      contacts: [
        _contact(id: 'a', displayName: 'Alex'),
        _contact(id: 'b', displayName: 'Blake'),
        _contact(id: 'blank', displayName: '   '),
      ],
    );

    expect(entries, [
      {
        'contactIdentifier': 'a',
        'displayName': 'Alex',
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
