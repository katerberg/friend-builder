import 'package:friend_builder/data/encodableContact.dart';
import 'package:intl/intl.dart';

class Hangout {
  List<EncodableContact> contacts = [];
  String where;
  String howMany = 'One on One';
  String medium = 'Face to Face';
  DateTime when = DateTime.now();

  Hangout({this.contacts, this.where, this.howMany, this.medium, this.when});

  String formattedDate() => DateFormat.yMMMMd().format(this.when);

  factory Hangout.fromJson(Map<String, dynamic> parsedJson) {
    return new Hangout(
      contacts: (parsedJson['contacts'] as List)
          .map((c) => EncodableContact.fromJson(c))
          .toList(),
      where: parsedJson['where'] ?? "",
      howMany: parsedJson['howMany'] ?? "One on One",
      medium: parsedJson['medium'] ?? "Face to Face",
      when: DateTime.parse(parsedJson['when']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "contacts": this.contacts,
      "where": this.where,
      "howMany": this.howMany,
      "when": this.when.toIso8601String(),
      "medium": this.medium
    };
  }
}
