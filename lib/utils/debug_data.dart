import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/utils/string_utils.dart';

/// Debug-only utility to populate fake contacts for testing
/// This will only run in debug mode and will not create duplicates
class DebugData {
  static List<Map<String, String>> get _fakeContacts => [
        {'firstName': 'Alice', 'lastName': 'Johnson', 'frequency': 'Weekly'},
        {'firstName': 'Bob', 'lastName': 'Smith', 'frequency': 'Monthly'},
        {'firstName': 'Charlie', 'lastName': 'Davis', 'frequency': 'Quarterly'},
        {'firstName': 'Diana', 'lastName': 'Martinez', 'frequency': 'Weekly'},
        {'firstName': 'Ethan', 'lastName': 'Wilson', 'frequency': 'Monthly'},
        {
          'firstName': 'Random',
          'lastName': 'Name ${StringUtils.getRandomString(10)}',
          'frequency': 'Monthly'
        },
      ];

  /// Creates fake device contacts and friends for testing if they don't already exist
  /// Only runs in debug mode
  static Future<void> populateFakeContactsIfNeeded() async {
    if (!kDebugMode) {
      return;
    }

    try {
      // Check if we have permission to access contacts
      if (!await FlutterContacts.requestPermission()) {
        debugPrint('⚠️  Contact permission denied, skipping debug contacts');
        return;
      }

      // Get existing device contacts
      final existingContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      // Get existing friends from database
      final existingFriends = await Storage.getFriends();
      final existingIdentifiers =
          existingFriends?.map((f) => f.contactIdentifier).toSet() ?? {};

      int contactsCreated = 0;
      int friendsCreated = 0;
      final List<Friend> friendsToAdd = [];

      // Check each fake contact and create if needed
      for (final fakeContact in _fakeContacts) {
        final firstName = fakeContact['firstName']!;
        final lastName = fakeContact['lastName']!;
        final fullName = '$firstName $lastName';

        // Check if this contact already exists on the device (with or without DEBUG prefix)
        Contact? existingContact = existingContacts.firstWhere(
          (c) => c.name.first == firstName && c.name.last == lastName,
          orElse: () => Contact(),
        );

        String contactId;
        bool isDebugContact = existingContact.displayName.contains('DEBUG');

        // Create device contact only if no contact with that name exists
        if (existingContact.id.isEmpty) {
          final newContact = Contact()
            ..name.first = firstName
            ..name.last = lastName
            ..displayName = '$fullName [DEBUG]'
            ..phones = [
              Phone('+1555${100 + contactsCreated}${200 + contactsCreated}')
            ]
            ..emails = [
              Email(
                  '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com')
            ];

          final insertedContact =
              await FlutterContacts.insertContact(newContact);
          contactId = insertedContact.id;
          contactsCreated++;
          debugPrint('📱 Created device contact: $fullName [DEBUG]');
        } else {
          contactId = existingContact.id;
          if (isDebugContact) {
            debugPrint('ℹ️  Device contact already exists: $fullName [DEBUG]');
          } else {
            debugPrint('ℹ️  Using existing real contact: $fullName');
          }
        }

        // Create Friend record if it doesn't exist
        if (!existingIdentifiers.contains(contactId)) {
          final friend = Friend(
            contactIdentifier: contactId,
            notes: 'Debug test contact',
            frequency: Frequency.fromType(fakeContact['frequency']!),
            isContactable: true,
          );

          friendsToAdd.add(friend);
          friendsCreated++;
        }
      }

      // Save all new friends to database
      if (friendsToAdd.isNotEmpty) {
        final storage = Storage();
        await storage.saveFriends(friendsToAdd);
      }

      // Summary
      if (contactsCreated > 0 || friendsCreated > 0) {
        debugPrint(
            '✅ Debug data created: $contactsCreated device contacts, $friendsCreated friend records');
      } else {
        debugPrint('ℹ️  All debug contacts and friends already exist');
      }
    } catch (e) {
      debugPrint('❌ Error creating debug contacts: $e');
    }
  }
}
