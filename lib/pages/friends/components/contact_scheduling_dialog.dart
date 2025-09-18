import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/shared/selection_choice_group.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/permissions.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:permission_handler/permission_handler.dart';

const oftenLabel = 'How often do you want to contact this person?';
const notesLabel = 'Notes';

class ContactSchedulingDialog extends StatefulWidget {
  final Contact? contact;
  final Friend? friend;

  const ContactSchedulingDialog({super.key, this.contact, this.friend});

  @override
  ContactSchedulingDialogState createState() => ContactSchedulingDialogState();
}

class ContactSchedulingDialogState extends State<ContactSchedulingDialog>
    with WidgetsBindingObserver {
  Map<String, String> selection = {
    oftenLabel: 'Weekly',
    notesLabel: '',
  };
  bool isContactable = false;
  bool _hasNotificationsPermissions = false;
  List<Hangout> _contactHangouts = [];
  final Storage _storage = Storage();

  TextEditingController notesController = TextEditingController(text: '');

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _setCurrentNotificationPermissions();
  }

  @override
  void initState() {
    super.initState();
    if (widget.friend == null && widget.contact == null) {
      throw ArgumentError('contact and friend cannot both be null');
    }
    WidgetsBinding.instance.addObserver(this);
    _setCurrentNotificationPermissions();
    selection[oftenLabel] = widget.friend?.frequency ?? 'Weekly';
    selection[notesLabel] = widget.friend?.notes ?? '';
    isContactable = widget.friend?.isContactable ?? false;
    notesController = TextEditingController(text: selection[notesLabel]);
    _loadContactHangouts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _setCurrentNotificationPermissions() {
    PermissionsUtils()
        .isMissingPermission(Permission.notification)
        .then((value) => setState(() {
              _hasNotificationsPermissions = !value;
            }));
  }

  void _loadContactHangouts() async {
    if (widget.contact == null) return;

    final allHangouts = await _storage.getHangouts();
    if (allHangouts != null) {
      final contactHangouts = allHangouts
          .where((hangout) => hangout.hasContact(widget.contact!))
          .toList();

      // Sort by date descending to get most recent first
      contactHangouts.sort((a, b) => b.when.compareTo(a.when));

      if (mounted) {
        setState(() {
          _contactHangouts = contactHangouts;
        });
      }
    }
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
      selection[oftenLabel] = selectedValue;
    });
  }

  void _editContactPressed() {
    FlutterContacts.openExternalEdit(widget.contact!.id);
  }

  ButtonStyleButton _getContactButton() {
    onPressed() {
      setState(() {
        isContactable = !isContactable;
      });
      _closePage();
    }

    requestPermissions() {
      openAppSettings();
    }

    if (widget.friend?.isContactable == true) {
      return TextButton(
        onPressed: onPressed,
        child: Text(
          "I don't want reminders for ${ContactsHelper.getContactName(widget.contact)}",
          style: const TextStyle(color: Color(0xffdd4444)),
        ),
      );
    }

    return TextButton(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.all(Colors.blue),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
      onPressed: !_hasNotificationsPermissions ? requestPermissions : onPressed,
      child: Text(
          !_hasNotificationsPermissions
              ? 'Enable notifications'
              : 'I want notifications for ${ContactsHelper.getContactName(widget.contact)}',
          style: const TextStyle(color: Colors.white)),
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
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
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
                        label:
                            'How often do you want to contact ${ContactsHelper.getContactName(widget.contact)}?',
                      ),
                      widget.contact == null
                          ? Container()
                          : TextButton(
                              onPressed: _editContactPressed,
                              child: const Text('Edit Contact')),
                      Container(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: notesController,
                          onChanged: (newVal) =>
                              _handleSelectionTap(notesLabel, newVal),
                          autocorrect: true,
                          enableSuggestions: false,
                          decoration:
                              const InputDecoration(labelText: notesLabel),
                          keyboardType: TextInputType.multiline,
                          minLines: 1,
                          maxLines: 8,
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                      if (_contactHangouts.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.event,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                'Last hangout: ${_contactHangouts.first.dateWithYear()}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: _getContactButton(),
              ),
            ],
          ),
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
