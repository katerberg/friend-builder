import 'package:flutter/material.dart';
import 'package:friend_builder/pages/stats/sections/top_friends_section.dart';
import 'package:friend_builder/storage.dart';

class StatsPage extends StatelessWidget {
  final Storage storage;

  const StatsPage({
    super.key,
    required this.storage,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        TopFriendsSection(storage: storage),
      ],
    );
  }
}
