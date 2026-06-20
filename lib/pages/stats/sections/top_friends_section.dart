import 'package:flutter/material.dart';
import 'package:friend_builder/contacts_permission.dart';
import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/data/top_friend_row.dart';
import 'package:friend_builder/pages/stats/components/stats_section_card.dart';
import 'package:friend_builder/storage.dart';
import 'package:friend_builder/shared/lazy_contact_avatar.dart';

class TopFriendsSection extends StatefulWidget {
  final Storage storage;

  const TopFriendsSection({
    super.key,
    required this.storage,
  });

  @override
  State<TopFriendsSection> createState() => _TopFriendsSectionState();
}

class _TopFriendsSectionState extends State<TopFriendsSection> {
  bool _isLoading = true;
  List<TopFriendRow> _topFriends = [];
  Map<String, Contact> _contactByIdentifier = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final topFriendsFuture =
        widget.storage.getTopFriendsForCalendarYear(limit: 5);
    final contactPermissionFuture = ContactPermissionService().getContacts();

    final topFriends = await topFriendsFuture;
    final contactPermission = await contactPermissionFuture;

    if (!mounted) return;

    setState(() {
      _topFriends = topFriends;
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
              row.displayName.isNotEmpty
                  ? row.displayName
                  : contact.displayName,
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
      return const StatsEmptyMessage(
        message:
            'No hangouts yet this year. Log one to see who you spend the most time with.',
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
    return StatsSectionCard(
      title: 'Top Friends',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildContent(),
    );
  }
}
