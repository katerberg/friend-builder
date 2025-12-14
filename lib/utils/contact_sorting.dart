import 'package:friend_builder/data/frequency.dart';
import 'package:friend_builder/utils/scheduling.dart';

class SortableContact {
  final String id;
  final String displayName;
  final int? frequencyValue;
  final DateTime? lastHangoutDate;
  final bool isContactable;

  SortableContact({
    required this.id,
    required this.displayName,
    required this.frequencyValue,
    required this.lastHangoutDate,
    required this.isContactable,
  });
}

class ContactSortResult {
  final List<String> hangoutContactIds;
  final List<String> unusedContactIds;

  ContactSortResult(this.hangoutContactIds, this.unusedContactIds);
}

/// Sorts contacts into two groups:
/// 1. hangoutContacts: Contacts with isContactable=true, sorted by "days left"
///    (how overdue or upcoming they are based on frequency and last hangout)
/// 2. unusedContacts: Contacts with isContactable=false, sorted alphabetically
///
/// "Days left" calculation:
/// - frequencyValue (e.g., 7 for weekly) minus days since last hangout
/// - Negative = overdue, Positive = still have time
/// - Contacts most overdue appear first
///
/// This is a top-level function so it can be used with compute() for isolate execution.
ContactSortResult sortContactsForDisplay(List<SortableContact> contacts) {
  final hangoutContacts = contacts.where((c) => c.isContactable).toList();
  final unusedContacts = contacts.where((c) => !c.isContactable).toList();

  hangoutContacts.sort((a, b) {
    final freqA = a.frequencyValue ?? Frequency.fromType('Weekly').value;
    final freqB = b.frequencyValue ?? Frequency.fromType('Weekly').value;
    final daysA =
        Scheduling.daysLeft(Frequency.fromValue(freqA), a.lastHangoutDate);
    final daysB =
        Scheduling.daysLeft(Frequency.fromValue(freqB), b.lastHangoutDate);
    return daysA != daysB
        ? daysA - daysB
        : a.displayName.compareTo(b.displayName);
  });

  unusedContacts.sort((a, b) => a.displayName.compareTo(b.displayName));

  return ContactSortResult(
    hangoutContacts.map((c) => c.id).toList(),
    unusedContacts.map((c) => c.id).toList(),
  );
}
