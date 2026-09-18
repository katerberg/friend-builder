import 'dart:convert';
import 'dart:typed_data';

import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/utils/carplay_phone.dart';
import 'package:friend_builder/utils/carplay_urgency.dart';
import 'package:friend_builder/utils/contact_sorting.dart';

class CarPlayTopPerson {
  final String contactIdentifier;
  final String displayName;
  final String urgency;
  final Uint8List? photoBytes;
  final List<Map<String, String>> phones;
  final bool hasPhone;

  const CarPlayTopPerson({
    required this.contactIdentifier,
    required this.displayName,
    required this.urgency,
    required this.photoBytes,
    required this.phones,
    required this.hasPhone,
  });

  Map<String, dynamic> toChannelPayload() {
    return {
      'found': true,
      'contactIdentifier': contactIdentifier,
      'displayName': displayName,
      'urgency': urgency,
      'photoBase64': photoBytes == null ? null : base64Encode(photoBytes!),
      'phones': phones,
      'hasPhone': hasPhone,
    };
  }
}

class CarPlayTopPersonResult {
  final CarPlayTopPerson? person;
  final bool missingContactsPermission;

  const CarPlayTopPersonResult({
    this.person,
    this.missingContactsPermission = false,
  });

  Map<String, dynamic> toChannelPayload() {
    if (missingContactsPermission) {
      return {
        'found': false,
        'reason': 'contacts_permission',
      };
    }
    if (person == null) {
      return {'found': false};
    }
    return person!.toChannelPayload();
  }
}

/// Selects the single most overdue/due contactable friend using the same
/// ordering as Friends ([sortContactsForDisplay]).
Future<CarPlayTopPersonResult> resolveCarPlayTopPerson({
  required bool missingContactsPermission,
  required Iterable<Contact> contacts,
  required List<Friend> friends,
  required List<Hangout> hangouts,
  required Future<Uint8List?> Function(String contactIdentifier) loadPhoto,
}) async {
  if (missingContactsPermission) {
    return const CarPlayTopPersonResult(missingContactsPermission: true);
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
    return const CarPlayTopPersonResult();
  }

  final topContactIdentifier = sorted.hangoutContactIds.first;
  final topContact = contactMap[topContactIdentifier];
  if (topContact == null) {
    return const CarPlayTopPersonResult();
  }

  final friend = friendMap[topContactIdentifier];
  final latestHangout = latestHangoutMap[topContactIdentifier];
  final phones = carPlayPhonesFromContact(topContact);
  final photoBytes = await loadPhoto(topContactIdentifier);

  return CarPlayTopPersonResult(
    person: CarPlayTopPerson(
      contactIdentifier: topContactIdentifier,
      displayName: topContact.displayName,
      urgency: carPlayUrgencyLabel(
        latestHangoutWhen: latestHangout?.when,
        frequency: friend?.frequency,
      ),
      photoBytes: photoBytes,
      phones: phones,
      hasPhone: phones.isNotEmpty,
    ),
  );
}
