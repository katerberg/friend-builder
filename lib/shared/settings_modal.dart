import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:friend_builder/utils/calendar_sync.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:friend_builder/theme_notifier.dart';
import 'package:friend_builder/services/cloud_sync_service.dart';

const String calendarSyncEnabledKey = 'calendar_sync_enabled';
const String excludedContactsKey = 'excluded_calendar_contacts';

class SettingsModal extends StatefulWidget {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  final ThemeNotifier themeNotifier;

  const SettingsModal({
    super.key,
    required this.flutterLocalNotificationsPlugin,
    required this.themeNotifier,
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
  DateTime? _lastSyncTime;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadSyncStatus();
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

  Future<void> _loadSyncStatus() async {
    if (!CloudSyncService().isInitialized) {
      return;
    }

    try {
      final lastSync = await CloudSyncService().getLastSyncTimestamp();
      if (mounted) {
        setState(() {
          _lastSyncTime = lastSync;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to load sync status: $e');
      }
    }
  }

  Future<void> _performManualSync() async {
    if (!CloudSyncService().isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Cloud backup is not configured. Please follow FIREBASE_SETUP.md to set up Firebase.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final canSync = await CloudSyncService().shouldSyncManually();
    if (!canSync) {
      final lastSync = await CloudSyncService().getLastSyncTimestamp();
      if (lastSync != null && mounted) {
        final minutesAgo = DateTime.now().difference(lastSync).inMinutes;
        final minutesRemaining = 60 - minutesAgo;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Sync is throttled. Please wait $minutesRemaining more minute${minutesRemaining == 1 ? '' : 's'}.'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isSyncing = true;
    });

    try {
      await CloudSyncService().performFullSync(forceSync: true);
      await _loadSyncStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully synced to cloud'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Manual sync failed: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync failed. Please check your connection.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
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

  Widget _buildThemeColorPicker() {
    final currentColor = widget.themeNotifier.themeColor;
    final colorNames = [
      'Soft Sky Blue',
      'Mint Green',
      'Blush Pink',
      'Peach',
      'Lavender',
      'Golden Yellow',
      'Black',
      'Coral',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'App Theme Color',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(ThemeNotifier.pastelColors.length, (index) {
            final color = ThemeNotifier.pastelColors[index];
            final colorName = colorNames[index];
            final isSelected = currentColor.toARGB32() == color.toARGB32();

            return Semantics(
              label: colorName,
              hint: isSelected ? 'Currently selected' : 'Tap to select',
              selected: isSelected,
              button: true,
              child: InkWell(
                onTap: () {
                  widget.themeNotifier.setThemeColor(color);
                  setState(() {});
                },
                borderRadius: BorderRadius.circular(22),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onSurface
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                        : null,
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: _contrastingColor(color),
                          size: 22,
                        )
                      : null,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Color _contrastingColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Widget _buildCloudSyncSection() {
    final isConfigured = CloudSyncService().isInitialized;

    String syncStatusText = 'Never synced';
    if (_lastSyncTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSyncTime!);

      if (difference.inMinutes < 1) {
        syncStatusText = 'Just now';
      } else if (difference.inMinutes < 60) {
        syncStatusText =
            '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
      } else if (difference.inHours < 24) {
        syncStatusText =
            '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else {
        syncStatusText =
            '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Cloud Backup',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (!isConfigured)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Cloud backup not configured. Follow FIREBASE_SETUP.md to enable.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            'Your data is automatically backed up to the cloud',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        const SizedBox(height: 12),
        if (isConfigured)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last sync',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    syncStatusText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSyncing ? null : _performManualSync,
                icon: _isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(_isSyncing ? 'Syncing…' : 'Sync Now'),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
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
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildThemeColorPicker(),
                        const Divider(),
                        _buildCloudSyncSection(),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Calendar Sync'),
                          subtitle: const Text(
                            'Automatically create hangouts from calendar events with friends',
                          ),
                          value: _calendarSyncEnabled,
                          onChanged: _handleCalendarSyncToggle,
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (_calendarSyncEnabled)
                          _buildExcludedContactsSection(),
                      ],
                    ),
                  ),
                ),
            ],
          ),
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
                hintText: 'Search contacts…',
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
