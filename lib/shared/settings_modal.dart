import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friend_builder/utils/calendar_sync.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

const String calendarSyncEnabledKey = 'calendar_sync_enabled';
const String excludedContactsKey = 'excluded_calendar_contacts';

class SettingsModal extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  const SettingsModal({
    super.key,
    required this.flutterLocalNotificationsPlugin,
  });

  static Future<bool> isCalendarSyncEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(calendarSyncEnabledKey) ?? false;
  }

  static Future<void> setCalendarSyncEnabled(bool enabled) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(calendarSyncEnabledKey, enabled);
  }

  static Future<List<String>> getExcludedContacts() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getStringList(excludedContactsKey) ?? [];
  }

  static Future<void> setExcludedContacts(List<String> contactIds) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(excludedContactsKey, contactIds);
  }

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool _calendarSyncEnabled = false;
  bool _isLoading = true;
  List<String> _excludedContactIds = [];
  Map<String, String> _excludedContactNames = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    var enabled = await SettingsModal.isCalendarSyncEnabled();
    if (kDebugMode) {
      print('Settings modal: saved enabled=$enabled');
    }

    if (enabled) {
      final hasPermission = await CalendarSync.checkCalendarPermission();
      if (kDebugMode) {
        print('Settings modal: hasPermission=$hasPermission');
      }
      if (!hasPermission) {
        enabled = false;
        await SettingsModal.setCalendarSyncEnabled(false);
        if (kDebugMode) {
          print('Settings modal: disabled sync due to missing permission');
        }
      }
    }

    final excludedIds = await SettingsModal.getExcludedContacts();
    final contactNames = <String, String>{};

    if (excludedIds.isNotEmpty) {
      try {
        final contacts = await FlutterContacts.getContacts();
        for (var contact in contacts) {
          if (excludedIds.contains(contact.id)) {
            contactNames[contact.id] = contact.displayName;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error loading contact names: $e');
        }
      }
    }

    if (mounted) {
      setState(() {
        _calendarSyncEnabled = enabled;
        _excludedContactIds = excludedIds;
        _excludedContactNames = contactNames;
        _isLoading = false;
      });
    }
  }

  Future<void> _addExcludedContact() async {
    final contacts = await FlutterContacts.getContacts();
    final availableContacts = contacts
        .where((c) =>
            !_excludedContactIds.contains(c.id) && c.displayName.isNotEmpty)
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    if (!mounted) return;

    final selected = await showDialog<Contact>(
      context: context,
      builder: (context) => _ContactPickerDialog(contacts: availableContacts),
    );

    if (selected != null) {
      final newExcludedIds = [..._excludedContactIds, selected.id];
      await SettingsModal.setExcludedContacts(newExcludedIds);
      setState(() {
        _excludedContactIds = newExcludedIds;
        _excludedContactNames[selected.id] = selected.displayName;
      });
    }
  }

  Future<void> _removeExcludedContact(String contactId) async {
    final newExcludedIds =
        _excludedContactIds.where((id) => id != contactId).toList();
    await SettingsModal.setExcludedContacts(newExcludedIds);
    setState(() {
      _excludedContactIds = newExcludedIds;
      _excludedContactNames.remove(contactId);
    });
  }

  Future<void> _handleCalendarSyncToggle(bool value) async {
    if (value) {
      final hasPermission = await CalendarSync.requestCalendarPermission();
      if (!hasPermission) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Calendar permission is required for this feature'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () => openAppSettings(),
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
        return;
      }
    }

    await SettingsModal.setCalendarSyncEnabled(value);
    setState(() {
      _calendarSyncEnabled = value;
    });

    if (value) {
      CalendarSync.syncCalendarEvents(widget.flutterLocalNotificationsPlugin);
    }
  }

  Widget _buildExcludedContactsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Excluded from Calendar Sync',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addExcludedContact,
              tooltip: 'Add contact to exclude',
            ),
          ],
        ),
        if (_excludedContactIds.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              'No contacts excluded',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ...List.generate(_excludedContactIds.length, (index) {
            final contactId = _excludedContactIds[index];
            final contactName =
                _excludedContactNames[contactId] ?? 'Unknown Contact';
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(contactName),
              trailing: IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: () => _removeExcludedContact(contactId),
                color: Colors.red,
              ),
            );
          }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              SwitchListTile(
                title: const Text('Calendar Sync'),
                subtitle: const Text(
                  'Automatically create hangouts from calendar events with friends',
                ),
                value: _calendarSyncEnabled,
                onChanged: _handleCalendarSyncToggle,
                contentPadding: EdgeInsets.zero,
              ),
              if (_calendarSyncEnabled) _buildExcludedContactsSection(),
            ],
          ],
        ),
      ),
    );
  }
}

class _ContactPickerDialog extends StatefulWidget {
  final List<Contact> contacts;

  const _ContactPickerDialog({required this.contacts});

  @override
  State<_ContactPickerDialog> createState() => _ContactPickerDialogState();
}

class _ContactPickerDialogState extends State<_ContactPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<Contact> _filteredContacts = [];

  @override
  void initState() {
    super.initState();
    _filteredContacts = widget.contacts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = widget.contacts;
      } else {
        _filteredContacts = widget.contacts
            .where((c) =>
                c.displayName.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Contact to Exclude'),
      content: SizedBox(
        width: double.maxFinite,
        height: 450,
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _filterContacts,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredContacts.length,
                itemBuilder: (context, index) {
                  final contact = _filteredContacts[index];
                  return ListTile(
                    title: Text(contact.displayName),
                    onTap: () => Navigator.of(context).pop(contact),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
