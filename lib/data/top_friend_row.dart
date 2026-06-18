class TopFriendRow {
  final String contactIdentifier;
  final String displayName;
  final int hangoutCount;

  const TopFriendRow({
    required this.contactIdentifier,
    required this.displayName,
    required this.hangoutCount,
  });

  factory TopFriendRow.fromMap(Map<String, dynamic> map) {
    return TopFriendRow(
      contactIdentifier: map['identifier'] as String,
      displayName: map['displayName'] as String? ?? '',
      hangoutCount: (map['hangoutCount'] as num).toInt(),
    );
  }
}
