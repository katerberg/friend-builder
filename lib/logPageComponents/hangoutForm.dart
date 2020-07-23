import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/encodableContact.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:intl/intl.dart';

class HangoutForm extends StatefulWidget {
  final void Function() onSubmit;
  final List<Contact> selectedFriends;
  final Hangout hangout;

  HangoutForm(
      {Key key,
      @required this.onSubmit,
      @required this.selectedFriends,
      this.hangout})
      : super(key: key);

  @override
  _HangoutFormState createState() => _HangoutFormState(hangout: hangout);
}

class _HangoutFormState extends State<HangoutForm> {
  final _formKey = GlobalKey<FormState>();

  Hangout _data;
  DateTime selectedDate;
  TextEditingController dateController =
      TextEditingController(text: _formatDate(DateTime.now()));

  _HangoutFormState({Hangout hangout}) {
    _data = hangout ?? Hangout();
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
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'How did you see them?'),
              items: <String>['Face to Face', 'Chat', 'Phone', 'Video', 'Mail']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String _) => {},
              onSaved: (String newValue) => {this._data.medium = newValue},
              value: _data.medium ?? 'Face to Face',
            ),
            TextFormField(
                autocorrect: true,
                enableSuggestions: true,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Where?',
                ),
                initialValue: _data.where,
                onSaved: (String value) {
                  this._data.where = value;
                }),
            DropdownButtonFormField(
              decoration: InputDecoration(labelText: 'How many people?'),
              items: <String>['One on One', 'Small Group', 'Party']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String _) => {},
              onSaved: (String newValue) => {this._data.howMany = newValue},
              value: _data.howMany ?? 'One on One',
            ),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'When?',
              ),
              controller: dateController,
              onTap: () => _selectWhen(context),
              onSaved: (String value) {
                this._data.when = selectedDate;
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  RaisedButton(
                    color: Theme.of(context).primaryColor,
                    textColor: Theme.of(context).cardColor,
                    onPressed: () async {
                      if (_formKey.currentState.validate()) {
                        _formKey.currentState.save();
                        List<Hangout> hangouts = await Storage().getHangouts();
                        if (hangouts != null) {
                          var index = hangouts
                              .indexWhere((element) => element.id == _data.id);
                          if (index == -1) {
                            hangouts.add(_data);
                          } else {
                            hangouts[index] = _data;
                          }
                        } else {
                          hangouts = [_data];
                        }
                        Storage().saveHangouts(hangouts);
                        widget.onSubmit();
                      } else {
                        print('Form is not valid');
                      }
                    },
                    child: Text('Save'),
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
