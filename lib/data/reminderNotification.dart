import 'package:uuid/uuid.dart';

class ReminderNotification {
  final String id;
  final String title;
  final String body;
  final String payload;

  ReminderNotification({
    String id,
    this.title,
    this.body,
    this.payload,
  }) : this.id = id ?? Uuid().v4();
}
