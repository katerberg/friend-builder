import 'package:flutter/material.dart';
import 'package:friend_builder/contacts.dart';
import 'package:friend_builder/pages/friends/components/selection_choice_group.dart';
import 'package:friend_builder/data/friend.dart';

const oftenLabel = 'How often do you want to contact this person?';
const notesLabel = 'Notes';

class ContactSchedulingDialog extends StatefulWidget {
  final Contact? contact;
  final Friend? friend;

  const ContactSchedulingDialog({super.key, this.contact, this.friend});

  @override
  ContactSchedulingDialogState createState() => ContactSchedulingDialogState();
}

class ContactSchedulingDialogState extends State<ContactSchedulingDialog> {
  Map<String, String> selection = {
    oftenLabel: 'Weekly',
    notesLabel: '',
  };
  bool isContactable = false;

  TextEditingController notesController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    if (widget.friend == null && widget.contact == null) {
      throw ArgumentError('contact and friend cannot both be null');
    }
    selection[oftenLabel] = widget.friend?.frequency ?? 'Weekly';
    selection[notesLabel] = widget.friend?.notes ?? '';
    isContactable = widget.friend?.isContactable ?? false;
    notesController = TextEditingController(text: selection[notesLabel]);
  }

  Friend _getFriendToSubmit() {
    if (widget.friend != null) {
      widget.friend!.notes = selection[notesLabel] ?? '';
      widget.friend!.frequency = selection[oftenLabel] ?? 'Weekly';
      widget.friend!.isContactable = isContactable;
      return widget.friend!;
    }
    return Friend(
      contactIdentifier: widget.contact!.id,
      frequency: selection[oftenLabel] ?? 'Weekly',
      notes: selection[notesLabel] ?? '',
      isContactable: isContactable,
    );
  }

  void _closePage() {
    if (mounted) {
      Navigator.pop(context, _getFriendToSubmit());
    }
  }

  void _handleSelectionTap(String groupName, String selectedValue) {
    setState(() {
      selection[groupName] = selectedValue;
    });
  }

  ButtonStyleButton _getContactButton() {
    onPressed() {
      setState(() {
        isContactable = !isContactable;
      });
      _closePage();
    }

    if (widget.friend?.isContactable == true) {
      return TextButton(
        onPressed: onPressed,
        child: const Text(
          "I don't want reminders for this person",
          style: TextStyle(color: Color(0xffdd4444)),
        ),
      );
    }
    return TextButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.blue),
        foregroundColor: MaterialStateProperty.all(Colors.white),
      ),
      onPressed: onPressed,
      child: const Text('I want notifications for this person',
          style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Scaffold(
        appBar: AppBar(
          leading:
              IconButton(icon: const Icon(Icons.close), onPressed: _closePage),
          title: Text(widget.contact?.displayName ?? 'Schedule'),
        ),
        body: SafeArea(
          child: Column(children: [
            ListView(
                shrinkWrap: true,
                scrollDirection: Axis.vertical,
                children: [
                  SelectionChoiceGroup(
                      choices: const [
                        'Weekly',
                        'Monthly',
                        'Quarterly',
                        'Yearly'
                      ],
                      onSelect: _handleSelectionTap,
                      selection: selection[oftenLabel] ?? '',
                      label: oftenLabel),
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: notesController,
                      onChanged: (newVal) =>
                          _handleSelectionTap(notesLabel, newVal),
                      autocorrect: true,
                      enableSuggestions: false,
                      decoration: const InputDecoration(labelText: notesLabel),
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ]),
            const Spacer(),
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              child: _getContactButton(),
            ),
          ]),
        ),
      ),
      onTap: () {
        if (mounted) {
          FocusScope.of(context).requestFocus(FocusNode());
        }
      },
    );
  }
}
