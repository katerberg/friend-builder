import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/utils/search_utils.dart';
import 'package:friend_builder/utils/string_utils.dart';

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
      List<Contact> excludedContacts, String pattern) async {
    ContactPermission contactPermission =
        await ContactPermissionService().getContacts();
    if (contactPermission.missingPermission) {
      return Future.value([]);
    }
    var listOfFriends = await Future.value(contactPermission.contacts
        .where((element) =>
            !excludedContacts.any((selected) => selected.id == element.id) &&
            (pattern.length < 2 ||
                StringUtils.getComparison(element.displayName, pattern) > 0.1))
        .toList());
    var sortedFriends = listOfFriends
      ..sort((a, b) {
        return SearchUtils.sortTwoFriendsInSuggestions(pattern, a, b);
      });
    const maxResults = 7;
    return sortedFriends.sublist(0,
        sortedFriends.length > maxResults ? maxResults : sortedFriends.length);
  }
}
