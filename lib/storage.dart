import 'package:friend_builder/data/calendar_year_stats.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/top_friend_row.dart';

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
    return DBProvider.db.saveHangout(hangout);
  }

  Future createHangout(Hangout hangout) async {
    return DBProvider.db.saveHangout(hangout);
  }

  Future deleteHangout(Hangout hangout) async {
    return DBProvider.db.deleteHangout(hangout);
  }

  Future<List<TopFriendRow>> getTopFriendsForCalendarYear({int limit = 5}) {
    return DBProvider.db.getTopFriendsForCalendarYear(limit: limit);
  }

  Future<int> getHangoutCountForCalendarYear() {
    return DBProvider.db.getHangoutCountForCalendarYear();
  }

  Future<List<int>> getHangoutCountByMonthForCalendarYear() {
    return DBProvider.db.getHangoutCountByMonthForCalendarYear();
  }

  Future<GroupSoloCounts> getGroupVsSoloCountsForCalendarYear() {
    return DBProvider.db.getGroupVsSoloCountsForCalendarYear();
  }

  Future<List<int>> getHangoutCountByWeekdayForCalendarYear() {
    return DBProvider.db.getHangoutCountByWeekdayForCalendarYear();
  }

  static Future<List<Friend>?> getFriends() async {
    var dbFriends = await DBProvider.db.getAllFriends();
    return dbFriends;
  }

  Future deleteFriend(Friend friend) async {
    await DBProvider.db
        .deleteSnoozeRemindersForContact(friend.contactIdentifier);
    return DBProvider.db.deleteFriend(friend);
  }

  Future saveFriends(List<Friend> friends) async {
    var futureMap = friends.map((friend) {
      return DBProvider.db.saveFriend(friend);
    });
    return Future.wait(futureMap);
  }
}
