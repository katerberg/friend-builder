import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';

class Storage {
  Future<List<Hangout>> getHangouts() async {
    var dbHangouts = await DBProvider.db.getAllHangouts();
    return dbHangouts;
  }

  Future updateHangout(Hangout hangout) async {
    return DBProvider.db.saveHangout(hangout);
  }

  Future createHangout(Hangout hangout) async {
    return DBProvider.db.saveHangout(hangout);
  }

  Future deleteHangout(Hangout hangout) async {
    return DBProvider.db.deleteHangout(hangout);
  }

  static Future<List<Friend>> getFriends() async {
    var dbFriends = await DBProvider.db.getAllFriends();
    return dbFriends;
  }

  Future saveFriends(List<Friend> friends) async {
    var futureMap = friends.map((friend) {
      return DBProvider.db.saveFriend(friend);
    });
    return Future.wait(futureMap);
  }
}
