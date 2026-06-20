import 'package:flutter/material.dart';
import 'package:friend_builder/data/calendar_year_stats.dart';
import 'package:friend_builder/pages/stats/components/group_solo_pie_chart.dart';
import 'package:friend_builder/pages/stats/components/stats_section_card.dart';
import 'package:friend_builder/storage.dart';

class GroupSoloSection extends StatefulWidget {
  final Storage storage;

  const GroupSoloSection({
    super.key,
    required this.storage,
  });

  @override
  State<GroupSoloSection> createState() => _GroupSoloSectionState();
}

class _GroupSoloSectionState extends State<GroupSoloSection> {
  bool _isLoading = true;
  GroupSoloCounts _counts = const GroupSoloCounts(soloCount: 0, groupCount: 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final counts = await widget.storage.getGroupVsSoloCountsForCalendarYear();

    if (!mounted) return;

    setState(() {
      _counts = counts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatsSectionCard(
      title: 'Group vs Solo',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _counts.isEmpty
              ? const StatsEmptyMessage(
                  message: 'No hangouts to chart yet this year.',
                )
              : GroupSoloPieChart(counts: _counts),
    );
  }
}
