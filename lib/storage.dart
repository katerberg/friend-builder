import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HangoutData {
  String where;
  String howMany = 'One on One';
  String medium = 'Face to Face';
  DateTime when = DateTime.now();

  HangoutData({this.where, this.howMany, this.medium, this.when});

  factory HangoutData.fromJson(Map<String, dynamic> parsedJson) {
    return new HangoutData(
      where: parsedJson['where'] ?? "",
      howMany: parsedJson['howMany'] ?? "One on One",
      medium: parsedJson['medium'] ?? "Face to Face",
      when: DateTime.parse(parsedJson['when']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "where": this.where,
      "howMany": this.howMany,
      "when": this.when.toIso8601String(),
      "medium": this.medium
    };
  }
}

class Storage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();

    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/hangouts.txt');
  }

  Future<List<HangoutData>> getHangouts() async {
    try {
      final file = await _localFile;

      // Read the file.
      String contents = await file.readAsString();
      print('reading');
      print(contents);

      var contentList = jsonDecode(contents) as List;
      return contentList
          .map((hangout) => HangoutData.fromJson(hangout))
          .toList();
    } catch (e) {
      if (e.runtimeType == FileSystemException) {
        return [];
      }
      print('error reading data');
      print(e);
      return null;
    }
  }

  Future<File> saveHangouts(List<HangoutData> hangouts) async {
    final file = await _localFile;

    return file.writeAsString(jsonEncode(hangouts));
  }
}
