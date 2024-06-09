import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/main.dart';
import 'package:friend_builder/pages/onboarding/add_friends_screen/friend_adder.dart';
import 'package:friend_builder/pages/onboarding/add_friends_screen/friend_scheduler.dart';

class AddFriendsScreen extends StatefulWidget {
  final void Function() onSubmit;

  const AddFriendsScreen({super.key, required this.onSubmit});

  @override
  State<AddFriendsScreen> createState() => _AddFriendsScreenState();
}

class _AddFriendsScreenState extends State<AddFriendsScreen> {
  bool _isSelectingFriends = true;
  List<Contact> _selectedFriends = [];
  Padding _adderSection(Widget contents) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: contents,
          ),
        ),
      ),
    );
  }

  Widget _selectingInfoCard() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who do you miss?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
              'Less than half of Americans socialize with their friends on a weekly basis. Only 14% get to see friends daily.'),
        ),
        Text(
            '8% of Americans report having no close friends. Let’s beat the numbers.'),
      ],
    );
  }

  Widget _notSelectingInfoCard() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How often do you want to check in?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Text(
              'Great! Now that you know who you want to keep up with, let’s set some accountability goals and schedule reminders.'),
        ),
        Padding(
          padding: EdgeInsets.only(bottom: 16.0),
          child: Text(
              'Checking in can mean whatever you want it to mean: hanging out, a phone call, or a text message. The important thing is that you find a way to stay in touch.'),
        ),
        Text('Don’t worry, you can definitely change this later or add more!')
      ],
    );
  }

  void _handleSelectedFriendsChange(List<Contact> selectedFriends) {
    _selectedFriends = selectedFriends;
  }

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      child: Scaffold(
        backgroundColor: colorScheme.primary,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _adderSection(
                _isSelectingFriends
                    ? _selectingInfoCard()
                    : _notSelectingInfoCard(),
              ),
              Expanded(
                child: ListView(
                  scrollDirection: Axis.vertical,
                  children: [
                    _adderSection(_isSelectingFriends
                        ? FriendAdder(
                            onSelectedFriendsChange:
                                _handleSelectedFriendsChange)
                        : FriendScheduler(
                            selectedFriends: _selectedFriends,
                            flutterLocalNotificationsPlugin:
                                flutterLocalNotificationsPlugin)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _isSelectingFriends
                        ? TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            onPressed: widget.onSubmit,
                            child: const Text('Skip'),
                          )
                        : const SizedBox(),
                    const Spacer(),
                    ElevatedButton(
                        onPressed: () => setState(() {
                              if (_isSelectingFriends) {
                                _isSelectingFriends = false;
                              } else {
                                widget.onSubmit();
                              }
                            }),
                        child: Text(_isSelectingFriends ? 'Next' : 'Done'))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(FocusNode());
      },
    );
  }
}
