import 'package:friend_builder/data/calendar_year_stats.dart';
import 'package:friend_builder/pages/stats/components/hangouts_bar_chart.dart';
import 'package:flutter/material.dart';

class WeekdayHangoutsChart extends StatelessWidget {
  final List<int> weekdayCounts;

  const WeekdayHangoutsChart({
    super.key,
    required this.weekdayCounts,
  });

  @override
  Widget build(BuildContext context) {
    return HangoutsBarChart(
      counts: weekdayCounts,
      labels: weekdayLabels,
    );
  }
}
