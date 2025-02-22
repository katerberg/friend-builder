import 'dart:collection';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:test/test.dart';

String getRandomString([int length = 10]) => String.fromCharCodes(List.generate(
    length,
    (index) => 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
        .codeUnitAt(Random().nextInt(62))));

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

  group('sortRecentContactsFirst', () {
    test('sorts first 7 recent contacts first', () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) =>
              Contact(id: index.toString(), displayName: getRandomString()));
      var recentContacts = LinkedHashSet<EncodableContact>(
          equals: (o1, o2) => o1.identifier == o2.identifier,
          hashCode: (contact) => contact.identifier.hashCode);
      recentContacts
          .add(EncodableContact.fromContact(contactsToSort.elementAt(7)));

      var sortedContacts = ContactsHelper.sortRecentContactsFirst(
          contactsToSort, recentContacts, '');

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '7');
    });

    test('prioritizes perfect matches', () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) =>
              Contact(id: index.toString(), displayName: getRandomString()));
      var recentContacts = LinkedHashSet<EncodableContact>(
          equals: (o1, o2) => o1.identifier == o2.identifier,
          hashCode: (contact) => contact.identifier.hashCode);

      var sortedContacts = ContactsHelper.sortRecentContactsFirst(
          contactsToSort,
          recentContacts,
          contactsToSort.elementAt(9).displayName.substring(0, 3));

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '9');
    });

    test('prioritizes recent hang out if there are multiple perfect matches',
        () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) =>
              Contact(id: index.toString(), displayName: getRandomString()));
      contactsToSort[9].displayName = 'Jane Dorsey';
      contactsToSort[10].displayName = 'Jane Thomas';
      var recentContacts = LinkedHashSet<EncodableContact>(
          equals: (o1, o2) => o1.identifier == o2.identifier,
          hashCode: (contact) => contact.identifier.hashCode);
      recentContacts
          .add(EncodableContact.fromContact(contactsToSort.elementAt(10)));

      var sortedContacts = ContactsHelper.sortRecentContactsFirst(
          contactsToSort, recentContacts, 'Jane');

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '10');
      expect(sortedContacts[1].id, '9');
    });

    test('prioritizes perfect match over recent hang out', () {
      List<Contact> contactsToSort = List.generate(
          20,
          (index) =>
              Contact(id: index.toString(), displayName: getRandomString()));
      contactsToSort[9].displayName = 'Jane Dorsey';
      contactsToSort[10].displayName = 'Jan Thomas';
      var recentContacts = LinkedHashSet<EncodableContact>(
          equals: (o1, o2) => o1.identifier == o2.identifier,
          hashCode: (contact) => contact.identifier.hashCode);
      recentContacts
          .add(EncodableContact.fromContact(contactsToSort.elementAt(10)));

      var sortedContacts = ContactsHelper.sortRecentContactsFirst(
          contactsToSort, recentContacts, 'Jane');

      expect(sortedContacts.length, 7);
      expect(sortedContacts[0].id, '9');
    });
  });
}
