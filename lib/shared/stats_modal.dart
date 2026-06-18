import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/top_friend_row.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/shared/lazy_contact_avatar.dart';
import 'package:friend_builder/utils/calendar_year.dart';

class StatsModal extends StatefulWidget {
  final Storage storage;

  const StatsModal({
    super.key,
    required this.storage,
  });

  @override
  State<StatsModal> createState() => _StatsModalState();
}

class _StatsModalState extends State<StatsModal> {
  bool _isLoading = true;
  List<TopFriendRow> _topFriends = [];
  int _hangoutCount = 0;
  Map<String, Contact> _contactByIdentifier = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final topFriendsFuture =
        widget.storage.getTopFriendsForCalendarYear(limit: 5);
    final hangoutCountFuture = widget.storage.getHangoutCountForCalendarYear();
    final contactPermissionFuture = ContactPermissionService().getContacts();

    final topFriends = await topFriendsFuture;
    final hangoutCount = await hangoutCountFuture;
    final contactPermission = await contactPermissionFuture;

    if (!mounted) return;

    setState(() {
      _topFriends = topFriends;
      _hangoutCount = hangoutCount;
      _contactByIdentifier = {
        for (final contact in contactPermission.contacts) contact.id: contact,
      };
      _isLoading = false;
    });
  }

  Contact _contactForRow(TopFriendRow row) {
    return _contactByIdentifier[row.contactIdentifier] ??
        EncodableContact(
          displayName: row.displayName,
          middleName: '',
          givenName: row.displayName,
          identifier: row.contactIdentifier,
          familyName: '',
        );
  }

  String _rankLabel(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '$rank';
    }
  }

  String _hangoutCountLabel(int count) {
    return count == 1 ? '1 hangout' : '$count hangouts';
  }

  Widget _buildLeaderboardRow(int rank, TopFriendRow row) {
    final contact = _contactForRow(row);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Text(
              _rankLabel(rank),
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
          ),
          LazyContactAvatar(contact: contact),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              row.displayName.isNotEmpty ? row.displayName : contact.displayName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _hangoutCountLabel(row.hangoutCount),
            style: TextStyle(color: Theme.of(context).hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_topFriends.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(
            '🏆: Yourself',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var index = 0; index < _topFriends.length; index++)
          _buildLeaderboardRow(index + 1, _topFriends[index]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final year = calendarYearBounds().year;
    final subtitle = formatHangoutCountSubtitle(year, _hangoutCount);

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
                    'Top Friends',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Flexible(
                  child: SingleChildScrollView(
                    child: _buildContent(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
