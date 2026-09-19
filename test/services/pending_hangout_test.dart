import 'package:flutter_test/flutter_test.dart';
import 'package:friend_builder/services/pending_hangout.dart';

void main() {
  test('pendingHangoutStorageKey is unique per pendingId', () {
    expect(pendingHangoutStorageKey('p1'), 'pending_hangout.p1');
    expect(pendingHangoutStorageKey('p2'), 'pending_hangout.p2');
    expect(
      pendingHangoutStorageKey('p1'),
      isNot(pendingHangoutStorageKey('p2')),
    );
  });

  test('parsePendingHangoutItem reads a single object', () {
    final item = parsePendingHangoutItem({
      'pendingId': 'p1',
      'contactIdentifier': 'c1',
      'displayName': 'Alex',
      'enqueuedAt': '2026-01-01T00:00:00Z',
    });
    expect(item?.pendingId, 'p1');
    expect(item?.displayName, 'Alex');
  });

  test('parsePendingHangoutItem rejects invalid payloads', () {
    expect(parsePendingHangoutItem(null), isNull);
    expect(parsePendingHangoutItem(''), isNull);
    expect(parsePendingHangoutItem('not-json'), isNull);
    expect(parsePendingHangoutItem({'pendingId': ''}), isNull);
    expect(
      parsePendingHangoutItem({
        'pendingId': 'p1',
        'contactIdentifier': '',
      }),
      isNull,
    );
  });

  test('parsePendingHangoutList reads channel payloads and skips invalid', () {
    final items = parsePendingHangoutList([
      {
        'pendingId': 'p1',
        'contactIdentifier': 'c1',
        'displayName': 'Alex',
        'enqueuedAt': 't1',
      },
      {
        'pendingId': '',
        'contactIdentifier': 'c2',
        'displayName': 'Bad',
      },
      {
        'pendingId': 'p3',
        'contactIdentifier': 'c3',
        'displayName': 'Casey',
        'enqueuedAt': 't3',
      },
    ]);
    expect(items.map((item) => item.pendingId), ['p1', 'p3']);
  });

  test('parsePendingHangouts still reads legacy JSON arrays', () {
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
  }
]
''';
    final items = parsePendingHangouts(json);
    expect(items.single.pendingId, 'p1');
    expect(parsePendingHangouts(null), isEmpty);
    expect(parsePendingHangouts('not-json'), isEmpty);
    expect(parsePendingHangouts('{}'), isEmpty);
  });
}
