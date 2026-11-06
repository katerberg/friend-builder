import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';

/// Shown for a hangout participant whose device contact can't be found
/// (deleted, or contact IDs changed on a new device).
const String unknownContactName = 'Unknown contact';

/// Converts hangout contacts to and from their cloud representation.
///
/// Only the opaque device contact identifier is uploaded. Names, numbers and
/// other contact details never leave the device; they are looked up again from
/// the device's contacts on restore.
class CloudContactCodec {
  static List<Map<String, String>> encode(Iterable<EncodableContact> contacts) {
    return contacts.map((c) => {'identifier': c.identifier}).toList();
  }

  /// Rebuilds a contact from a cloud entry. Prefers the live device contact;
  /// falls back to names on legacy cloud entries that still carry them; and
  /// otherwise uses [unknownContactName].
  static EncodableContact decode(
    Map<String, dynamic> data,
    Map<String, Contact> deviceContactsById,
  ) {
    final identifier = data['identifier'] as String? ?? '';
    final deviceContact =
        identifier.isEmpty ? null : deviceContactsById[identifier];
    if (deviceContact != null) {
      return EncodableContact.fromContact(deviceContact);
    }

    final legacyDisplayName = (data['displayName'] as String? ?? '').trim();
    if (legacyDisplayName.isNotEmpty) {
      return EncodableContact(
        displayName: legacyDisplayName,
        middleName: data['middleName'] as String? ?? '',
        givenName: data['givenName'] as String? ?? '',
        identifier: identifier,
        familyName: data['familyName'] as String? ?? '',
      );
    }

    return EncodableContact(
      displayName: unknownContactName,
      middleName: '',
      givenName: '',
      identifier: identifier,
      familyName: '',
    );
  }

  /// True if any entry carries more than the identifier (written by app
  /// versions that uploaded names).
  static bool containsPersonalFields(List<dynamic> cloudContacts) {
    return cloudContacts.any(
      (c) => c is Map && c.keys.any((key) => key != 'identifier'),
    );
  }

  static List<Map<String, String>> stripPersonalFields(
      List<dynamic> cloudContacts) {
    return cloudContacts
        .map((c) => {
              'identifier': c is Map ? (c['identifier'] as String? ?? '') : '',
            })
        .toList();
  }

  /// True if a locally stored hangout contact has no real name yet (restored
  /// before contacts permission was granted, or the contact wasn't found).
  static bool needsNameBackfill(EncodableContact contact) {
    final displayName = contact.safeDisplayName.trim();
    return displayName.isEmpty || displayName == unknownContactName;
  }
}
