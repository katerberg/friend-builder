class SchedulingUtils {
  static int daysFromFrequncy(String frequency) {
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

  static DateTime howLong(DateTime previousHangout, String interaction) {
    return previousHangout.add(Duration(days: daysFromFrequncy(interaction)));
  }
}
