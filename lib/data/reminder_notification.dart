import 'package:uuid/uuid.dart';

class ReminderNotification {
  final String id;
  final String title;
  final String body;
  final String payload;

  ReminderNotification({
    String? id,
    required this.title,
    required this.body,
    required this.payload,
  }) : id = id ?? const Uuid().v4();
}
