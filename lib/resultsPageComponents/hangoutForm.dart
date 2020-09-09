import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/notificationHelper.dart';
import 'package:friend_builder/schedulingUtils.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:intl/intl.dart';

class HangoutForm extends StatefulWidget {
  final void Function() onSubmit;
  final List<Contact> selectedFriends;
  final Hangout hangout;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  HangoutForm(
      {@required this.onSubmit,
      @required this.selectedFriends,
      this.hangout,
      @required this.flutterLocalNotificationsPlugin});

  @override
  _HangoutFormState createState() => _HangoutFormState(hangout: hangout);
}

class _HangoutFormState extends State<HangoutForm> {
  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  Hangout _data;
  DateTime selectedDate;
  TextEditingController dateController =
      TextEditingController(text: _formatDate(DateTime.now()));

  _HangoutFormState({Hangout hangout}) {
    _data = hangout ?? Hangout(notes: '');
    selectedDate = hangout != null ? hangout.when : DateTime.now();
    dateController = TextEditingController(text: _formatDate(selectedDate));
  }

  static String _formatDate(DateTime date) =>
      DateFormat.yMMMMEEEEd().format(date);

  Future<void> _selectWhen(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2018, 8),
        lastDate: DateTime.now());
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      dateController.text = _formatDate(picked);
    }
    _unfocus();
  }

  void _unfocus() {
    FocusScope.of(context).requestFocus(new FocusNode());
  }

  Future<void> _handleNotificationScheduling(List<Hangout> hangouts) async {
    List<Friend> friends = await Storage.getFriends();
    widget.selectedFriends.forEach((contact) {
      Friend friend = friends.firstWhere(
          (element) => element.contactIdentifier == contact.identifier,
          orElse: () => null);
      if (friend != null && friend.isContactable) {
        List<Hangout> contactHangouts = hangouts
            .where((element) => element.contacts
                .any((hc) => hc.identifier == contact.identifier))
            .toList();
        DateTime latestTime = contactHangouts
            .reduce((value, element) =>
                element.when.compareTo(value.when) > 0 ? element : value)
            .when;
        scheduleNotification(
          widget.flutterLocalNotificationsPlugin,
          contact.identifier.hashCode,
          'Want to chat with ' + contact.displayName + '?',
          "It's been a minute!",
          SchedulingUtils.howLong(latestTime, friend.frequency),
        );
      }
    });
  }

  Future<void> _handleSubmitPress() async {
    if (!_submitting && _formKey.currentState.validate()) {
      setState(() {
        _submitting = true;
      });
      _formKey.currentState.save();
      List<Hangout> hangouts = await Storage().getHangouts();
      if (hangouts != null) {
        var index = hangouts.indexWhere((element) => element.id == _data.id);
        if (index == -1) {
          hangouts.add(_data);
        } else {
          hangouts[index] = _data;
        }
      } else {
        hangouts = [_data];
      }
      Storage().saveHangouts(hangouts).then((_) {
        _handleNotificationScheduling(hangouts);
        widget.onSubmit();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _data.contacts = widget.selectedFriends
          .map((f) => EncodableContact.fromContact(f))
          .toList();
    });

    return Padding(
      padding: EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'When?',
              ),
              controller: dateController,
              onTap: () => _selectWhen(context),
              onChanged: (String value) => {this._data.when = selectedDate},
              onSaved: (String value) => {this._data.when = selectedDate},
            ),
            TextFormField(
              autocorrect: true,
              enableSuggestions: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
              ),
              maxLines: 8,
              initialValue: _data.notes,
              onChanged: (String value) => {this._data.notes = value},
              onSaved: (String value) => {this._data.notes = value},
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Theme.of(context).cardColor,
                    onPressed: _submitting ? null : _handleSubmitPress,
                    child: Text(_submitting ? 'Submitting...' : 'Save'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
