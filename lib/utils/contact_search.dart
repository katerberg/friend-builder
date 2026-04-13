import 'dart:math';

import 'package:friend_builder/data/encodable_contact.dart';
import 'package:friend_builder/utils/string_utils.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

enum ContactMatchTier {
  none(0),
  bigramWeak(20),
  legacyWordPrefix(40),
  orderedTokensFuzzy(60),
  orderedTokensStrict(80),
  strongLiteral(100);

  const ContactMatchTier(this.value);
  final int value;
}

class ContactSearch {
  ContactSearch._();

  static const int defaultMaxSuggestions = 7;

  static Iterable<String> normalizedSearchStringsForContact(Contact contact) {
    final Set<String> phrases = {};

    void addPhrase(String? raw) {
      final trimmed = raw?.trim().toLowerCase() ?? '';
      if (trimmed.isNotEmpty) {
        phrases.add(trimmed);
      }
    }

    addPhrase(contact.displayName);
    addPhrase(contact.name.first);
    addPhrase(contact.name.last);
    addPhrase(contact.name.middle);
    addPhrase(contact.name.nickname);

    if (contact is EncodableContact) {
      addPhrase(contact.givenName);
      addPhrase(contact.familyName);
      addPhrase(contact.middleName);
    }

    final structuredFirstLast = [
      contact.name.first.trim(),
      contact.name.last.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    addPhrase(structuredFirstLast);

    if (contact is EncodableContact) {
      final encodable = contact;
      final encodableFirstLast = [
        encodable.givenName.trim(),
        encodable.familyName.trim(),
      ].where((part) => part.isNotEmpty).join(' ');
      addPhrase(encodableFirstLast);
    }

    return phrases;
  }

  static Iterable<List<String>> tokenSequencesForContact(Contact contact) {
    final List<List<String>> sequences = [];
    final Set<String> seen = {};
    for (final phrase in normalizedSearchStringsForContact(contact)) {
      final tokens = phrase
          .split(RegExp(r'\s+'))
          .where((token) => token.isNotEmpty)
          .toList();
      if (tokens.isEmpty) {
        continue;
      }
      final signature = tokens.join('\u0001');
      if (seen.add(signature)) {
        sequences.add(tokens);
      }
    }
    return sequences;
  }

  static double bigramScoreForContact(Contact contact, String pattern) {
    return StringUtils.getComparison(contact.displayName, pattern);
  }

  static ContactMatchTier tierForContact(Contact contact, String pattern) {
    final normalizedQuery = pattern.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return ContactMatchTier.strongLiteral;
    }

    final lowerDisplayName = contact.displayName.toLowerCase();

    ContactMatchTier bestTier = ContactMatchTier.none;

    void consider(ContactMatchTier tier) {
      if (tier.value > bestTier.value) {
        bestTier = tier;
      }
    }

    if (lowerDisplayName.contains(normalizedQuery) ||
        lowerDisplayName.startsWith(normalizedQuery)) {
      consider(ContactMatchTier.strongLiteral);
    }

    final queryTokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList();

    final tokenSequences = tokenSequencesForContact(contact).toList();

    for (final nameTokens in tokenSequences) {
      if (_orderedTokensMatch(nameTokens, queryTokens, allowFuzzy: false)) {
        consider(ContactMatchTier.orderedTokensStrict);
        break;
      }
    }

    for (final nameTokens in tokenSequences) {
      if (_orderedTokensMatch(nameTokens, queryTokens, allowFuzzy: true)) {
        consider(ContactMatchTier.orderedTokensFuzzy);
        break;
      }
    }

    if (_legacyWordPrefixMatch(contact.displayName, pattern)) {
      consider(ContactMatchTier.legacyWordPrefix);
    }

    final bigramScore = bigramScoreForContact(contact, pattern);
    if (bigramScore > 0.1) {
      consider(ContactMatchTier.bigramWeak);
    }

    return bestTier;
  }

  static bool _isRecentlySeen(
    Contact contact,
    Set<String> recentContactIdentifiers,
  ) {
    if (recentContactIdentifiers.contains(contact.id)) {
      return true;
    }
    if (contact is EncodableContact &&
        recentContactIdentifiers.contains(contact.identifier)) {
      return true;
    }
    return false;
  }

  static bool passesSuggestionFilter(
    Contact contact,
    String pattern, {
    required int minimumPatternLengthForMatch,
  }) {
    final trimmed = pattern.trim();
    if (trimmed.length < minimumPatternLengthForMatch) {
      return true;
    }
    return tierForContact(contact, pattern) != ContactMatchTier.none;
  }

