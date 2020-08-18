import 'package:friend_builder/data/encodableContact.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class Hangout {
  List<EncodableContact> contacts = [];
  final String id;
  String where = '';
  String howMany = 'One on one';
  String medium = 'Face to face';
  DateTime when = DateTime.now();

  Hangout(
      {String id,
      this.contacts,
      this.where,
      this.howMany,
      this.medium,
      this.when})
      : this.id = id ?? Uuid().v4();

  String dateWithYear() => DateFormat.yMMMMd().format(this.when);
  String dateWithoutYear() => DateFormat.MMMMd().format(this.when);

  static String _getHowMany(String howMany) {
    switch (howMany) {
      case 'Small Group':
        return 'Small group';
      case 'One on One':
        return 'One on one';
      default:
        return howMany;
    }
  }

  static String _getMedium(String medium) {
    switch (medium) {
      case 'Face to Face':
        return 'Face to face';
      case 'Mail':
        return 'Text';
      case 'Phone':
      case 'Video':
        return 'Call';
      default:
        return medium;
    }
  }

  bool hasContact(Contact contact) {
    return this
        .contacts
        .any((element) => element.identifier == contact.identifier);
  }

  factory Hangout.fromJson(Map<String, dynamic> parsedJson) {
    return new Hangout(
      id: parsedJson['id'] ?? Uuid().v4(),
      contacts: (parsedJson['contacts'] as List)
          .map((c) => EncodableContact.fromJson(c))
          .toList(),
      where: parsedJson['where'] ?? "",
      howMany: _getHowMany(parsedJson['howMany']) ?? "One on one",
      medium: _getMedium(parsedJson['medium']) ?? "Face to face",
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
