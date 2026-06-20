class GroupSoloCounts {
  final int soloCount;
  final int groupCount;

  const GroupSoloCounts({
    required this.soloCount,
    required this.groupCount,
  });

  int get total => soloCount + groupCount;

  bool get isEmpty => total == 0;

  factory GroupSoloCounts.fromMap(Map<String, dynamic> map) {
    return GroupSoloCounts(
      soloCount: (map['soloCount'] as num?)?.toInt() ?? 0,
      groupCount: (map['groupCount'] as num?)?.toInt() ?? 0,
    );
  }
}

const List<String> monthLabels = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

const List<String> weekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

List<int> emptyMonthlyCounts() => List.filled(12, 0);

List<int> emptyWeekdayCounts() => List.filled(7, 0);

int monthIndexFromSqliteMonth(String monthString) {
  return int.parse(monthString) - 1;
}

List<int> buildMonthlyCountsFromQueryRows(List<Map<String, dynamic>> rows) {
  final counts = emptyMonthlyCounts();
  for (final row in rows) {
    final monthString = row['month'] as String?;
    if (monthString == null) continue;
    final index = monthIndexFromSqliteMonth(monthString);
    if (index >= 0 && index < 12) {
      counts[index] = (row['hangoutCount'] as num).toInt();
    }
  }
  return counts;
}

int sqliteWeekdayToMondayFirstIndex(int sqliteWeekday) {
  if (sqliteWeekday == 0) {
    return 6;
  }
  return sqliteWeekday - 1;
}

List<int> buildWeekdayCountsFromQueryRows(List<Map<String, dynamic>> rows) {
  final counts = emptyWeekdayCounts();
  for (final row in rows) {
    final weekdayString = row['weekday'] as String?;
    if (weekdayString == null) continue;
    final sqliteWeekday = int.parse(weekdayString);
    final index = sqliteWeekdayToMondayFirstIndex(sqliteWeekday);
    counts[index] = (row['hangoutCount'] as num).toInt();
  }
  return counts;
}

bool countsAreAllZero(List<int> counts) {
  return counts.every((count) => count == 0);
}
