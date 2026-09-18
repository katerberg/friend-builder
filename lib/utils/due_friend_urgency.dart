import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/utils/scheduling.dart';

/// Urgency copy matching [ContactTile] Friends UI semantics.
String dueFriendUrgencyLabel({
  required DateTime? latestHangoutWhen,
  required Frequency? frequency,
}) {
  if (latestHangoutWhen == null) {
    return 'Never seen!';
  }

  final effectiveFrequency = frequency ?? Frequency.fromType('Weekly');
  final daysLeft = Scheduling.daysLeft(effectiveFrequency, latestHangoutWhen);
  if (daysLeft > 0) {
    return '$daysLeft days to go';
  }
  return '${daysLeft.abs()} days late';
}
