import 'package:flutter/material.dart';
import 'package:friend_builder/missing_permission.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/shared/no_items_found.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/contacts_helper.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/data/hangout.dart';

class FriendSelector extends StatefulWidget {
  final List<Contact> selectedFriends;
  final void Function(Contact friend) addFriend;
  final TextEditingController typeaheadController;
  final List<Hangout>? previousHangouts;

  const FriendSelector({
    super.key,
    required this.selectedFriends,
    required this.addFriend,
    required this.typeaheadController,
    this.previousHangouts,
  });

  @override
  FriendSelectorState createState() => FriendSelectorState();
}

class FriendSelectorState extends State<FriendSelector> {
  Iterable<Contact> _contacts = [];
  bool _missingPermission = false;

  String _getInputLabelText() {
    if (widget.selectedFriends.isEmpty) {
      return 'Who are you seeing?';
    }
    return 'Anyone else?';
  }

  Future<List<Contact>> _getSuggestions(String pattern,
      {List<Contact> excludeList = const []}) async {
    if (_contacts.isEmpty) {
      ContactPermission contactPermission =
          await ContactPermissionService().getContacts();
      if (contactPermission.missingPermission) {
        setState(() {
          _missingPermission = true;
        });
        return Future.value([]);
      }
      _contacts = contactPermission.contacts;
    }
    return ContactsHelper.getSuggestions(excludeList, pattern,
        previousHangouts: widget.previousHangouts, contacts: _contacts);
  }

  @override
  Widget build(BuildContext context) {
    if (_missingPermission) {
      return const Column(children: [
        MissingPermission(
          isWhite: true,
        )
      ]);
    }
    const inputBorder = UnderlineInputBorder(
        borderSide: BorderSide(width: 1, color: Colors.white));
    return TypeAheadField(
      controller: widget.typeaheadController,
      builder: (context, controller, focusNode) {
        return TextField(
          textCapitalization: TextCapitalization.sentences,
          controller: controller,
          focusNode: focusNode,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white, fontSize: 24),
          autofocus: false,
          autocorrect: false,
          decoration: InputDecoration(
            floatingLabelBehavior: FloatingLabelBehavior.never,
            focusedBorder: inputBorder,
            enabledBorder: inputBorder,
            labelStyle: const TextStyle(color: Colors.white, fontSize: 24),
            labelText: _getInputLabelText(),
          ),
        );
      },
      // suggestionsCallback: (pattern) async =>
      //     await ContactsHelper.getSuggestions(widget.selectedFriends, pattern,
      //         previousHangouts: widget.previousHangouts),
      suggestionsCallback: (pattern) async => await _getSuggestions(
        pattern,
        excludeList: widget.selectedFriends,
      ),
      itemBuilder: (context, Contact suggestion) {
        return ListTile(
          leading: EncodableContact.fromContact(suggestion).getAvatar(context),
          title: Text(suggestion.displayName),
        );
      },
      emptyBuilder: (context) => const NoItemsFound(),
      debounceDuration: const Duration(milliseconds: 200),
      onSelected: widget.addFriend,
    );
  }
}
