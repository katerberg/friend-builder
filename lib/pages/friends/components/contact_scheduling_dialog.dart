import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/shared/selection_choice_group.dart';
import 'package:friend_builder/data/friend.dart';
import 'package:friend_builder/permissions.dart';
import 'package:friend_builder/data/hangout.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/pages/history/components/result.dart';
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
  final Storage _storage = Storage();
  List<Hangout> _hangouts = [];
  bool _isFetchingHangouts = true;

  TextEditingController notesController = TextEditingController(text: '');

  void _refreshHangouts() {
    _storage.getHangouts().then((hangouts) {
      if (hangouts != null) {
        setState(() {
          _isFetchingHangouts = false;
          _hangouts = hangouts;
        });
      }
    });
  }

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
    _refreshHangouts();
    WidgetsBinding.instance.addObserver(this);
    _setCurrentNotificationPermissions();
    selection[oftenLabel] = widget.friend?.frequency ?? 'Weekly';
    selection[notesLabel] = widget.friend?.notes ?? '';
    isContactable = widget.friend?.isContactable ?? false;
    notesController = TextEditingController(text: selection[notesLabel]);
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

  List<Widget> _notesAndHangouts() {
    return [
      Expanded(
          child: TextField(
        controller: notesController,
        onChanged: (newVal) => _handleSelectionTap(notesLabel, newVal),
        autocorrect: true,
        enableSuggestions: false,
        decoration: const InputDecoration(labelText: notesLabel),
        keyboardType: TextInputType.multiline,
        maxLines: null,
        textCapitalization: TextCapitalization.sentences,
      )),
      const Text('Hangouts'),
      _isFetchingHangouts
          ? const CircularProgressIndicator()
          : Expanded(
              child: ListView(
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  children: _hangouts
                      .map((hangout) => Result(
                            hangout: hangout,
                          ))
                      .toList()),
            )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;

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
                      label:
                          'How often do you want to contact ${ContactsHelper.getContactName(widget.contact)}?',
                    ),
                    widget.contact == null
                        ? Container()
                        : TextButton(
                            onPressed: _editContactPressed,
                            child: const Text('Edit Contact')),
                  ]),
              const Spacer(),
              Container(
                padding: const EdgeInsets.only(bottom: 16),
                child: _getContactButton(),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [..._notesAndHangouts()],
                ),
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
