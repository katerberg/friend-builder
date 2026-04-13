import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/contact_search.dart';
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

  static const int _minimumQueryLengthBeforeFiltering = 2;

  /// Load contacts (or use [contacts]), exclude selected, filter by query match,
  /// then rank and cap. Sort: [ContactSearch.tierForContact] (stronger name match
  /// wins) → recent hangout (60d) → [ContactSearch.bigramScoreForContact] → name.
  static Future<List<Contact>> getSuggestions(
    List<Contact> excludedContacts,
    String pattern, {
    Iterable<Contact>? contacts,
    Iterable<Hangout>? previousHangouts,
  }) async {
    final contactsFromWhichToSuggest =
        await _fetchContactsUnlessProvided(contacts);
    if (contactsFromWhichToSuggest == null) {
      return [];
    }
    final suggestionCandidates = _filteredSuggestionCandidates(
      contactsFromWhichToSuggest,
      excludedContacts,
      pattern,
    );
    final recentContactIdentifiers =
        _identifiersForRecentHangoutContacts(previousHangouts);
    return ContactSearch.sortAndLimitSuggestions(
      suggestionCandidates,
      pattern,
      recentContactIdentifiers,
    );
  }

  static Future<Iterable<Contact>?> _fetchContactsUnlessProvided(
    Iterable<Contact>? contacts,
  ) async {
    if (contacts != null) {
      return contacts;
    }
    final contactPermission =
        await ContactPermissionService().getContacts();
    if (contactPermission.missingPermission) {
      return null;
    }
    return contactPermission.contacts;
  }

  static List<Contact> _filteredSuggestionCandidates(
    Iterable<Contact> contactsFromWhichToSuggest,
    List<Contact> excludedContacts,
    String pattern,
  ) {
    return contactsFromWhichToSuggest
        .where((element) =>
            !excludedContacts.any((selected) => selected.id == element.id) &&
            ContactSearch.passesSuggestionFilter(
              element,
              pattern,
              minimumPatternLengthForMatch: _minimumQueryLengthBeforeFiltering,
            ))
        .toList();
  }

  static Set<String> _identifiersForRecentHangoutContacts(
    Iterable<Hangout>? previousHangouts,
  ) {
    final recentContactIdentifiers = <String>{};
    previousHangouts?.forEach((hangout) {
      final isWithinRecencyWindow = hangout.when.compareTo(
            DateTime.now().subtract(const Duration(days: 60)),
          ) ==
          1;
      if (!isWithinRecencyWindow) {
        return;
      }
      for (final contact in hangout.contacts) {
        if (contact.identifier.isNotEmpty) {
          recentContactIdentifiers.add(contact.identifier);
        }
        if (contact.id.isNotEmpty) {
          recentContactIdentifiers.add(contact.id);
        }
      }
    });
    return recentContactIdentifiers;
  }
}
