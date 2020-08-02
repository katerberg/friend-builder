import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/contactPageComponents/selectionChoiceGroup.dart';
import 'package:friend_builder/data/friend.dart';

class ContactSchedulingDialog extends StatefulWidget {
  final Contact contact;
  final void Function() onSave;

  ContactSchedulingDialog({@required this.contact, @required this.onSave});

  @override
  _ContactSchedulingDialogState createState() =>
      _ContactSchedulingDialogState();
}

class _ContactSchedulingDialogState extends State<ContactSchedulingDialog> {
  Map<String, String> selection = {
    'How often do you want to contact this person?': 'Weekly',
    'How do you want to stay in contact?': 'Any way',
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
            onPressed: () =>
                Navigator.pop(context, Friend(contactIdentifier: '4234')),
          ),
          title: Text(widget.contact?.displayName ?? 'Schedule'),
        ),
        body: SafeArea(
          child: ListView(
              shrinkWrap: true,
              scrollDirection: Axis.vertical,
              children: [
                SelectionChoiceGroup(
                    choices: ['Not often', 'Weekly', 'Monthly', 'Quarterly'],
                    onSelect: _handleSelectionTap,
                    selection: selection[
                        'How often do you want to contact this person?'],
                    label: 'How often do you want to contact this person?'),
                SelectionChoiceGroup(
                    choices: ['Any way', 'Face to face', 'Text', 'Call'],
                    onSelect: _handleSelectionTap,
                    selection: selection['How do you want to stay in contact?'],
                    label: 'How do you want to stay in contact?'),
              ]),
        ),
      ),
      onTap: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
  }
}
