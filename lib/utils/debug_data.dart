import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/utils/string_utils.dart';

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

  static bool _isDebugContact(Contact contact) {
    return contact.name?.nickname == 'DEBUG';
  }

  // Creates fake device contacts and friends for testing if they don't already exist
  static Future<void> populateFakeContactsIfNeeded() async {
    if (!kDebugMode) {
      return;
    }

    try {
      final status = await FlutterContacts.permissions
          .request(PermissionType.readWrite);
      if (status != PermissionStatus.granted) {
        debugPrint('⚠️  Contact permission denied, skipping debug contacts');
        return;
      }

      final existingContacts = await FlutterContacts.getAll(
        properties: ContactProperties.allProperties,
      );

      final existingFriends = await Storage.getFriends();
      final existingIdentifiers =
          existingFriends?.map((f) => f.contactIdentifier).toSet() ?? {};

      int contactsCreated = 0;
      int friendsCreated = 0;
      final List<Friend> friendsToAdd = [];

      for (final fakeContact in _fakeContacts) {
        final firstName = fakeContact['firstName']!;
        final lastName = fakeContact['lastName']!;
        final fullName = '$firstName $lastName';

        Contact? existingContact;
        for (final contact in existingContacts) {
          if (contact.name?.first == firstName &&
              contact.name?.last == lastName) {
            existingContact = contact;
            break;
          }
        }

        String contactId;
        final isDebugContact =
            existingContact != null && _isDebugContact(existingContact);

        if (existingContact == null || (existingContact.id ?? '').isEmpty) {
          final newContact = Contact(
            name: Name(
              first: firstName,
              last: lastName,
              nickname: 'DEBUG',
            ),
            displayName: fullName,
            phones: [
              Phone(
                  number:
                      '+1555${100 + contactsCreated}${200 + contactsCreated}')
            ],
            emails: [
              Email(
                  address:
                      '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com')
            ],
          );

          contactId = await FlutterContacts.create(newContact);
          contactsCreated++;
          debugPrint('📱 Created device contact: $fullName [DEBUG]');
        } else {
          contactId = existingContact.id!;
          if (isDebugContact) {
            debugPrint('ℹ️  Device contact already exists: $fullName [DEBUG]');
          } else {
            debugPrint('ℹ️  Using existing real contact: $fullName');
          }
        }

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

      if (friendsToAdd.isNotEmpty) {
        final storage = Storage();
        await storage.saveFriends(friendsToAdd);
      }

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
    if (!kDebugMode) {
      return;
    }
    try {
      final allFriends = await Storage.getFriends();
      if (allFriends == null || allFriends.isEmpty) {
        debugPrint('⚠️  No friends found, cannot create hangouts');
        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: ContactProperties.allProperties,
      );

      final contactMap = <String, Contact>{};
      for (final contact in contacts) {
        final contactId = contact.id;
        if (contactId != null) {
          contactMap[contactId] = contact;
        }
      }

      final random = Random();
      final storage = Storage();
      final List<Hangout> hangoutsToCreate = [];
      final now = DateTime.now();

      int getRandomFriendCount() {
        final roll = random.nextInt(100);
        if (roll < 40) return 1; // 40%
        if (roll < 70) return 2; // 30%
        if (roll < 90) return 3; // 20%
        if (roll < 97) return 4; // 7%
        return 5; // 3%
      }

      for (int i = 0; i < 1000; i++) {
        final friendCount = getRandomFriendCount();

        final selectedFriendIndices = <int>[];
        while (selectedFriendIndices.length < friendCount &&
            selectedFriendIndices.length < allFriends.length) {
          final index = random.nextInt(allFriends.length);
          if (!selectedFriendIndices.contains(index)) {
            selectedFriendIndices.add(index);
          }
        }

        final hangoutContacts = <EncodableContact>[];
        for (final index in selectedFriendIndices) {
          final friend = allFriends[index];
          final contact = contactMap[friend.contactIdentifier];
          if (contact != null) {
            hangoutContacts.add(EncodableContact.fromContact(contact));
          }
        }

        if (hangoutContacts.isEmpty) {
          continue;
        }

        final daysAgo = random.nextInt(730); // 0-730 days
        final hangoutDate = now.subtract(Duration(days: daysAgo));

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

      for (final hangout in hangoutsToCreate) {
        await storage.createHangout(hangout);
      }

      debugPrint(
          '✅ Created ${hangoutsToCreate.length} fake hangouts with 1-5 friends each');
    } catch (e) {
      debugPrint('❌ Error creating fake hangouts: $e');
    }
  }

  static Future<int> removeDebugHangouts() async {
    if (!kDebugMode) {
      return 0;
    }

    try {
      final storage = Storage();
      final hangouts = await storage.getHangouts();

      if (hangouts == null || hangouts.isEmpty) {
        debugPrint('ℹ️  No hangouts found to clean up');
        return 0;
      }

      final debugHangouts =
          hangouts.where((h) => h.notes.contains('[DEBUG]')).toList();

      if (debugHangouts.isEmpty) {
        debugPrint('ℹ️  No debug hangouts found');
        return 0;
      }

      for (final hangout in debugHangouts) {
        await storage.deleteHangout(hangout);
      }

      debugPrint('🗑️  Removed ${debugHangouts.length} debug hangouts');
      return debugHangouts.length;
    } catch (e) {
      debugPrint('❌ Error removing debug hangouts: $e');
      return 0;
    }
  }

  static Future<int> removeDebugContacts() async {
    if (!kDebugMode) {
      return 0;
    }

    try {
      final status = await FlutterContacts.permissions
          .request(PermissionType.readWrite);
      if (status != PermissionStatus.granted) {
        debugPrint(
            '⚠️  Contact permission denied, cannot remove debug contacts');
        return 0;
      }

      final contacts = await FlutterContacts.getAll(
        properties: ContactProperties.allProperties,
      );
      debugPrint('📱 Found ${contacts.length} total contacts on device');

      final debugContacts =
          contacts.where(_isDebugContact).toList();

      if (debugContacts.isEmpty) {
        debugPrint('ℹ️  No debug contacts found');
        return 0;
      }

      debugPrint('🔍 Found ${debugContacts.length} debug contacts to remove');

      final storage = Storage();
      final friends = await Storage.getFriends();
      final debugContactIds = debugContacts
          .map((c) => c.id)
          .whereType<String>()
          .toSet();

      final debugFriends = friends
              ?.where((f) => debugContactIds.contains(f.contactIdentifier))
              .toList() ??
          [];

      for (final friend in debugFriends) {
        await storage.deleteFriend(friend);
      }

      for (final contact in debugContacts) {
        if (contact.id != null) {
          await FlutterContacts.delete(contact.id!);
        }
      }

      debugPrint(
          '🗑️  Removed ${debugContacts.length} debug contacts and ${debugFriends.length} friend records');
      return debugContacts.length;
    } catch (e) {
      debugPrint('❌ Error removing debug contacts: $e');
      return 0;
    }
  }
}
