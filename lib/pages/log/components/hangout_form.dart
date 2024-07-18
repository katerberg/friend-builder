import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/utils/notification_helper.dart';
import 'package:friend_builder/utils/scheduling.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';

class HangoutForm extends StatefulWidget {
  final void Function() onSubmit;
  final List<Contact> selectedFriends;
  final Hangout? hangout;
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const HangoutForm({
    super.key,
    required this.onSubmit,
    required this.selectedFriends,
    required this.flutterLocalNotificationsPlugin,
    this.hangout,
  });

  @override
  HangoutFormState createState() => HangoutFormState();
}

class HangoutFormState extends State<HangoutForm> {
  final _formKey = GlobalKey<FormState>();

  bool _submitting = false;
  Hangout _data = Hangout(
    contacts: [],
    when: DateTime.now(),
    notes: '',
  );
  DateTime selectedDate = DateTime.now();
  TextEditingController dateController =
      TextEditingController(text: Scheduling.formatDate(DateTime.now()));

  @override
  void initState() {
    super.initState();
    if (widget.hangout != null) {
      _data = widget.hangout!;
    }
    selectedDate =
        widget.hangout != null ? widget.hangout!.when : DateTime.now();
    dateController =
        TextEditingController(text: Scheduling.formatDate(selectedDate));
  }

  Future<void> _selectWhen(BuildContext context) async {
    final DateTime picked = await showDatePicker(
            context: context,
            initialDate: selectedDate,
            firstDate: DateTime(2018, 8),
            lastDate: DateTime.now()) ??
        DateTime.now();
    if (picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });

      dateController.text = Scheduling.formatDate(picked);
    }
    _unfocus();
  }

  Future<void> _handleNotificationScheduling(List<Hangout> hangouts) async {
    List<Friend>? friends = await Storage.getFriends();
    for (var contact in widget.selectedFriends) {
      Friend? friend = friends?.firstWhereOrNull(
        (element) => element.contactIdentifier == contact.id,
      );
      if (friend == null || !friend.isContactable) {
        return;
      }
      upsertNotifications(
        widget.flutterLocalNotificationsPlugin,
        hangouts,
        friend,
        contact,
      );
    }
  }

  Future<void> _handleSubmitPress() async {
    if (!_submitting &&
        _formKey.currentState != null &&
        _formKey.currentState!.validate()) {
      setState(() {
        _submitting = true;
      });
      _formKey.currentState!.save();
      List<Hangout>? hangouts = await Storage().getHangouts();
      if (hangouts == null) {
        return;
      }
      var index = hangouts.indexWhere((element) => element.id == _data.id);
      if (index == -1) {
        await Storage().createHangout(_data);
        hangouts.add(_data);
      } else {
        await Storage().updateHangout(_data);
        hangouts[index] = _data;
      }
      await _handleNotificationScheduling(hangouts);
      widget.onSubmit();
    }
  }

  void _handleNotesChange(String value) {
    _data.notes = value;
  }

  void _handleNullableNotesChange(String? value) {
    _handleNotesChange(value ?? '');
  }

  void _unfocus() {
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _handleDateChange(String value) {
    _data.when = selectedDate;
  }

  void _handleNullableDateChange(String? value) {
    _handleDateChange(value ?? '');
  }

  @override
  Widget build(BuildContext context) {
    setState(() {
      _data.contacts = widget.selectedFriends
          .map((f) => EncodableContact.fromContact(f))
          .toList();
    });

    const inputBorder = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.white));

    return Container(
      decoration: BoxDecoration(color: Theme.of(context).primaryColor),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'When?',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                focusedBorder: inputBorder,
                enabledBorder: inputBorder,
              ),
              controller: dateController,
              onTap: () => _selectWhen(context),
              onChanged: _handleDateChange,
              onSaved: _handleNullableDateChange,
            ),
            TextFormField(
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelStyle: TextStyle(color: Colors.white),
                labelText: 'Notes',
                floatingLabelBehavior: FloatingLabelBehavior.never,
                focusedBorder: inputBorder,
                enabledBorder: inputBorder,
              ),
              cursorColor: Colors.white,
              autocorrect: true,
              enableSuggestions: true,
              onFieldSubmitted: (String string) {
                _handleSubmitPress();
              },
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              initialValue: _data.notes,
              onChanged: _handleNotesChange,
              onSaved: _handleNullableNotesChange,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
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
