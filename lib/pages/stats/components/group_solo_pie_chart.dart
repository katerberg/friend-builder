import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:friend_builder/data/calendar_year_stats.dart';

class GroupSoloPieChart extends StatelessWidget {
  final GroupSoloCounts counts;

  const GroupSoloPieChart({
    super.key,
    required this.counts,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final total = counts.total;

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 36,
              sections: [
                PieChartSectionData(
                  value: counts.soloCount.toDouble(),
                  color: colorScheme.primary,
                  radius: 52,
                  title: '',
                ),
                PieChartSectionData(
                  value: counts.groupCount.toDouble(),
                  color: colorScheme.secondary,
                  radius: 52,
                  title: '',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _LegendRow(
          color: colorScheme.primary,
          label: 'Solo',
          count: counts.soloCount,
          percent: total == 0 ? 0 : counts.soloCount / total,
        ),
        const SizedBox(height: 8),
        _LegendRow(
          color: colorScheme.secondary,
          label: 'Group',
          count: counts.groupCount,
          percent: total == 0 ? 0 : counts.groupCount / total,
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final double percent;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    final percentLabel = '${(percent * 100).round()}%';

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(label),
        ),
        Text(
          '$count ($percentLabel)',
          style: TextStyle(color: Theme.of(context).hintColor),
        ),
      ],
    );
  }
}
