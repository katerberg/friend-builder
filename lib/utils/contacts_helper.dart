import 'dart:collection';

import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
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
    // Handle both regular Contacts and EncodableContacts which may use identifier
    String removeId = friendToRemove is EncodableContact &&
            friendToRemove.identifier.isNotEmpty
        ? friendToRemove.identifier
        : friendToRemove.id;

    return contacts.where((element) {
      String elementId =
          element is EncodableContact && element.identifier.isNotEmpty
              ? element.identifier
              : element.id;
      return elementId != removeId;
    }).toList();
  }

  static bool isPerfectSubsetMatch(String testString, String pattern) {
    var lowerTestString = testString.toLowerCase();
    var lowerPattern = pattern.toLowerCase();
    return lowerTestString.startsWith(lowerPattern) ||
        lowerTestString.split(' ').any((part) => part.startsWith(lowerPattern));
  }

  static List<Contact> sortRecentContactsFirst(List<Contact> contactsToSort,
      LinkedHashSet<EncodableContact> recentContacts, String pattern) {
    const maxResults = 7;
    var sorted = contactsToSort
      ..sort((a, b) {
        if (isPerfectSubsetMatch(a.displayName, pattern)) {
          if (isPerfectSubsetMatch(b.displayName, pattern) &&
              recentContacts.any((c) => c.identifier == b.id)) {
            return 1;
          }
          return -1;
        }
        if (isPerfectSubsetMatch(b.displayName, pattern)) {
          if (isPerfectSubsetMatch(a.displayName, pattern) &&
              recentContacts.any((c) => c.identifier == a.id)) {
            return -1;
          }
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
    return sorted.sublist(
        0,
        contactsToSort.length > maxResults
            ? maxResults
            : contactsToSort.length);
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
    return sortRecentContactsFirst(listOfFriends, recentContacts, pattern);
  }
}
