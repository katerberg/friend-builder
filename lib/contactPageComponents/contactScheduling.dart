import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/contactPageComponents/selectionChoiceGroup.dart';
import 'package:friend_builder/data/friend.dart';

const oftenLabel = 'How often do you want to contact this person?';
const notesLabel = 'Notes';

class ContactSchedulingDialog extends StatefulWidget {
  final Contact contact;
  final Friend friend;

  ContactSchedulingDialog({@required this.contact, this.friend});

  @override
  _ContactSchedulingDialogState createState() =>
      _ContactSchedulingDialogState(friend);
}

class _ContactSchedulingDialogState extends State<ContactSchedulingDialog> {
  Map<String, String> selection = {
    oftenLabel: 'Weekly',
    notesLabel: '',
  };

  TextEditingController notesController;

  _ContactSchedulingDialogState(Friend friend) {
    selection[oftenLabel] = friend?.frequency ?? 'Weekly';
    selection[notesLabel] = friend?.notes ?? '';
    notesController = new TextEditingController(text: friend?.notes ?? '');
  }

  void _handleSelectionTap(String groupName, String selectedValue) {
    setState(() {
      selection[groupName] = selectedValue;
    });
  }

  Friend _getFriendToSubmit() {
    if (widget.friend == null) {
      return Friend(
        contactIdentifier: widget.contact.identifier,
        frequency: selection[oftenLabel],
        notes: selection[notesLabel],
        isContactable: true,
      );
    }
    widget.friend.notes = selection[notesLabel];
    widget.friend.frequency = selection[oftenLabel];
    return widget.friend;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
              icon: Icon(Icons.close),
              onPressed: () => Navigator.pop(
                    context,
                    _getFriendToSubmit(),
                  )),
          title: Text(widget.contact?.displayName ?? 'Schedule'),
        ),
        body: SafeArea(
          child: Column(children: [
            ListView(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                children: [
                  SelectionChoiceGroup(
                      choices: ['Weekly', 'Monthly', 'Quarterly', 'Yearly'],
                      onSelect: _handleSelectionTap,
                      selection: selection[oftenLabel],
                      label: oftenLabel),
                  Container(
                    padding: EdgeInsets.all(16),
                    child: TextField(
                      controller: notesController,
                      onChanged: (newVal) =>
                          _handleSelectionTap(notesLabel, newVal),
                      autocorrect: true,
                      enableSuggestions: false,
                      decoration: InputDecoration(labelText: notesLabel),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                    ),
                  ),
                ]),
            Spacer(),
            Container(
              padding: EdgeInsets.only(bottom: 16),
              child: FlatButton(
                child: Text(
                  "I don't want reminders for this person",
                  style: TextStyle(color: Color(0xffdd4444)),
                ),
                onPressed: () => {},
              ),
            ),
          ]),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}
