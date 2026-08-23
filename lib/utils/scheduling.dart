import 'package:intl/intl.dart';
import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/utils/local_date.dart';

class Scheduling {
  static int daysFromFrequency(Frequency frequency) {
    return frequency.value;
  }

  static int daysLeft(Frequency frequency, DateTime? latestHangoutTime) {
    final daysAgo =
        calendarDaysBetween(latestHangoutTime ?? DateTime(2200), DateTime.now());
    final howOften = daysFromFrequency(frequency);
    return howOften - daysAgo;
  }

  static DateTime howLong(DateTime previousHangout, Frequency interaction) {
    var newHang = previousHangout
        .add(Duration(days: daysFromFrequency(interaction)))
        .add(const Duration(hours: 12));
    if (newHang.isBefore(DateTime.now())) {
      return DateTime.now()
          .add(Duration(days: daysFromFrequency(interaction)))
          .add(const Duration(hours: 12));
    }
    return newHang;
  }

  static String formatDate(DateTime date) =>
      DateFormat.yMMMMEEEEd().format(date);
}
