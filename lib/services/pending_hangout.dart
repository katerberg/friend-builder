import 'dart:convert';

class PendingHangoutItem {
  final String pendingId;
  final String contactIdentifier;
  final String displayName;
  final String enqueuedAt;

  const PendingHangoutItem({
    required this.pendingId,
    required this.contactIdentifier,
    required this.displayName,
    required this.enqueuedAt,
  });

  factory PendingHangoutItem.fromJson(Map<String, dynamic> json) {
    return PendingHangoutItem(
      pendingId: json['pendingId'] as String? ?? '',
      contactIdentifier: json['contactIdentifier'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      enqueuedAt: json['enqueuedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pendingId': pendingId,
      'contactIdentifier': contactIdentifier,
      'displayName': displayName,
      'enqueuedAt': enqueuedAt,
    };
  }

  bool get isValid =>
      pendingId.isNotEmpty && contactIdentifier.isNotEmpty;
}

List<PendingHangoutItem> parsePendingHangouts(String? json) {
  if (json == null || json.isEmpty) {
    return const [];
  }
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List) {
      return const [];
    }
    return decoded
        .whereType<Map>()
        .map(
          (item) => PendingHangoutItem.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .where((item) => item.isValid)
        .toList();
  } catch (_) {
    return const [];
  }
}

String encodePendingHangouts(List<PendingHangoutItem> items) {
  return jsonEncode(items.map((item) => item.toJson()).toList());
}

List<PendingHangoutItem> removePendingHangoutById({
  required List<PendingHangoutItem> items,
  required String pendingId,
}) {
  if (pendingId.isEmpty) {
    return items;
  }
  return items.where((item) => item.pendingId != pendingId).toList();
}
