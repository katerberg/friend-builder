import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/logPageComponents/hangoutForm.dart';

class EditDialog extends StatelessWidget {
  final List<Contact> selectedFriends;
  final Hangout hangout;
  final void Function() onSubmit;

  EditDialog(
      {@required List<Contact> selectedFriends,
      @required Hangout hangout,
      @required void Function() onSubmit})
      : this.selectedFriends = selectedFriends,
        this.hangout = hangout,
        this.onSubmit = onSubmit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit'),
        ),
        body: SafeArea(
          child: ListView(
            shrinkWrap: true,
            scrollDirection: Axis.vertical,
            children: [
              HangoutForm(
                  hangout: hangout,
                  selectedFriends: this.selectedFriends,
                  onSubmit: () {
                    onSubmit();
                    Navigator.pop(context);
                  })
            ],
          ),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}
