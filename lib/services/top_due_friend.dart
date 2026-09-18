import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/utils/contact_sorting.dart';
import 'package:friend_builder/utils/due_friend_urgency.dart';

class TopDueFriend {
  final String contactIdentifier;
  final String displayName;
  final String urgency;

  const TopDueFriend({
    required this.contactIdentifier,
    required this.displayName,
    required this.urgency,
  });

  Map<String, dynamic> toSnapshotPayload() {
    return {
      'found': true,
      'contactIdentifier': contactIdentifier,
      'displayName': displayName,
      'urgency': urgency,
    };
  }
}

class TopDueFriendResult {
  final TopDueFriend? friend;
  final bool missingContactsPermission;

  const TopDueFriendResult({
    this.friend,
    this.missingContactsPermission = false,
  });

  Map<String, dynamic> toSnapshotPayload() {
    if (missingContactsPermission) {
      return {
        'found': false,
        'reason': 'contacts_permission',
      };
    }
    if (friend == null) {
      return {'found': false};
    }
    return friend!.toSnapshotPayload();
  }
}

/// Selects the single most overdue/due contactable friend using the same
/// ordering as Friends ([sortContactsForDisplay]).
TopDueFriendResult resolveTopDueFriend({
  required bool missingContactsPermission,
  required Iterable<Contact> contacts,
  required List<Friend> friends,
  required List<Hangout> hangouts,
}) {
  if (missingContactsPermission) {
    return const TopDueFriendResult(missingContactsPermission: true);
  }

  final friendMap = {
    for (final friend in friends) friend.contactIdentifier: friend,
  };
  final latestHangoutMap = <String, Hangout?>{};
  for (final hangout in hangouts) {
    for (final hangoutContact in hangout.contacts) {
      final existingHangout = latestHangoutMap[hangoutContact.identifier];
      if (existingHangout == null ||
          hangout.when.isAfter(existingHangout.when)) {
        latestHangoutMap[hangoutContact.identifier] = hangout;
      }
    }
  }

  final contactMap = {for (final contact in contacts) contact.id: contact};
  final sortableContacts = contacts.map((contact) {
    final friend = friendMap[contact.id];
    final hangout = latestHangoutMap[contact.id];
    return SortableContact(
      id: contact.id,
      displayName: contact.displayName,
      frequencyValue: friend?.frequency.value,
      lastHangoutDate: hangout?.when,
      isContactable: friend?.isContactable ?? false,
    );
  }).toList();

  final sorted = sortContactsForDisplay(sortableContacts);
  if (sorted.hangoutContactIds.isEmpty) {
    return const TopDueFriendResult();
  }

  final topContactIdentifier = sorted.hangoutContactIds.first;
  final topContact = contactMap[topContactIdentifier];
  if (topContact == null) {
    return const TopDueFriendResult();
  }

  final friend = friendMap[topContactIdentifier];
  final latestHangout = latestHangoutMap[topContactIdentifier];

  return TopDueFriendResult(
    friend: TopDueFriend(
      contactIdentifier: topContactIdentifier,
      displayName: topContact.displayName,
      urgency: dueFriendUrgencyLabel(
        latestHangoutWhen: latestHangout?.when,
        frequency: friend?.frequency,
      ),
    ),
  );
}