  static List<Contact> sortAndLimitSuggestions(
    List<Contact> candidates,
    String pattern,
    Set<String> recentContactIdentifiers, {
    int maxResults = defaultMaxSuggestions,
  }) {
    final scored = candidates
        .map((contact) => _ScoredContact(
              contact: contact,
              tier: tierForContact(contact, pattern),
              bigramScore: bigramScoreForContact(contact, pattern),
              isRecent: _isRecentlySeen(contact, recentContactIdentifiers),
            ))
        .toList();

    scored.sort((left, right) => left.compareTo(right));
    final limitedLength =
        scored.length > maxResults ? maxResults : scored.length;
    return scored
        .sublist(0, limitedLength)
        .map((scoredContact) => scoredContact.contact)
        .toList();
  }

  static bool _legacyWordPrefixMatch(String displayName, String pattern) {
    final lowerDisplayName = displayName.toLowerCase();
    final lowerPattern = pattern.trim().toLowerCase();
    if (lowerPattern.isEmpty) {
      return true;
    }
    return lowerDisplayName.startsWith(lowerPattern) ||
        lowerDisplayName
            .split(RegExp(r'\s+'))
            .any((part) => part.startsWith(lowerPattern));
  }

  static bool _orderedTokensMatch(
    List<String> nameTokens,
    List<String> queryTokens, {
    required bool allowFuzzy,
  }) {
    if (queryTokens.isEmpty) {
      return true;
    }
    var nameIndex = 0;
    for (final queryToken in queryTokens) {
      if (queryToken.isEmpty) {
        continue;
      }
      var matched = false;
      while (nameIndex < nameTokens.length) {
        if (_nameTokenMatchesQueryToken(
          queryToken,
          nameTokens[nameIndex],
          allowFuzzy: allowFuzzy,
        )) {
          matched = true;
          nameIndex++;
          break;
        }
        nameIndex++;
      }
      if (!matched) {
        return false;
      }
    }
    return true;
  }

  static bool _nameTokenMatchesQueryToken(
    String queryToken,
    String nameToken, {
    required bool allowFuzzy,
  }) {
    if (queryToken.isEmpty) {
      return true;
    }
    if (nameToken.isEmpty) {
      return false;
    }
    if (queryToken.length == 1) {
      return nameToken[0] == queryToken[0];
    }
    if (nameToken.startsWith(queryToken)) {
      return true;
    }
    if (!allowFuzzy || queryToken.length < 4) {
      return false;
    }
    final maxEnd = min(nameToken.length, queryToken.length + 2);
    for (var endIndex = queryToken.length;
        endIndex <= maxEnd;
        endIndex++) {
      if (_levenshtein(queryToken, nameToken.substring(0, endIndex)) <= 1) {
        return true;
      }
    }
    return false;
  }

  static int _levenshtein(String stringA, String stringB) {
    final lengthA = stringA.length;
    final lengthB = stringB.length;
    if (lengthA == 0) {
      return lengthB;
    }
    if (lengthB == 0) {
      return lengthA;
    }
    final matrix = List.generate(
      lengthA + 1,
      (_) => List<int>.filled(lengthB + 1, 0),
    );
    for (var indexA = 0; indexA <= lengthA; indexA++) {
      matrix[indexA][0] = indexA;
    }
    for (var indexB = 0; indexB <= lengthB; indexB++) {
      matrix[0][indexB] = indexB;
    }
    for (var indexA = 1; indexA <= lengthA; indexA++) {
      for (var indexB = 1; indexB <= lengthB; indexB++) {
        final substitutionCost =
            stringA[indexA - 1] == stringB[indexB - 1] ? 0 : 1;
        matrix[indexA][indexB] = [
          matrix[indexA - 1][indexB] + 1,
          matrix[indexA][indexB - 1] + 1,
          matrix[indexA - 1][indexB - 1] + substitutionCost,
        ].reduce(min);
      }
    }
    return matrix[lengthA][lengthB];
  }
}

class _ScoredContact {
  _ScoredContact({
    required this.contact,
    required this.tier,
    required this.bigramScore,
    required this.isRecent,
  });

  final Contact contact;
  final ContactMatchTier tier;
  final double bigramScore;
  final bool isRecent;

  int compareTo(_ScoredContact other) {
    final tierComparison = other.tier.value.compareTo(tier.value);
    if (tierComparison != 0) {
      return tierComparison;
    }
    if (isRecent != other.isRecent) {
      return isRecent ? -1 : 1;
    }
    final bigramComparison = other.bigramScore.compareTo(bigramScore);
    if (bigramComparison != 0) {
      return bigramComparison;
    }
    return contact.displayName.compareTo(other.contact.displayName);
  }
}
