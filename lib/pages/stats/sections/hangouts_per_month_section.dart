import 'package:flutter/material.dart';
import 'package:friend_builder/data/calendar_year_stats.dart';
import 'package:friend_builder/pages/stats/components/monthly_hangouts_chart.dart';
import 'package:friend_builder/pages/stats/components/stats_section_card.dart';
import 'package:friend_builder/storage.dart';

class HangoutsPerMonthSection extends StatefulWidget {
  final Storage storage;

  const HangoutsPerMonthSection({
    super.key,
    required this.storage,
  });

  @override
  State<HangoutsPerMonthSection> createState() =>
      _HangoutsPerMonthSectionState();
}

class _HangoutsPerMonthSectionState extends State<HangoutsPerMonthSection> {
  bool _isLoading = true;
  List<int> _monthlyCounts = emptyMonthlyCounts();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final monthlyCounts =
        await widget.storage.getHangoutCountByMonthForCalendarYear();

    if (!mounted) return;

    setState(() {
      _monthlyCounts = monthlyCounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatsSectionCard(
      title: 'Hangouts per Month',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : countsAreAllZero(_monthlyCounts)
              ? const StatsEmptyMessage(
                  message: 'No hangouts to chart yet this year.',
                )
              : MonthlyHangoutsChart(monthlyCounts: _monthlyCounts),
    );
  }
}
