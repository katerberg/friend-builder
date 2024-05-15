import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/hangout.dart';
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

  void _updateV1ToV2(Batch batch) {
    _createContactsTable(batch);
    _createHangoutsTable(batch);
  }

  _initDB() async {
    return await openDatabase(
      join(await getDatabasesPath(), 'friend-builder.db'),
      onCreate: (Database db, int version) async {
        var batch = db.batch();
        _createFriendsTable(batch);
        _createContactsTable(batch);
        _createHangoutsTable(batch);
        await batch.commit();
      },
      onConfigure: _onConfigure,
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        var batch = db.batch();
        if (oldVersion == 1) {
          _updateV1ToV2(batch);
        }
        await batch.commit();
      },
      onDowngrade: onDatabaseDowngradeDelete,
      version: 2,
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
    var raw = await db.rawInsert(
        "INSERT INTO friends (contactIdentifier,frequency,notes,isContactable)"
        " VALUES (?,?,?,?)",
        [
          friend.contactIdentifier,
          friend.frequency,
          friend.notes,
          friend.isContactable ? 1 : 0
        ]);
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
    return db.rawInsert(
        "INSERT INTO contacts (displayName,familyName,middleName,givenName,identifier,hangoutId,avatar)"
        " VALUES (?,?,?,?,?,?,?,?)",
        [
          c.displayName,
          c.familyName,
          c.middleName,
          c.givenName,
          c.identifier,
          hangout.id,
          c.avatar
        ]);
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

    // final db = await database;
    // var res = await db.update("friends", friend.toMap(),
    //     where: "contactIdentifier = ?", whereArgs: [friend.contactIdentifier]);
    // return res;
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
}
