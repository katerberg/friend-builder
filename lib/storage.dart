import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/data/friend.dart';

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localHangoutsFile async {
    final path = await _localPath;
    return File('$path/hangouts.txt');
  }

  Future<List<Hangout>> getHangouts() async {
    try {
      final file = await _localHangoutsFile;

      // Read the file.
      String contents = await file.readAsString();

      var contentList = jsonDecode(contents) as List;
      return contentList.map((hangout) => Hangout.fromJson(hangout)).toList();
    } catch (e) {
      if (e.runtimeType == FileSystemException) {
        return [];
      }
      print('error reading hangout data');
      print(e);
      return null;
    }
  }

  Future<File> saveHangouts(List<Hangout> hangouts) async {
    final file = await _localHangoutsFile;

    return file.writeAsString(jsonEncode(hangouts));
  }

  Future<File> get _localFriendsFile async {
    final path = await _localPath;
    return File('$path/friends.txt');
  }

  Future<List<Friend>> getFriends() async {
    try {
      final file = await _localHangoutsFile;
      String contents = await file.readAsString();

      var contentList = jsonDecode(contents) as List;
      return contentList.map((friend) => Friend.fromJson(friend)).toList();
    } catch (e) {
      if (e.runtimeType == FileSystemException) {
        return [];
      }
      print('error reading friend data');
      print(e);
      return null;
    }
  }

  Future<File> saveFriends(List<Friend> friends) async {
    final file = await _localFriendsFile;

    return file.writeAsString(jsonEncode(friends));
  }
}
