import 'package:friend_builder/data/hangout.dart';

/// Matches History pagination's `filterOldHangouts` window in the database layer.
const Duration historyOpenableWindow = Duration(days: 365);

/// Hangouts History can currently deep-link to: [when] on or after [now] minus
/// [historyOpenableWindow], newest first.
List<Hangout> hangoutsOpenableInHistory(
  List<Hangout> hangouts, {
  DateTime? now,
}) {
  final cutoff = (now ?? DateTime.now()).subtract(historyOpenableWindow);
  final eligible = hangouts
      .where((hangout) => !hangout.when.isBefore(cutoff))
      .toList();
  eligible.sort((a, b) => b.when.compareTo(a.when));
  return eligible;
}
