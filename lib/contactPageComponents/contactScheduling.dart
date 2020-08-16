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
  bool isContactable;

  TextEditingController notesController;

  _ContactSchedulingDialogState(Friend friend) {
    selection[oftenLabel] = friend?.frequency ?? 'Weekly';
    selection[notesLabel] = friend?.notes ?? '';
    isContactable = friend?.isContactable ?? true;
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
        isContactable: false,
      );
    }
    widget.friend.notes = selection[notesLabel];
    widget.friend.frequency = selection[oftenLabel];
    widget.friend.isContactable = isContactable;
    return widget.friend;
  }

  void _closePage() {
    Navigator.pop(
      context,
      _getFriendToSubmit(),
    );
  }

  MaterialButton _getContactButton() {
    var onPressed = () {
      setState(() {
        isContactable = !isContactable;
      });
      _closePage();
    };
    if (widget.friend?.isContactable ?? false) {
      return FlatButton(
        child: Text(
          "I don't want reminders for this person",
          style: TextStyle(color: Color(0xffdd4444)),
        ),
        onPressed: onPressed,
      );
    }
    return FlatButton(
      color: Colors.blue,
      textColor: Colors.white,
      splashColor: Colors.blueAccent,
      child: Text('I want notifications for this person',
          style: TextStyle(color: Colors.white)),
      onPressed: onPressed,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: Icon(Icons.close), onPressed: _closePage),
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
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ]),
            Spacer(),
            Container(
              padding: EdgeInsets.only(bottom: 16),
              child: _getContactButton(),
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
