import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/missing_permission.dart';
import 'package:friend_builder/shared/no_items_found.dart';
import 'package:friend_builder/shared/selected_friend_chips.dart';
import 'package:friend_builder/utils/contacts_helper.dart';

class FriendAdder extends StatefulWidget {
  final void Function(List<Contact>) onSelectedFriendsChange;

  const FriendAdder({super.key, required this.onSelectedFriendsChange});

  @override
  FriendAdderState createState() => FriendAdderState();
}

class FriendAdderState extends State<FriendAdder> {
  Iterable<Contact> _contacts = [];
  List<Contact> _selectedFriends = [];
  bool _missingPermission = false;
  final TextEditingController typeaheadController =
      TextEditingController(text: '');
  final SuggestionsController<Contact> _suggestionsController =
      SuggestionsController();

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
        contacts: _contacts);
  }

  void _onSelected(Contact contact) {
    typeaheadController.text = '';
    var newFriends = [..._selectedFriends, contact];
    setState(() {
      _selectedFriends = newFriends;
    });
    widget.onSelectedFriendsChange(newFriends);
  }

  void _resetFriend(Contact friendToRemove) {
    var newFriends =
        ContactsHelper.filterContacts(_selectedFriends, friendToRemove);
    setState(() {
      _selectedFriends = newFriends;
    });
    widget.onSelectedFriendsChange(newFriends);
    if (_suggestionsController.isOpen) {
      _suggestionsController.refresh();
    }
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectedFriendChips(
            selectedFriends: _selectedFriends,
            onRemoveFriend: _resetFriend,
            isWhite: true,
          ),
          _selectedFriends.length > 2
              ? const Divider()
              : TypeAheadField(
                  controller: typeaheadController,
                  suggestionsController: _suggestionsController,
                  builder: (context, controller, focusNode) {
                    return TextField(
                      onTap: () => _suggestionsController.refresh(),
                      textCapitalization: TextCapitalization.sentences,
                      controller: controller,
                      focusNode: focusNode,
                      style: const TextStyle(fontSize: 24),
                      autofocus: false,
                      decoration: const InputDecoration(
                        prefixIcon: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [Icon(Icons.search, size: 30)],
                        ),
                        floatingLabelBehavior: FloatingLabelBehavior.never,
                        labelText: "Who do you want to keep up with?",
                      ),
                    );
                  },
                  itemBuilder: (context, Contact suggestion) {
                    return ListTile(
                      leading: EncodableContact.fromContact(suggestion)
                          .getAvatar(context),
                      title: Text(suggestion.displayName),
                    );
                  },
                  onSelected: _onSelected,
                  emptyBuilder: (context) => const NoItemsFound(),
                  suggestionsCallback: (pattern) async => await _getSuggestions(
                      pattern,
                      excludeList: _selectedFriends),
                ),
          _selectedFriends.length > 2
              ? const Text(
                  'You will have the opportunity to add as many friends as you want later, but for now, let’s get started with these.')
              : const SizedBox.shrink(),
        ],
      ),
    );
  }
}
