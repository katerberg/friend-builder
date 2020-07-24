class StringUtils {
  List<String> _getBigrams(String str) {
    if (str.length < 2) {
      return [];
    }
    List<String> bigrams = [];
    for (var i = 0; i < str.length - 1; i++) {
      bigrams.add(str.substring(i, i + 1));
    }
    return bigrams;
  }

  double getComparison(String first, String second) {
    if (first.length < 2 || second.length < 2) {
      return 0;
    }
    var bigrams1 = _getBigrams(first);
    var bigrams2 = _getBigrams(second);

    int intersection = 0;

    for (var i = 0; i < first.length; i++) {
      for (var j = 0; j < second.length; j++) {
        if (bigrams1[i] == bigrams2[j]) {
          intersection++;
          bigrams2[j] = null;
          break;
        }
      }
    }

    return (2.0 * intersection) / (first.length + second.length);
  }
}
