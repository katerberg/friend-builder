import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/missing_permission.dart';
import 'package:friend_builder/pages/log/components/friend_selector.dart';
import 'package:friend_builder/pages/log/components/hangout_form.dart';
import 'package:friend_builder/shared/selected_friend_chips.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:permission_handler/permission_handler.dart';

class LogPage extends StatefulWidget {
  final void Function() onSubmit;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final Storage storage = Storage();

  LogPage(
      {super.key,
      required this.onSubmit,
      required this.flutterLocalNotificationsPlugin});

  @override
  LogPageState createState() => LogPageState();
}

class LogPageState extends State<LogPage> {
  List<Contact> _selectedFriends = [];
  List<Hangout> _hangouts = [];
  TextEditingController typeaheadController = TextEditingController(text: '');

  @override
  void initState() {
    _selectedFriends = [];
    super.initState();
    _refreshHangouts();
  }

  void _refreshHangouts() {
    widget.storage.getHangouts().then((hangouts) {
      if (hangouts != null) {
        setState(() {
          _hangouts = hangouts;
        });
      }
    });
  }

  void _setFriend(Contact friend) {
    typeaheadController.text = '';
    setState(() {
      _selectedFriends = [..._selectedFriends, friend];
    });
  }

  void _resetFriend(Contact friendToRemove) {
    setState(() {
      _selectedFriends =
          ContactsHelper.filterContacts(_selectedFriends, friendToRemove);
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> itemsToShow = [
      FriendSelector(
        selectedFriends: _selectedFriends,
        addFriend: _setFriend,
        typeaheadController: typeaheadController,
        previousHangouts: _hangouts,
      ),
      SelectedFriendChips(
        selectedFriends: _selectedFriends,
        onRemoveFriend: _resetFriend,
        isWhite: true,
      )
    ];
    itemsToShow.add(
      FutureBuilder(
        future: Permission.contacts.status,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done ||
              snapshot.data != PermissionStatus.permanentlyDenied) {
            return const SizedBox();
          }
          return const MissingPermission(
            isWhite: false,
          );
        },
      ),
    );
    if (_selectedFriends.isNotEmpty) {
      itemsToShow.add(Row(children: [
        Expanded(
          child: HangoutForm(
            onSubmit: widget.onSubmit,
            selectedFriends: _selectedFriends,
            flutterLocalNotificationsPlugin:
                widget.flutterLocalNotificationsPlugin,
          ),
        ),
      ]));
    }

    return GestureDetector(
      child: Scaffold(
        backgroundColor: Theme.of(context).primaryColor,
        body: SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.only(top: 24, left: 24, right: 24),
            child: ListView(
              shrinkWrap: false,
              scrollDirection: Axis.vertical,
              children: itemsToShow,
            ),
          ),
        ),
      ),
      onTap: () {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      },
    );
  }
}
