import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/data/hangout.dart';
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

  /// Creates 1000 fake hangouts with semi-random distribution of friends (1-5 per hangout)
  static Future<void> populateFakeHangoutsIfNeeded() async {
    try {
      // Get all existing friends
      final allFriends = await Storage.getFriends();
      if (allFriends == null || allFriends.isEmpty) {
        debugPrint('⚠️  No friends found, cannot create hangouts');
        return;
      }

      // Get all contacts to create EncodableContacts
      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      // Create a map of contactIdentifier -> Contact for quick lookup
      final contactMap = <String, Contact>{};
      for (final contact in contacts) {
        contactMap[contact.id] = contact;
      }

      final random = Random();
      final storage = Storage();
      final List<Hangout> hangoutsToCreate = [];
      final now = DateTime.now();

      // Distribution weights for number of friends per hangout
      // Weighted towards smaller groups: 40% single, 30% pairs, 20% triplets, 7% quads, 3% five
      int getRandomFriendCount() {
        final roll = random.nextInt(100);
        if (roll < 40) return 1; // 40%
        if (roll < 70) return 2; // 30%
        if (roll < 90) return 3; // 20%
        if (roll < 97) return 4; // 7%
        return 5; // 3%
      }

      for (int i = 0; i < 1000; i++) {
        // Determine how many friends for this hangout
        final friendCount = getRandomFriendCount();

        // Randomly select friends (without replacement for this hangout)
        final selectedFriendIndices = <int>[];
        while (selectedFriendIndices.length < friendCount &&
            selectedFriendIndices.length < allFriends.length) {
          final index = random.nextInt(allFriends.length);
          if (!selectedFriendIndices.contains(index)) {
            selectedFriendIndices.add(index);
          }
        }

        // Convert to EncodableContacts
        final hangoutContacts = <EncodableContact>[];
        for (final index in selectedFriendIndices) {
          final friend = allFriends[index];
          final contact = contactMap[friend.contactIdentifier];
          if (contact != null) {
            hangoutContacts.add(EncodableContact.fromContact(contact));
          }
        }

        // Skip if we couldn't find any contacts
        if (hangoutContacts.isEmpty) {
          continue;
        }

        // Generate a random date within the past 2 years
        final daysAgo = random.nextInt(730); // 0-730 days
        final hangoutDate = now.subtract(Duration(days: daysAgo));

        // Generate notes
        final notesOptions = [
          'Coffee catch-up',
          'Lunch meeting',
          'Dinner party',
          'Movie night',
          'Game night',
          'Hiking trip',
          'Beach day',
          'Birthday celebration',
          'Casual meetup',
          'Brunch',
          'Bar hopping',
          'Concert',
          'Sports game',
          'Video call',
          'Park walk',
          'Museum visit',
          'Shopping trip',
          'Cooking together',
          'Book club',
          'Workout session',
        ];
        final notes =
            '${notesOptions[random.nextInt(notesOptions.length)]} [DEBUG]';

        final hangout = Hangout(
          contacts: hangoutContacts,
          notes: notes,
          when: hangoutDate,
        );

        hangoutsToCreate.add(hangout);
      }

      // Save all hangouts
      for (final hangout in hangoutsToCreate) {
        await storage.createHangout(hangout);
      }

      debugPrint(
          '✅ Created ${hangoutsToCreate.length} fake hangouts with 1-5 friends each');
    } catch (e) {
      debugPrint('❌ Error creating fake hangouts: $e');
    }
  }
}
