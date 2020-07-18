import 'package:flutter/material.dart';
import 'package:friend_builder/storage.dart';

class HangoutForm extends StatefulWidget {
  HangoutForm({Key key}) : super(key: key);

  @override
  _HangoutFormState createState() => _HangoutFormState();
}

class _HangoutFormState extends State<HangoutForm> {
  final _formKey = GlobalKey<FormState>();
  HangoutData _data = new HangoutData();
  DateTime selectedDate = DateTime.now();

  Future<void> _selectWhen(BuildContext context) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: selectedDate,
        firstDate: DateTime(2018, 8),
        lastDate: DateTime(2101));
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
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
          ),
          TextFormField(
              decoration: const InputDecoration(
                labelText: 'Where?',
              ),
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
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'How Long?',
            ),
            onSaved: (String value) {
              this._data.howLong = value;
            },
            validator: (String value) {
              if (value == null ||
                  value == '' ||
                  double.tryParse(value) != null) {
                return null;
              }
              return 'How many minutes?';
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'When?',
            ),
            onTap: () => _selectWhen(context),
            // onSaved: (String value) {
            //   this._data.when = value;
            // },
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
                      List<HangoutData> hangouts =
                          await Storage().getHangouts();
                      if (hangouts != null) {
                        hangouts.add(_data);
                      } else {
                        hangouts = [_data];
                      }
                      Storage().saveHangouts(hangouts);
                      List<HangoutData> hangouts2 =
                          await Storage().getHangouts();
                      print(hangouts2);
                    } else {
                      print('Form is not valid');
                    }
                  },
                  child: Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
