import 'package:intl/intl.dart';

class Scheduling {
  static int daysFromFrequency(String frequency) {
    switch (frequency) {
      case 'Weekly':
        return 7;
      case 'Quarterly':
        return 91;
      case 'Monthly':
        return 31;
      case 'Yearly':
        return 365;
      default:
        return 365;
    }
  }

  static int daysLeft(String frequency, DateTime? latestHangoutTime) {
    int daysAgo =
        DateTime.now().difference(latestHangoutTime ?? DateTime(2200)).inDays;
    int howOften = daysFromFrequency(frequency);
    return howOften - daysAgo;
  }

  static DateTime howLong(DateTime previousHangout, String interaction) {
    return previousHangout
        .add(Duration(days: daysFromFrequency(interaction)))
        .add(const Duration(hours: 12));
  }

  static String formatDate(DateTime date) =>
      DateFormat.yMMMMEEEEd().format(date);
}
