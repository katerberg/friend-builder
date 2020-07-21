import 'package:friend_builder/data/encodableContact.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Hangout {
  List<EncodableContact> contacts = [];
  String id = Uuid().v4();
  String where;
  String howMany = 'One on One';
  String medium = 'Face to Face';
  DateTime when = DateTime.now();

  Hangout(
      {this.id,
      this.contacts,
      this.where,
      this.howMany,
      this.medium,
      this.when});

  String dateWithYear() => DateFormat.yMMMMd().format(this.when);
  String dateWithoutYear() => DateFormat.MMMMd().format(this.when);

  factory Hangout.fromJson(Map<String, dynamic> parsedJson) {
    return new Hangout(
      id: parsedJson['id'] ?? Uuid().v4(),
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
      "id": this.id,
      "contacts": this.contacts,
      "where": this.where,
      "howMany": this.howMany,
      "when": this.when.toIso8601String(),
      "medium": this.medium
    };
  }
}
