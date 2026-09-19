import 'dart:convert';

import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';

/// Builds the App Group friend catalog for Siri App Intents entity resolution.
List<Map<String, String>> buildFriendCatalogEntries({
  required List<Friend> friends,
  required Iterable<Contact> contacts,
}) {
  final contactMap = {
    for (final contact in contacts) contact.id: contact,
  };
  final entries = <Map<String, String>>[];
  for (final friend in friends) {
    if (!friend.isContactable) {
      continue;
    }
    final contact = contactMap[friend.contactIdentifier];
    final displayName = contact?.displayName.trim() ?? '';
    if (displayName.isEmpty) {
      continue;
    }
    entries.add({
      'contactIdentifier': friend.contactIdentifier,
      'displayName': displayName,
    });
  }
  return entries;
}

String encodeFriendCatalogEntries(List<Map<String, String>> entries) {
  return jsonEncode(entries);
}
