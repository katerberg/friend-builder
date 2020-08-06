import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/contactPageComponents/selectionChoiceGroup.dart';
import 'package:friend_builder/data/friend.dart';

const oftenLabel = 'How often do you want to contact this person?';
const notesLabel = 'Notes';

class ContactSchedulingDialog extends StatefulWidget {
  final Contact contact;

  ContactSchedulingDialog({@required this.contact});

  @override
  _ContactSchedulingDialogState createState() =>
      _ContactSchedulingDialogState();
}

class _ContactSchedulingDialogState extends State<ContactSchedulingDialog> {
  Map<String, String> selection = {
    oftenLabel: 'Weekly',
    notesLabel: '',
  };

  void _handleSelectionTap(String groupName, String selectedValue) {
    setState(() {
      selection[groupName] = selectedValue;
    });
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
                Friend(
                  contactIdentifier: widget.contact.identifier,
                  frequency: selection[oftenLabel],
                  notes: selection[notesLabel],
                )),
          ),
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
                      onChanged: (String newVal) =>
                          _handleSelectionTap(notesLabel, newVal),
                      autocorrect: true,
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
