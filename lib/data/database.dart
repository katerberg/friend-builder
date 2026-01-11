import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/snooze_reminder.dart';
import 'package:sqflite/sqflite.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:path/path.dart';

class DBProvider {
  DBProvider._();
  static final DBProvider db = DBProvider._();
  static Database? _database;

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  void _createHangoutsTable(batch) {
    batch.execute('DROP TABLE IF EXISTS hangouts');
    batch.execute('''CREATE TABLE hangouts (
    id TEXT PRIMARY KEY,
    notes TEXT,
    whenOccurred TEXT
)''');
    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_hangouts_when ON hangouts(whenOccurred)');
  }

  void _createContactsTable(batch) {
    batch.execute('DROP TABLE IF EXISTS contacts');
    batch.execute('''CREATE TABLE contacts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    avatar TEXT,
    displayName TEXT,
    middleName TEXT,
    givenName TEXT,
    hangoutId TEXT,
    identifier TEXT,
    familyName TEXT,
    FOREIGN KEY (hangoutId) REFERENCES hangouts(id) ON DELETE CASCADE
)''');
  }

  void _createFriendsTable(batch) {
    batch.execute('DROP TABLE IF EXISTS friends');
    batch.execute(
      "CREATE TABLE friends(contactIdentifier TEXT PRIMARY KEY, frequency TEXT, notes TEXT, isContactable INTEGER)",
    );
  }

  void _createSyncedEventsTable(batch) {
    batch.execute('DROP TABLE IF EXISTS synced_events');
    batch.execute('''CREATE TABLE synced_events (
    eventId TEXT PRIMARY KEY,
    syncedAt TEXT
)''');
  }

  void _createSnoozeRemindersTable(batch) {
    batch.execute('DROP TABLE IF EXISTS snooze_reminders');
    batch.execute('''CREATE TABLE snooze_reminders (
    id TEXT PRIMARY KEY,
    contactIdentifier TEXT,
    snoozeUntil TEXT
)''');
    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_snooze_reminders_contact ON snooze_reminders(contactIdentifier)');
  }

  void _updateV1ToV2(Batch batch) {
    _createContactsTable(batch);
    _createHangoutsTable(batch);
  }

  void _updateV2ToV3(Batch batch) {
    batch.execute(
        'CREATE INDEX IF NOT EXISTS idx_hangouts_when ON hangouts(whenOccurred)');
  }

  void _updateV3ToV4(Batch batch) {
    _createSyncedEventsTable(batch);
  }

  void _updateV4ToV5(Batch batch) {
    _createSnoozeRemindersTable(batch);
  }

