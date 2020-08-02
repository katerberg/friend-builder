import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/contactPageComponents/selectionChoiceChip.dart';
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
  String selection = 'Weekly';

  void _handleSelectionTap(String selectedValue) {
    setState(() {
      selection = selectedValue;
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
                Container(
                  margin: EdgeInsets.fromLTRB(16, 16, 0, 8),
                  child: Text(
                    'How often do you want to contact this person?',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 8),
                  child: Wrap(
                    alignment: WrapAlignment.spaceEvenly,
                    spacing: 8.0, // gap between adjacent chips
                    runSpacing: 4.0, // gap between lines
                    children: [
                      SelectionChoiceChip(
                          label: 'Not often',
                          selection: selection,
                          onTap: _handleSelectionTap),
                      SelectionChoiceChip(
                          label: 'Weekly',
                          selection: selection,
                          onTap: _handleSelectionTap),
                      SelectionChoiceChip(
                          label: 'Monthly',
                          selection: selection,
                          onTap: _handleSelectionTap),
                      SelectionChoiceChip(
                          label: 'Quarterly',
                          selection: selection,
                          onTap: _handleSelectionTap),
                    ],
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
