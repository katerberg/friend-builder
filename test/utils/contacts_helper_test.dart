import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_contacts/properties/name.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:test/test.dart';

void main() {
  group('getContactName', () {
    test('shows "this person" by default', () {
      expect(ContactsHelper.getContactName(Contact()), 'this person');
    });

    test('shows display name if available', () {
      expect(ContactsHelper.getContactName(Contact(displayName: 'Jane Dorsey')),
          'Jane Dorsey');
    });

    test('shows first name over displayName if available', () {
      expect(
          ContactsHelper.getContactName(
              Contact(displayName: 'Jane Dorsey', name: Name(first: "Jane"))),
          'Jane');
    });

    test('shows nickname over first name if available', () {
      expect(
          ContactsHelper.getContactName(Contact(
              displayName: 'Jane Dorsey',
              name: Name(nickname: "Jane Bane", first: "Jane"))),
          'Jane Bane');
    });
  });
}
