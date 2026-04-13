import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:friend_builder/utils/contact_search.dart';
import 'package:test/test.dart';

void main() {
  group('tierForContact', () {
    test('Alex M matches Alexandra Martellaro via ordered tokens', () {
      final contact =
          Contact(id: '1', displayName: 'Alexandra Martellaro');
      expect(
        ContactSearch.tierForContact(contact, 'Alex M'),
        ContactMatchTier.orderedTokensStrict,
      );
    });

    test('typo in first name uses ordered fuzzy tier', () {
      final contact =
          Contact(id: '1', displayName: 'Alekzandra Martellaro');
      expect(
        ContactSearch.tierForContact(contact, 'Alex M'),
        ContactMatchTier.orderedTokensFuzzy,
      );
    });
  });

  group('sortAndLimitSuggestions', () {
    test('Alex M ranks strict ordered match above recent bigram-only match',
        () {
      final alexandra =
          Contact(id: 'alexandra', displayName: 'Alexandra Martellaro');
      final bigramOnly =
          Contact(id: 'alpha', displayName: 'Alpha Lexicus Moreton');
      final sorted = ContactSearch.sortAndLimitSuggestions(
        [bigramOnly, alexandra],
        'Alex M',
        {bigramOnly.id},
      );
      expect(sorted.first.id, 'alexandra');
    });
  });

  group('normalizedSearchStringsForContact', () {
    test('includes nickname for informal name phrases', () {
      final contact = Contact(
        displayName: 'Robert Formal',
        name: Name(nickname: 'Alex Buddy'),
      );
      final phrases =
          ContactSearch.normalizedSearchStringsForContact(contact).toList();
      expect(phrases, contains('alex buddy'));
      expect(phrases, contains('robert formal'));
    });

    test('includes given name when display name is formal', () {
      final contact = Contact(
        displayName: 'Robert Formal',
        name: Name(first: 'Alex'),
      );
      final phrases =
          ContactSearch.normalizedSearchStringsForContact(contact).toList();
      expect(phrases, contains('alex'));
    });
  });

  group('passesSuggestionFilter', () {
    test('excludes weak matches when query length reaches threshold', () {
      final noMatch = Contact(id: '1', displayName: 'Brimelow Mixtures');
      expect(
        ContactSearch.passesSuggestionFilter(
          noMatch,
          'Alex M',
          minimumPatternLengthForMatch: 2,
        ),
        false,
      );
    });
  });
}
