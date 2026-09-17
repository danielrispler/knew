import '../../vocabulary/domain/entry.dart';

abstract class StringNormalizer {
  static String normalize(String input) {
    if (input.isEmpty) return '';

    // Strip Hebrew niqqud (U+0591 to U+05C7)
    String result = input.replaceAll(RegExp(r'[\u0591-\u05C7]'), '');

    // Strip Unicode punctuation
    result = result.replaceAll(RegExp(r'[\p{P}]', unicode: true), '');

    // Lowercase
    result = result.toLowerCase();

    // Collapse whitespace and trim
    result = result.replaceAll(RegExp(r'\s+'), ' ').trim();

    return result;
  }
}

enum AnswerCheckStatus { exactMatch, typoMatch, noMatch }

class AnswerCheckResult {
  final AnswerCheckStatus status;
  final String? matchedTarget;

  const AnswerCheckResult(this.status, {this.matchedTarget});
}

abstract class AnswerChecker {
  /// Evaluates user input against a list of accepted target strings.
  static AnswerCheckResult evaluate({
    required String userInput,
    required List<String> expectedAnswers,
  }) {
    final normalizedInput = StringNormalizer.normalize(userInput);
    if (normalizedInput.isEmpty) {
      return const AnswerCheckResult(AnswerCheckStatus.noMatch);
    }

    final inputRunes = normalizedInput.runes.toList();

    // 1. Check exact match first
    for (final expected in expectedAnswers) {
      final normalizedExpected = StringNormalizer.normalize(expected);
      if (normalizedInput == normalizedExpected) {
        return AnswerCheckResult(
          AnswerCheckStatus.exactMatch,
          matchedTarget: expected,
        );
      }
    }

    // 2. Check typo match using code-point Levenshtein distance
    String? bestTypoMatch;
    int lowestDistance = 999;

    for (final expected in expectedAnswers) {
      final normalizedExpected = StringNormalizer.normalize(expected);
      if (normalizedExpected.isEmpty) continue;

      final expectedRunes = normalizedExpected.runes.toList();
      final maxAllowedDistance = expectedRunes.length <= 5 ? 1 : 2;

      final distance = _levenshteinDistance(inputRunes, expectedRunes);
      if (distance <= maxAllowedDistance && distance < lowestDistance) {
        lowestDistance = distance;
        bestTypoMatch = expected;
      }
    }

    if (bestTypoMatch != null) {
      return AnswerCheckResult(
        AnswerCheckStatus.typoMatch,
        matchedTarget: bestTypoMatch,
      );
    }

    return const AnswerCheckResult(AnswerCheckStatus.noMatch);
  }

  /// Evaluates a Hebrew answer for an English -> Hebrew prompt against all meanings.
  static AnswerCheckResult checkHebrewAnswer({
    required String userInput,
    required Entry entry,
  }) {
    final expectedHebrewAnswers = <String>[];
    for (final meaning in entry.meanings) {
      expectedHebrewAnswers.addAll(meaning.hebrewTranslations);
    }

    return evaluate(
      userInput: userInput,
      expectedAnswers: expectedHebrewAnswers,
    );
  }

  /// Evaluates an English answer for a Hebrew -> English prompt against the entry's term.
  static AnswerCheckResult checkEnglishAnswer({
    required String userInput,
    required Entry entry,
  }) {
    return evaluate(userInput: userInput, expectedAnswers: [entry.english]);
  }

  /// Standard Levenshtein distance on code points (runes).
  static int _levenshteinDistance(List<int> a, List<int> b) {
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> previousRow = List<int>.generate(b.length + 1, (i) => i);
    List<int> currentRow = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      currentRow[0] = i + 1;

      for (int j = 0; j < b.length; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        currentRow[j + 1] = [
          currentRow[j] + 1,
          previousRow[j + 1] + 1,
          previousRow[j] + cost,
        ].reduce((min, val) => val < min ? val : min);
      }

      final temp = previousRow;
      previousRow = currentRow;
      currentRow = temp;
    }

    return previousRow[b.length];
  }
}
