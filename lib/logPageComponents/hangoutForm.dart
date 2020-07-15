import 'package:flutter/material.dart';

class _HangoutData {
  String where;
  String howMany = 'One on One';
  String medium = 'Face to Face';
  String when;
  String howLong;
}

class HangoutForm extends StatefulWidget {
  HangoutForm({Key key}) : super(key: key);

  @override
  _HangoutFormState createState() => _HangoutFormState();
}

class _HangoutFormState extends State<HangoutForm> {
  final _formKey = GlobalKey<FormState>();
  _HangoutData _data = new _HangoutData();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DropdownButtonFormField(
            decoration: InputDecoration(labelText: 'How did you see them?'),
            items: <String>['Face to Face', 'Chat', 'Phone', 'Video']
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
                  double.tryParse(value) == null) {
                return 'How many minutes?';
              }
              return null;
            },
          ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'When?',
            ),
            onSaved: (String value) {
              this._data.when = value;
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
                  onPressed: () {
                    if (_formKey.currentState.validate()) {
                      print('Form is valid');
                      // Process data.
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
