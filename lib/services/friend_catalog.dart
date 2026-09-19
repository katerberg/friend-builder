import 'dart:convert';

import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/hangout.dart';

/// Builds the App Group friend catalog for Siri App Intents entity resolution.
///
/// Contactable [Friend] rows are the source of truth. Device contacts enrich
/// display names when available; hangout contact snapshots fill gaps when
/// contacts permission is missing or a CN contact was deleted.
List<Map<String, String>> buildFriendCatalogEntries({
  required List<Friend> friends,
  required Iterable<Contact> contacts,
  List<Hangout> hangouts = const [],
}) {
  final contactMap = {
    for (final contact in contacts) contact.safeId: contact,
  };
  final hangoutDisplayNames = _latestHangoutDisplayNames(hangouts);
  final entries = <Map<String, String>>[];
  for (final friend in friends) {
    if (!friend.isContactable) {
      continue;
    }
    final contact = contactMap[friend.contactIdentifier];
    final contactDisplayName = contact?.safeDisplayName.trim() ?? '';
    final hangoutDisplayName =
        hangoutDisplayNames[friend.contactIdentifier] ?? '';
    final displayName = contactDisplayName.isNotEmpty
        ? contactDisplayName
        : hangoutDisplayName;
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

Map<String, String> _latestHangoutDisplayNames(List<Hangout> hangouts) {
  final sortedHangouts = List<Hangout>.from(hangouts)
    ..sort((left, right) => right.when.compareTo(left.when));
  final displayNames = <String, String>{};
  for (final hangout in sortedHangouts) {
    for (final hangoutContact in hangout.contacts) {
      final identifier = hangoutContact.identifier;
      if (identifier.isEmpty || displayNames.containsKey(identifier)) {
        continue;
      }
      final displayName = hangoutContact.safeDisplayName.trim();
      if (displayName.isEmpty) {
        continue;
      }
      displayNames[identifier] = displayName;
    }
  }
  return displayNames;
}

String encodeFriendCatalogEntries(List<Map<String, String>> entries) {
  return jsonEncode(entries);
}
