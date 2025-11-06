import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/main.dart';
import 'package:friend_builder/missing_permission.dart';
import 'package:friend_builder/shared/selection_choice_group.dart';
import 'package:friend_builder/permissions.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:friend_builder/utils/scheduling.dart';
import 'package:permission_handler/permission_handler.dart';

class FriendScheduler extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final List<Contact> selectedFriends;
  final Storage storage = Storage();

  FriendScheduler(
      {super.key,
      required this.flutterLocalNotificationsPlugin,
      required this.selectedFriends});

  @override
  FriendSchedulerState createState() => FriendSchedulerState();
}

class FriendSchedulerState extends State<FriendScheduler>
    with WidgetsBindingObserver {
  Map<String, String> selection = {};
  bool _hasNotificationsPermissions = false;

  void _setCurrentNotificationPermissions() {
    PermissionsUtils()
        .isMissingPermission(Permission.notification)
        .then((value) => setState(() {
              _hasNotificationsPermissions = !value;
            }));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setCurrentNotificationPermissions();
  }

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    for (var contact in widget.selectedFriends) {
      selection[contact.id] = 'Never';
    }
    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _updateNotification(Contact contact, String selectedValue) {
    if (selectedValue != 'Never') {
      requestIOSPermissions(flutterLocalNotificationsPlugin);
      scheduleNotification(
        widget.flutterLocalNotificationsPlugin,
        contact.id.hashCode,
        'Want to chat with ${contact.displayName}?',
        "It's been a minute!",
        Scheduling.howLong(DateTime.now(), Frequency.fromType(selectedValue)),
      );
    } else {
      cancelNotification(
          widget.flutterLocalNotificationsPlugin, contact.id.hashCode);
    }
  }

  Future<void> _handleSelectionTap(
      Contact contact, String selectedValue) async {
    List<Friend>? friends = await Storage.getFriends();
    if (selectedValue != 'Never') {
      var newFriend = Friend(
        contactIdentifier: contact.id,
        frequency: Frequency.fromType(selectedValue),
        notes: '',
        isContactable: true,
      );
      if (friends != null) {
        var index = friends.indexWhere((element) =>
            element.contactIdentifier == newFriend.contactIdentifier);
        if (index == -1) {
          friends.add(newFriend);
        } else {
          friends[index] = newFriend;
        }
      } else {
        friends = [newFriend];
      }
      widget.storage.saveFriends(friends);
    }

    _updateNotification(contact, selectedValue);
    setState(() {
      selection[contact.id] = selectedValue;
    });
  }

  String _getLabel(Contact contact) {
    return 'How often do you want to contact ${ContactsHelper.getContactName(contact)}?';
  }

  Widget _contactChoices(Contact contact) {
    return SelectionChoiceGroup(
      choices: const [
        'Weekly',
        'Monthly',
        'Quarterly',
        'Yearly',
        'Custom',
        'Never'
      ],
      onSelect: (_, selectedValue) =>
          _handleSelectionTap(contact, selectedValue),
      selection: selection[contact.id] ?? '',
      label: _getLabel((contact)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: FutureBuilder(
          future: Permission.notification.status,
          builder: (context, snapshot) {
            List<Widget> children = [];
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data == PermissionStatus.permanentlyDenied &&
                !_hasNotificationsPermissions) {
              children.add(
                const MissingPermission(
                  isWhite: true,
                  permissionType: 'notifications',
                ),
              );
            } else {
              children.addAll(
                widget.selectedFriends.map(
                  (contact) => _contactChoices(contact),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            );
          }),
    );
  }
}
