import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/database.dart';
import 'package:friend_builder/data/snooze_reminder.dart';
import 'package:friend_builder/utils/notification_helper.dart';

class DebugNotificationMenu extends StatelessWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const DebugNotificationMenu({
    super.key,
    required this.flutterLocalNotificationsPlugin,
  });

  Future<void> _showTestNotification(
      BuildContext context, bool isSnoozeReminder) async {
    final contactPermissionService = ContactPermissionService();
    final contactPermission = await contactPermissionService.getContacts();
    final phoneContacts = contactPermission.contacts.toList();

    if (phoneContacts.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No contacts available for test')),
        );
      }
      return;
    }

    final testContact = phoneContacts.first;
    final notificationTime = DateTime.now().add(const Duration(seconds: 5));

    if (isSnoozeReminder) {
      final snoozeReminder = SnoozeReminder(
        contactIdentifier: testContact.id,
        snoozeUntil: notificationTime,
      );
      await DBProvider.db.saveSnoozeReminder(snoozeReminder);

      await scheduleTestNotification(
        flutterLocalNotificationsPlugin,
        'Reminder: Chat with ${testContact.displayName}?',
        "You snoozed this reminder!",
        notificationTime,
        testContact.id,
      );
    } else {
      await scheduleTestNotification(
        flutterLocalNotificationsPlugin,
        'Want to chat with ${testContact.displayName}?',
        "It's been a minute!",
        notificationTime,
        testContact.id,
      );
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              '${isSnoozeReminder ? 'Snooze reminder' : 'Reminder'} scheduled in 5 seconds for ${testContact.displayName}'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.bug_report),
      tooltip: 'Debug notifications',
      onSelected: (value) {
        switch (value) {
          case 'reminder':
            _showTestNotification(context, false);
            break;
          case 'snooze_reminder':
            _showTestNotification(context, true);
            break;
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'reminder',
          child: Row(
            children: [
              Icon(Icons.notifications),
              SizedBox(width: 8),
              Text('Test Reminder'),
            ],
          ),
        ),
        const PopupMenuItem<String>(
          value: 'snooze_reminder',
          child: Row(
            children: [
              Icon(Icons.snooze),
              SizedBox(width: 8),
              Text('Test Snooze Reminder'),
            ],
          ),
        ),
      ],
    );
  }
}
