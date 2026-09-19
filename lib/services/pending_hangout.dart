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

/// Matches iOS `PendingHangoutStore.keyPrefix` + pendingId.
String pendingHangoutStorageKey(String pendingId) {
  return 'pending_hangout.$pendingId';
}

PendingHangoutItem? parsePendingHangoutItem(Object? raw) {
  if (raw is Map) {
    final item = PendingHangoutItem.fromJson(Map<String, dynamic>.from(raw));
    return item.isValid ? item : null;
  }
  if (raw is! String || raw.isEmpty) {
    return null;
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return null;
    }
    final item = PendingHangoutItem.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    return item.isValid ? item : null;
  } catch (_) {
    return null;
  }
}

List<PendingHangoutItem> parsePendingHangoutList(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  return raw
      .map(parsePendingHangoutItem)
      .whereType<PendingHangoutItem>()
      .toList();
}

/// Legacy single-blob JSON array parser (upgrade migration / tests).
List<PendingHangoutItem> parsePendingHangouts(String? json) {
  if (json == null || json.isEmpty) {
    return const [];
  }
  try {
    return parsePendingHangoutList(jsonDecode(json));
  } catch (_) {
    return const [];
  }
}
