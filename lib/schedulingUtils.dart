class SchedulingUtils {
  static DateTime howLong(DateTime previousHangout, String interaction) {
    Duration duration;
    switch (interaction) {
      case 'Weekly':
        duration = Duration(days: 7);
        break;
      case 'Monthly':
        duration = Duration(days: 31);
        break;
      case 'Quarterly':
        duration = Duration(days: 91);
        break;
      case 'Yearly':
        duration = Duration(days: 365);
        break;
      default:
        duration = Duration(days: 365);
    }
    return previousHangout.add(duration);
  }
}
