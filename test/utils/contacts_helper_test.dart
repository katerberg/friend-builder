import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/contact_search.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:friend_builder/utils/string_utils.dart';
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

  group('sortAndLimitSuggestions', () {
    test('sorts first 7 recent contacts first', () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) => Contact(
              id: index.toString(),
              displayName: StringUtils.getRandomString()));
      final recentContact = contactsToSort.elementAt(7);
      final recentIdentifiers = <String>{
        EncodableContact.fromContact(recentContact).identifier,
        recentContact.id,
      };

      var sortedContacts = ContactSearch.sortAndLimitSuggestions(
          contactsToSort, '', recentIdentifiers);

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '7');
    });

    test('prioritizes perfect matches', () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) => Contact(
              id: index.toString(),
              displayName: StringUtils.getRandomString()));
      const recentIdentifiers = <String>{};

      var sortedContacts = ContactSearch.sortAndLimitSuggestions(
          contactsToSort,
          contactsToSort.elementAt(9).displayName.substring(0, 3),
          recentIdentifiers);

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '9');
    });

    test('prioritizes recent hang out if there are multiple perfect matches',
        () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) => Contact(
              id: index.toString(),
              displayName: StringUtils.getRandomString()));
      contactsToSort[9].displayName = 'Jane Dorsey';
      contactsToSort[10].displayName = 'Jane Thomas';
      final recentContact = contactsToSort.elementAt(10);
      final recentIdentifiers = <String>{
        EncodableContact.fromContact(recentContact).identifier,
        recentContact.id,
      };

      var sortedContacts = ContactSearch.sortAndLimitSuggestions(
          contactsToSort, 'Jane', recentIdentifiers);

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '10');
      expect(sortedContacts[1].id, '9');
    });

    test('prioritizes perfect match over recent hang out', () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) => Contact(
              id: index.toString(),
              displayName: StringUtils.getRandomString()));
      contactsToSort[9].displayName = 'Jane Dorsey';
      contactsToSort[10].displayName = 'Jan Thomas';
      final recentContact = contactsToSort.elementAt(10);
      final recentIdentifiers = <String>{
        EncodableContact.fromContact(recentContact).identifier,
        recentContact.id,
      };

      var sortedContacts = ContactSearch.sortAndLimitSuggestions(
          contactsToSort, 'Jane', recentIdentifiers);

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '9');
    });
  });

  group('filterContacts', () {
    test('filters mixed list of Contacts and EncodableContacts', () {
      List<Contact> contacts = [
        Contact(id: '1', displayName: 'Alice'),
        EncodableContact(
            identifier: '2',
            displayName: 'Bob',
            givenName: 'Bob',
            familyName: 'Jones',
            middleName: ''),
        Contact(id: '3', displayName: 'Charlie'),
      ];
      Contact toRemove = EncodableContact(
          identifier: '2',
          displayName: 'Bob',
          givenName: 'Bob',
          familyName: 'Jones',
          middleName: '');

      var filtered = ContactsHelper.filterContacts(contacts, toRemove);

      expect(filtered.length, 2);
      expect(filtered[0].id, '1');
      expect(filtered[1].id, '3');
    });

    test('returns empty list when filtering last contact', () {
      List<Contact> contacts = [
        Contact(id: '1', displayName: 'Alice'),
      ];
      Contact toRemove = Contact(id: '1', displayName: 'Alice');

      var filtered = ContactsHelper.filterContacts(contacts, toRemove);

      expect(filtered.length, 0);
    });

    test('returns same list when contact to remove is not present', () {
      List<Contact> contacts = [
        Contact(id: '1', displayName: 'Alice'),
        Contact(id: '2', displayName: 'Bob'),
      ];
      Contact toRemove = Contact(id: '3', displayName: 'Charlie');

      var filtered = ContactsHelper.filterContacts(contacts, toRemove);

      expect(filtered.length, 2);
      expect(filtered[0].id, '1');
      expect(filtered[1].id, '2');
    });

    test('handles EncodableContact with empty identifier falling back to id',
        () {
      List<Contact> contacts = [
        EncodableContact(
            identifier: '',
            displayName: 'Alice',
            givenName: 'Alice',
            familyName: 'Smith',
            middleName: ''),
        Contact(id: '2', displayName: 'Bob'),
      ];
      contacts[0].id = '1'; // Set id on EncodableContact with empty identifier

      Contact toRemove = Contact(id: '1', displayName: 'Alice');

      var filtered = ContactsHelper.filterContacts(contacts, toRemove);

      expect(filtered.length, 1);
      expect(filtered[0].id, '2');
    });
  });
}