  _initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'friend-builder.db'),
      onCreate: (Database db, int version) async {
        var batch = db.batch();
        _createFriendsTable(batch);
        _createContactsTable(batch);
        _createHangoutsTable(batch);
        _createSyncedEventsTable(batch);
        _createSnoozeRemindersTable(batch);
        await batch.commit();
      },
      onConfigure: _onConfigure,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        var batch = db.batch();
        if (oldVersion < 2) {
          _updateV1ToV2(batch);
        }
        if (oldVersion < 3) {
          _updateV2ToV3(batch);
        }
        if (oldVersion < 4) {
          _updateV3ToV4(batch);
        }
        if (oldVersion < 5) {
          _updateV4ToV5(batch);
        }
        await batch.commit();
      },
      onDowngrade: onDatabaseDowngradeDelete,
      version: 5,
    );
  }

  Future<Database> get database async {
    if (_database != null) return _database!;

    // if _database is null we instantiate it
    _database = await _initDB();
    return _database!;
  }

  Future<int> saveFriend(Friend friend) async {
    final db = await database;
    if ((await db.query('friends',
            where: 'contactIdentifier = ?',
            whereArgs: [friend.contactIdentifier]))
        .isEmpty) {
      return _insertFriend(friend);
    } else {
      return _updateFriend(friend);
    }
  }

  Future<int> _insertFriend(Friend friend) async {
    final db = await database;
    var raw = await db.insert("friends", friend.toMap());
    return raw;
  }

  Future<int> _updateFriend(Friend friend) async {
    final db = await database;
    var res = await db.update("friends", friend.toMap(),
        where: "contactIdentifier = ?", whereArgs: [friend.contactIdentifier]);
    return res;
  }

  Future<List<Friend>> getAllFriends() async {
    final db = await database;
    var res = await db.query("friends");
    List<Friend> list =
        res.isNotEmpty ? res.map((c) => Friend.fromMap(c)).toList() : [];
    return list;
  }

  Future<int> deleteFriend(Friend friend) async {
    final db = await database;
    return db.delete('friends',
        where: 'contactIdentifier = ?', whereArgs: [friend.contactIdentifier]);
  }

  Future<int> deleteHangout(Hangout hangout) async {
    final db = await database;
    return db.delete('hangouts', where: 'id = ?', whereArgs: [hangout.id]);
  }

  Future saveHangout(Hangout hangout) async {
    final db = await database;
    if ((await db.query('hangouts', where: 'id = ?', whereArgs: [hangout.id]))
        .isEmpty) {
      return _insertHangout(hangout);
    } else {
      return _updateHangout(hangout);
    }
  }

  Future _insertContact(EncodableContact c, Hangout hangout) async {
    final db = await database;
    List<Object?> variables = [
      c.displayName,
      c.familyName,
      c.middleName,
      c.givenName,
      c.identifier,
      hangout.id,
      c.avatar
    ];
    return db.rawInsert(
        "INSERT INTO contacts (displayName,familyName,middleName,givenName,identifier,hangoutId,avatar)"
        " VALUES (?,?,?,?,?,?,?)",
        variables);
  }

  Future _updateContact(EncodableContact c, Hangout hangout) async {
    final db = await database;
    return db.rawUpdate(
        "UPDATE contacts SET displayName = ?, familyName = ?, middleName = ?, givenName = ?, identifier = ?, hangoutId = ?, avatar = ?"
        "WHERE hangoutId = ? AND identifier = ?",
        [
          c.displayName,
          c.familyName,
          c.middleName,
          c.givenName,
          c.identifier,
          hangout.id,
          c.avatar,
          hangout.id,
          c.identifier,
        ]);
  }

  Future<int> _insertHangout(Hangout hangout) async {
    final db = await database;
    var raw = await db.rawInsert(
        "INSERT INTO hangouts (id,notes,whenOccurred)"
        " VALUES (?,?,?)",
        [hangout.id, hangout.notes, hangout.when.toIso8601String()]);
    var promises = hangout.contacts.map((c) => _insertContact(c, hangout));
    await Future.wait(promises);
    return raw;
  }

  Future _updateHangout(Hangout hangout) async {
    final db = await database;
    var hangoutPromise = db.rawUpdate(
        'UPDATE hangouts SET notes = ?, whenOccurred = ? WHERE id = ?',
        [hangout.notes, hangout.when.toIso8601String(), hangout.id]);
    var previousContacts = await db
        .query('contacts', where: 'hangoutId = ?', whereArgs: [hangout.id]);
    var deletionPromises = previousContacts.map((previousContact) {
      if (hangout.contacts.any((newContact) =>
          newContact.identifier == previousContact['identifier'])) {
        return Future.value(null);
      } else {
        return db.delete('contacts',
            where: 'id = ?', whereArgs: [previousContact['id']]);
      }
    });
    var contactPromises = hangout.contacts.map((c) async {
      if ((await db.query('contacts',
              where: 'hangoutId = ? AND identifier = ?',
              whereArgs: [hangout.id, c.identifier]))
          .isNotEmpty) {
        return _updateContact(c, hangout);
      } else {
        return _insertContact(c, hangout);
      }
    });
    return Future.wait(
        [...contactPromises, ...deletionPromises, hangoutPromise]);
  }

  Future<List<Hangout>> getAllHangouts() async {
    final db = await database;
    var dbHangouts = await db.query("hangouts");
    var dbContacts = await db.query("contacts");
    List<Hangout> hangoutList = dbHangouts.isNotEmpty
        ? dbHangouts.map((c) => Hangout.fromMap(c)).toList()
        : [];
    if (dbContacts.isNotEmpty) {
      for (var c in dbContacts) {
        var hangout =
            hangoutList.firstWhere((element) => element.id == c['hangoutId']);
        hangout.contacts.add(EncodableContact.fromMap(c));
      }
    }
    return hangoutList;
  }

  Future<List<Hangout>> getHangoutsPaginated({
    required int limit,
    required int offset,
    bool filterOldHangouts = true,
  }) async {
    final db = await database;

    final oneYearAgo =
        DateTime.now().subtract(const Duration(days: 365)).toIso8601String();

    var dbHangouts = await db.query(
      "hangouts",
      where: filterOldHangouts ? "whenOccurred >= ?" : null,
      whereArgs: filterOldHangouts ? [oneYearAgo] : null,
      orderBy: "whenOccurred DESC",
      limit: limit,
      offset: offset,
    );

    if (dbHangouts.isEmpty) {
      return [];
    }

    var hangoutIds = dbHangouts.map((h) => h['id'] as String).toList();

    var dbContacts = await db.query(
      "contacts",
      where: "hangoutId IN (${List.filled(hangoutIds.length, '?').join(',')})",
      whereArgs: hangoutIds,
    );

    List<Hangout> hangoutList =
        dbHangouts.map((c) => Hangout.fromMap(c)).toList();

    if (dbContacts.isNotEmpty) {
      for (var c in dbContacts) {
        var hangout =
            hangoutList.firstWhere((element) => element.id == c['hangoutId']);
        hangout.contacts.add(EncodableContact.fromMap(c));
      }
    }

    return hangoutList;
  }

  Future<bool> isEventSynced(String eventId) async {
    final db = await database;
    var result = await db.query(
      'synced_events',
      where: 'eventId = ?',
      whereArgs: [eventId],
    );
    return result.isNotEmpty;
  }

  Future<void> markEventAsSynced(String eventId) async {
    final db = await database;
    await db.insert(
      'synced_events',
      {
        'eventId': eventId,
        'syncedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveSnoozeReminder(SnoozeReminder reminder) async {
    final db = await database;
    await db.insert(
      'snooze_reminders',
      reminder.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<SnoozeReminder>> getActiveSnoozeReminders() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final result = await db.query(
      'snooze_reminders',
      where: 'snoozeUntil > ?',
      whereArgs: [now],
    );
    return result.map((map) => SnoozeReminder.fromMap(map)).toList();
  }

  Future<void> deleteSnoozeRemindersForContact(String contactIdentifier) async {
    final db = await database;
    await db.delete(
      'snooze_reminders',
      where: 'contactIdentifier = ?',
      whereArgs: [contactIdentifier],
    );
  }

  Future<void> deleteExpiredSnoozeReminders() async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.delete(
      'snooze_reminders',
      where: 'snoozeUntil <= ?',
      whereArgs: [now],
    );
  }
}
