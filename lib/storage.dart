import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/services/cloud_sync_service.dart';

class Storage {
  Future<List<Hangout>?> getHangouts() async {
    var dbHangouts = await DBProvider.db.getAllHangouts();
    return dbHangouts;
  }

  Future<List<Hangout>> getHangoutsPaginated({
    required int limit,
    required int offset,
    bool filterOldHangouts = true,
  }) async {
    return DBProvider.db.getHangoutsPaginated(
      limit: limit,
      offset: offset,
      filterOldHangouts: filterOldHangouts,
    );
  }

  Future updateHangout(Hangout hangout) async {
    final result = await DBProvider.db.saveHangout(hangout);
    CloudSyncService().syncHangouts([hangout]);
    return result;
  }

  Future createHangout(Hangout hangout) async {
    final result = await DBProvider.db.saveHangout(hangout);
    CloudSyncService().syncHangouts([hangout]);
    return result;
  }

  Future deleteHangout(Hangout hangout) async {
    final result = await DBProvider.db.deleteHangout(hangout);
    CloudSyncService().deleteHangoutFromCloud(hangout.id);
    return result;
  }

  static Future<List<Friend>?> getFriends() async {
    var dbFriends = await DBProvider.db.getAllFriends();
    return dbFriends;
  }

  Future deleteFriend(Friend friend) async {
    await DBProvider.db
        .deleteSnoozeRemindersForContact(friend.contactIdentifier);
    final result = await DBProvider.db.deleteFriend(friend);
    CloudSyncService().deleteFriendFromCloud(friend.contactIdentifier);
    return result;
  }

  Future saveFriends(List<Friend> friends) async {
    var futureMap = friends.map((friend) {
      return DBProvider.db.saveFriend(friend);
    });
    final result = await Future.wait(futureMap);
    CloudSyncService().syncFriends(friends);
    return result;
  }
}
