import 'package:friend_builder/data/calendar_year_stats.dart';
import 'package:friend_builder/pages/stats/components/hangouts_bar_chart.dart';
import 'package:flutter/material.dart';

class MonthlyHangoutsChart extends StatelessWidget {
  final List<int> monthlyCounts;

  const MonthlyHangoutsChart({
    super.key,
    required this.monthlyCounts,
  });

  @override
  Widget build(BuildContext context) {
    return HangoutsBarChart(
      counts: monthlyCounts,
      labels: monthLabels,
    );
  }
}
