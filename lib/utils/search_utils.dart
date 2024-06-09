import 'package:friend_builder/utils/string_utils.dart';

class SearchUtils {
  static int sortByBetterMatch(pattern, a, b) {
    bool isBBetterMatch = StringUtils.getComparison(a?.displayName, pattern) <
        StringUtils.getComparison(b?.displayName, pattern);
    return isBBetterMatch ? 1 : -1;
  }

  static int sortTwoFriendsInSuggestions(pattern, a, b) {
    RegExp startsWithExactly = RegExp(
      "^$pattern",
      caseSensitive: false,
    );
    var aMatches = startsWithExactly.hasMatch(a?.displayName ?? '');
    if (aMatches || startsWithExactly.hasMatch(b?.displayName ?? '')) {
      return aMatches ? -1 : 1;
    }
    return sortByBetterMatch(pattern, a, b);
  }
}
