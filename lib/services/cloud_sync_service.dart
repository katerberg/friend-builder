import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/snooze_reminder.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _firebaseUserIdKey = 'firebase_user_id';
const String _lastSyncTimestampKey = 'last_sync_timestamp';

class CloudSyncService {
  static final CloudSyncService _instance = CloudSyncService._internal();
  factory CloudSyncService() => _instance;
  CloudSyncService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isInitialized = false;
  bool _isSyncing = false;
  String? _userId;

  FirebaseFirestore get _firestore {
    if (_firestoreInstance == null) {
      throw Exception('CloudSyncService not initialized');
    }
    return _firestoreInstance!;
  }

  FirebaseAuth get _auth {
    if (_authInstance == null) {
      throw Exception('CloudSyncService not initialized');
    }
    return _authInstance!;
  }

  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  String? get userId => _userId;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      _firestoreInstance = FirebaseFirestore.instance;
      _authInstance = FirebaseAuth.instance;

      String? storedUserId = await _secureStorage.read(key: _firebaseUserIdKey);

      if (storedUserId != null && _auth.currentUser?.uid == storedUserId) {
        _userId = storedUserId;
        if (kDebugMode) {
          print('Using existing Firebase user: $_userId');
        }
      } else {
        UserCredential userCredential = await _auth.signInAnonymously();
        _userId = userCredential.user!.uid;
        await _secureStorage.write(key: _firebaseUserIdKey, value: _userId);
        if (kDebugMode) {
          print('Created new anonymous Firebase user: $_userId');
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initialize CloudSyncService: $e');
        print('This is expected if Firebase is not yet configured.');
        print('Please follow FIREBASE_SETUP.md to configure Firebase.');
      }
    }
  }

  Future<DateTime?> getLastSyncTimestamp() async {
    final preferences = await SharedPreferences.getInstance();
    final timestamp = preferences.getInt(_lastSyncTimestampKey);
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  Future<void> _updateLastSyncTimestamp() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      _lastSyncTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  bool _shouldSyncBasedOnThrottle(
      DateTime? lastSync, Duration throttleDuration) {
    if (lastSync == null) return true;
    final timeSinceLastSync = DateTime.now().difference(lastSync);
    return timeSinceLastSync >= throttleDuration;
  }

  Future<bool> shouldSyncOnStartup() async {
    final lastSync = await getLastSyncTimestamp();
    return _shouldSyncBasedOnThrottle(lastSync, const Duration(days: 1));
  }

  Future<bool> shouldSyncManually() async {
    final lastSync = await getLastSyncTimestamp();
    return _shouldSyncBasedOnThrottle(lastSync, const Duration(hours: 1));
  }

  Future<bool> shouldSyncWeekly() async {
    final lastSync = await getLastSyncTimestamp();
    return _shouldSyncBasedOnThrottle(lastSync, const Duration(days: 7));
  }

  Future<void> syncFriends(List<Friend> friends) async {
    if (!_isInitialized || _userId == null) {
      return;
    }

    try {
      final batch = _firestore.batch();
      final friendsCollection = _firestore.collection('users/$_userId/friends');

      for (var friend in friends) {
        final docRef = friendsCollection.doc(friend.contactIdentifier);
        batch.set(docRef, {
          'contactIdentifier': friend.contactIdentifier,
          'notes': friend.notes,
          'frequency': friend.frequency.toJson(),
          'isContactable': friend.isContactable,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (kDebugMode) {
        print('Synced ${friends.length} friends to cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync friends: $e');
      }
    }
  }

  Future<void> syncHangouts(List<Hangout> hangouts) async {
    if (!_isInitialized || _userId == null) {
      return;
    }

    try {
      final batch = _firestore.batch();
      final hangoutsCollection =
          _firestore.collection('users/$_userId/hangouts');

      for (var hangout in hangouts) {
        final docRef = hangoutsCollection.doc(hangout.id);
        batch.set(docRef, {
          'id': hangout.id,
          'notes': hangout.notes,
          'when': Timestamp.fromDate(hangout.when),
          'contacts': hangout.contacts
              .map((c) => {
                    'displayName': c.displayName,
                    'middleName': c.middleName,
                    'givenName': c.givenName,
                    'identifier': c.identifier,
                    'familyName': c.familyName,
                  })
              .toList(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (kDebugMode) {
        print('Synced ${hangouts.length} hangouts to cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync hangouts: $e');
      }
    }
  }

  Future<void> syncSettings(Map<String, dynamic> settings) async {
    if (!_isInitialized || _userId == null) {
      if (kDebugMode) {
        print('CloudSyncService not initialized, skipping settings sync');
      }
      return;
    }

    try {
      await _firestore.collection('users/$_userId/settings').doc('app').set({
        ...settings,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (kDebugMode) {
        print('Synced settings to cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync settings: $e');
      }
    }
  }

  Future<void> syncSnoozeReminders(List<SnoozeReminder> reminders) async {
    if (!_isInitialized || _userId == null) {
      return;
    }

    try {
      final batch = _firestore.batch();
      final remindersCollection =
          _firestore.collection('users/$_userId/snooze_reminders');

      for (var reminder in reminders) {
        final docRef = remindersCollection.doc(reminder.id);
        batch.set(docRef, {
          'id': reminder.id,
          'contactIdentifier': reminder.contactIdentifier,
          'snoozeUntil': Timestamp.fromDate(reminder.snoozeUntil),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (kDebugMode) {
        print('Synced ${reminders.length} snooze reminders to cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync snooze reminders: $e');
      }
    }
  }

  Future<void> syncSyncedEvents(List<String> eventIds) async {
    if (!_isInitialized || _userId == null) {
      return;
    }

    try {
      final batch = _firestore.batch();
      final eventsCollection =
          _firestore.collection('users/$_userId/synced_events');

      for (var eventId in eventIds) {
        final docRef = eventsCollection.doc(eventId);
        batch.set(docRef, {
          'eventId': eventId,
          'syncedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      if (kDebugMode) {
        print('Synced ${eventIds.length} synced events to cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to sync synced events: $e');
      }
    }
  }

  Future<void> performFullSync({bool forceSync = false}) async {
    if (!forceSync) {
      final lastSync = await getLastSyncTimestamp();
      if (lastSync != null) {
        final timeSinceLastSync = DateTime.now().difference(lastSync);
        if (timeSinceLastSync < const Duration(hours: 1)) {
          if (kDebugMode) {
            print(
                'Sync throttled: Last sync was ${timeSinceLastSync.inMinutes} minutes ago');
          }
          return;
        }
      }
    }

    if (_isSyncing) {
      if (kDebugMode) {
        print('Sync already in progress, skipping');
      }
      return;
    }

    _isSyncing = true;

    try {
      final friends = await DBProvider.db.getAllFriends();
      await syncFriends(friends);

      final twoYearsAgo = DateTime.now().subtract(const Duration(days: 730));
      final recentHangouts = (await DBProvider.db.getAllHangouts())
          .where((h) => h.when.isAfter(twoYearsAgo))
          .toList();
      await syncHangouts(recentHangouts);

      final snoozeReminders = await DBProvider.db.getActiveSnoozeReminders();
      await syncSnoozeReminders(snoozeReminders);

      final preferences = await SharedPreferences.getInstance();
      final settings = {
        'theme_color': preferences.getInt('theme_color'),
        'calendar_sync_enabled': preferences.getBool('calendar_sync_enabled'),
        'excluded_contacts':
            preferences.getStringList('excluded_calendar_contacts'),
        'first_time': preferences.getBool('first_time'),
      };
      await syncSettings(settings);

      await _updateLastSyncTimestamp();

      if (kDebugMode) {
        print('Full sync completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to perform full sync: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> restoreFromCloud() async {
    if (!_isInitialized || _userId == null) {
      return;
    }

    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      await _restoreFriends();
      await _restoreHangouts();
      await _restoreSnoozeReminders();
      await _restoreSettings();

      await _updateLastSyncTimestamp();

      if (kDebugMode) {
        print('Restore from cloud completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore from cloud: $e');
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _restoreFriends() async {
    try {
      final snapshot =
          await _firestore.collection('users/$_userId/friends').get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No friends to restore from cloud');
        }
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final friend = Friend(
          contactIdentifier: data['contactIdentifier'] as String,
          notes: data['notes'] as String? ?? '',
          frequency: data['frequency'] != null
              ? Frequency.fromJson(data['frequency'] as Map<String, dynamic>)
              : Frequency.fromType('Weekly'),
          isContactable: data['isContactable'] as bool? ?? true,
        );

        await DBProvider.db.saveFriend(friend);
      }

      if (kDebugMode) {
        print('Restored ${snapshot.docs.length} friends from cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore friends: $e');
      }
    }
  }

  Future<void> _restoreHangouts() async {
    try {
      final snapshot =
          await _firestore.collection('users/$_userId/hangouts').get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No hangouts to restore from cloud');
        }
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final contacts = (data['contacts'] as List<dynamic>?)
                ?.map((c) => EncodableContact(
                      displayName: c['displayName'] as String? ?? '',
                      middleName: c['middleName'] as String? ?? '',
                      givenName: c['givenName'] as String? ?? '',
                      identifier: c['identifier'] as String? ?? '',
                      familyName: c['familyName'] as String? ?? '',
                    ))
                .toList() ??
            [];

        final hangout = Hangout(
          id: data['id'] as String,
          notes: data['notes'] as String? ?? '',
          when: (data['when'] as Timestamp).toDate(),
          contacts: contacts,
        );

        await DBProvider.db.saveHangout(hangout);
      }

      if (kDebugMode) {
        print('Restored ${snapshot.docs.length} hangouts from cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore hangouts: $e');
      }
    }
  }

  Future<void> _restoreSnoozeReminders() async {
    try {
      final snapshot =
          await _firestore.collection('users/$_userId/snooze_reminders').get();

      if (snapshot.docs.isEmpty) {
        if (kDebugMode) {
          print('No snooze reminders to restore from cloud');
        }
        return;
      }

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final reminder = SnoozeReminder(
          id: data['id'] as String,
          contactIdentifier: data['contactIdentifier'] as String,
          snoozeUntil: (data['snoozeUntil'] as Timestamp).toDate(),
        );

        await DBProvider.db.saveSnoozeReminder(reminder);
      }

      if (kDebugMode) {
        print('Restored ${snapshot.docs.length} snooze reminders from cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore snooze reminders: $e');
      }
    }
  }

  Future<void> _restoreSettings() async {
    try {
      final doc = await _firestore
          .collection('users/$_userId/settings')
          .doc('app')
          .get();

      if (!doc.exists) {
        if (kDebugMode) {
          print('No settings to restore from cloud');
        }
        return;
      }

      final data = doc.data()!;
      final preferences = await SharedPreferences.getInstance();

      if (data['theme_color'] != null) {
        await preferences.setInt('theme_color', data['theme_color'] as int);
      }

      if (data['calendar_sync_enabled'] != null) {
        await preferences.setBool(
            'calendar_sync_enabled', data['calendar_sync_enabled'] as bool);
      }

      if (data['excluded_contacts'] != null) {
        await preferences.setStringList('excluded_calendar_contacts',
            List<String>.from(data['excluded_contacts'] as List));
      }

      if (data['first_time'] != null) {
        await preferences.setBool('first_time', data['first_time'] as bool);
      }

      if (kDebugMode) {
        print('Restored settings from cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to restore settings: $e');
      }
    }
  }

  Future<bool> shouldRestoreFromCloud() async {
    if (!_isInitialized || _userId == null) return false;

    try {
      final localFriends = await DBProvider.db.getAllFriends();
      final localHangouts = await DBProvider.db.getAllHangouts();

      if (localFriends.isEmpty && localHangouts.isEmpty) {
        final cloudFriendsSnapshot = await _firestore
            .collection('users/$_userId/friends')
            .limit(1)
            .get();
        final cloudHangoutsSnapshot = await _firestore
            .collection('users/$_userId/hangouts')
            .limit(1)
            .get();

        return cloudFriendsSnapshot.docs.isNotEmpty ||
            cloudHangoutsSnapshot.docs.isNotEmpty;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to check if restore is needed: $e');
      }
      return false;
    }
  }

  Future<void> deleteFriendFromCloud(String contactIdentifier) async {
    if (!_isInitialized || _userId == null) return;

    try {
      await _firestore
          .collection('users/$_userId/friends')
          .doc(contactIdentifier)
          .delete();

      if (kDebugMode) {
        print('Deleted friend $contactIdentifier from cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete friend from cloud: $e');
      }
    }
  }

  Future<void> deleteHangoutFromCloud(String hangoutId) async {
    if (!_isInitialized || _userId == null) return;

    try {
      await _firestore
          .collection('users/$_userId/hangouts')
          .doc(hangoutId)
          .delete();

      if (kDebugMode) {
        print('Deleted hangout $hangoutId from cloud');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete hangout from cloud: $e');
      }
    }
  }
}
