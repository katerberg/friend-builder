import 'dart:collection';

import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/search_utils.dart';
import 'package:friend_builder/utils/string_utils.dart';
import 'package:friend_builder/data/hangout.dart';

class ContactsHelper {
  static String getContactName(Contact? contact) {
    var fullName = contact?.displayName.trim();
    var nickName = contact?.name.nickname.trim();
    var firstName = contact?.name.first.trim();
    if (nickName != null && nickName != '') {
      return nickName;
    }
    if (firstName != null && firstName != '') {
      return firstName;
    }
    if (fullName != null && fullName != '') {
      return fullName;
    }

    return 'this person';
  }

  static List<Contact> filterContacts(
      List<Contact> contacts, Contact friendToRemove) {
    return contacts
        .where((element) => element.id != friendToRemove.id)
        .toList();
  }

  static Future<List<Contact>> getSuggestions(
    List<Contact> excludedContacts,
    String pattern, {
    Iterable<Contact>? contacts,
    Iterable<Hangout>? previousHangouts,
  }) async {
    Iterable<Contact> contactsFromWhichToSuggest;
    if (contacts == null) {
      ContactPermission contactPermission =
          await ContactPermissionService().getContacts();
      if (contactPermission.missingPermission) {
        return Future.value([]);
      }
      contactsFromWhichToSuggest =
          await Future.value(contactPermission.contacts);
    } else {
      contactsFromWhichToSuggest = contacts;
    }
    var listOfFriends = contactsFromWhichToSuggest
        .where((element) =>
            !excludedContacts.any((selected) => selected.id == element.id) &&
            (pattern.length < 2 ||
                StringUtils.getComparison(element.displayName, pattern) > 0.1))
        .toList();
    var recentContacts = LinkedHashSet<EncodableContact>(
        equals: (o1, o2) => o1.identifier == o2.identifier,
        hashCode: (contact) => contact.identifier.hashCode);
    previousHangouts?.forEach((hangout) {
      if (hangout.when
              .compareTo(DateTime.now().subtract(const Duration(days: 60))) ==
          1) {
        for (var contact in hangout.contacts) {
          recentContacts.add(contact);
        }
      }
    });
    var sortedFriends = listOfFriends
      ..sort((a, b) => SearchUtils.sortTwoFriendsInSuggestions(pattern, a, b));
    const maxResults = 7;

    return sortedFriends.sublist(0,
        sortedFriends.length > maxResults ? maxResults : sortedFriends.length)
      ..sort((a, b) {
        if (a.displayName.toLowerCase().startsWith(pattern.toLowerCase())) {
          return -1;
        }
        if (b.displayName.toLowerCase().startsWith(pattern.toLowerCase())) {
          return 1;
        }
        if (recentContacts.any((c) => c.identifier == a.id)) {
          return -1;
        }
        if (recentContacts.any((c) => c.identifier == b.id)) {
          return 1;
        }
        return 0;
      });
  }
}
