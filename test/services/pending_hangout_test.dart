import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/services/pending_hangout.dart';

void main() {
  test('parsePendingHangouts reads valid items and skips invalid ones', () {
    const json = '''
[
  {
    "pendingId": "p1",
    "contactIdentifier": "c1",
    "displayName": "Alex",
    "enqueuedAt": "2026-01-01T00:00:00Z"
  },
  {
    "pendingId": "",
    "contactIdentifier": "c2",
    "displayName": "Bad"
  },
  {
    "pendingId": "p3",
    "contactIdentifier": "c3",
    "displayName": "Casey",
    "enqueuedAt": "2026-01-02T00:00:00Z"
  }
]
''';

    final items = parsePendingHangouts(json);
    expect(items.length, 2);
    expect(items.first.pendingId, 'p1');
    expect(items.first.displayName, 'Alex');
    expect(items.last.pendingId, 'p3');
  });

  test('parsePendingHangouts returns empty for null or malformed JSON', () {
    expect(parsePendingHangouts(null), isEmpty);
    expect(parsePendingHangouts(''), isEmpty);
    expect(parsePendingHangouts('not-json'), isEmpty);
    expect(parsePendingHangouts('{}'), isEmpty);
  });

  test('removePendingHangoutById is idempotent', () {
    final items = [
      const PendingHangoutItem(
        pendingId: 'p1',
        contactIdentifier: 'c1',
        displayName: 'Alex',
        enqueuedAt: 't1',
      ),
      const PendingHangoutItem(
        pendingId: 'p2',
        contactIdentifier: 'c2',
        displayName: 'Blake',
        enqueuedAt: 't2',
      ),
    ];

    final once = removePendingHangoutById(items: items, pendingId: 'p1');
    expect(once.map((item) => item.pendingId), ['p2']);

    final twice = removePendingHangoutById(items: once, pendingId: 'p1');
    expect(twice.map((item) => item.pendingId), ['p2']);

    final encoded = encodePendingHangouts(twice);
    expect(parsePendingHangouts(encoded).single.pendingId, 'p2');
  });

  test('removePendingHangoutById preserves unrelated concurrent items', () {
    final items = [
      const PendingHangoutItem(
        pendingId: 'p1',
        contactIdentifier: 'c1',
        displayName: 'Alex',
        enqueuedAt: 't1',
      ),
      const PendingHangoutItem(
        pendingId: 'p2',
        contactIdentifier: 'c2',
        displayName: 'Blake',
        enqueuedAt: 't2',
      ),
    ];

    final afterP1 = removePendingHangoutById(items: items, pendingId: 'p1');
    expect(afterP1.map((item) => item.pendingId), ['p2']);
  });
}
