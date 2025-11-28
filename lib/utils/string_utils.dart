import 'dart:math';

class StringUtils {
  static String getRandomString([int length = 10]) =>
      String.fromCharCodes(List.generate(
          length,
          (index) =>
              'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
                  .codeUnitAt(Random().nextInt(62))));

  static List<String?> _getBigrams(String str) {
    if (str.length < 2) {
      return [];
    }
    List<String?> bigrams = [];
    for (var i = 0; i < str.length - 1; i++) {
      bigrams.add(str.toLowerCase().substring(i, i + 2));
    }
    return bigrams;
  }

  static double getComparison(String first, String second) {
    if (first.length < 2 || second.length < 2) {
      return 0;
    }
    var bigrams1 = _getBigrams(first);
    var bigrams2 = _getBigrams(second);

    int intersection = 0;

    for (var i = 0; i < bigrams1.length; i++) {
      for (var j = 0; j < bigrams2.length; j++) {
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
