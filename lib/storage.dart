import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:friend_builder/data/hangout.dart';

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/hangouts.txt');
  }

  Future<List<Hangout>> getHangouts() async {
    try {
      final file = await _localFile;

      // Read the file.
      String contents = await file.readAsString();

      var contentList = jsonDecode(contents) as List;
      return contentList.map((hangout) => Hangout.fromJson(hangout)).toList();
    } catch (e) {
      if (e.runtimeType == FileSystemException) {
        return [];
      }
      print('error reading data');
      print(e);
      return null;
    }
  }

  Future<File> saveHangouts(List<Hangout> hangouts) async {
    final file = await _localFile;

    return file.writeAsString(jsonEncode(hangouts));
  }
}
