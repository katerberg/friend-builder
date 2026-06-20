import 'package:flutter/material.dart';
import 'package:friend_builder/data/calendar_year_stats.dart';
import 'package:friend_builder/pages/stats/components/stats_section_card.dart';
import 'package:friend_builder/pages/stats/components/weekday_hangouts_chart.dart';
import 'package:friend_builder/storage.dart';

class WeekdayHistogramSection extends StatefulWidget {
  final Storage storage;

  const WeekdayHistogramSection({
    super.key,
    required this.storage,
  });

  @override
  State<WeekdayHistogramSection> createState() =>
      _WeekdayHistogramSectionState();
}

class _WeekdayHistogramSectionState extends State<WeekdayHistogramSection> {
  bool _isLoading = true;
  List<int> _weekdayCounts = emptyWeekdayCounts();

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final weekdayCounts =
        await widget.storage.getHangoutCountByWeekdayForCalendarYear();

    if (!mounted) return;

    setState(() {
      _weekdayCounts = weekdayCounts;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StatsSectionCard(
      title: 'By Day of Week',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : countsAreAllZero(_weekdayCounts)
              ? const StatsEmptyMessage(
                  message: 'No hangouts to chart yet this year.',
                )
              : WeekdayHangoutsChart(weekdayCounts: _weekdayCounts),
    );
  }
}
