import 'package:intl/intl.dart';
import 'package:friend_builder/data/frequency.dart';

class Scheduling {
  static int daysFromFrequency(Frequency frequency) {
    return frequency.value;
  }

  static int daysLeft(Frequency frequency, DateTime? latestHangoutTime) {
    int daysAgo =
        DateTime.now().difference(latestHangoutTime ?? DateTime(2200)).inDays;
    int howOften = daysFromFrequency(frequency);
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
