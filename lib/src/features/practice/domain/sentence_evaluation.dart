class SentenceEvaluation {
  final bool usesTargetTerm, meaningCorrect, grammarCorrect, naturalUsage;
  final String feedback;
  final String? suggestedImprovement;
  const SentenceEvaluation({
    required this.usesTargetTerm,
    required this.meaningCorrect,
    required this.grammarCorrect,
    required this.naturalUsage,
    required this.feedback,
    this.suggestedImprovement,
  });
  bool get isValid => usesTargetTerm && meaningCorrect && grammarCorrect;
}

abstract class SentenceTargetDetector {
  static bool containsTarget({
    required String sentence,
    required List<String> forms,
  }) {
    final tokens = _tokens(sentence);
    return forms.any((form) {
      final target = _tokens(form);
      if (target.isEmpty || target.length > tokens.length) return false;
      return Iterable<int>.generate(tokens.length - target.length + 1).any(
        (start) =>
            tokens.sublist(start, start + target.length).join('\u0000') ==
            target.join('\u0000'),
      );
    });
  }

  static List<String> _tokens(String value) => RegExp(
    r"[a-z]+(?:['’-][a-z]+)*",
    caseSensitive: false,
  ).allMatches(value.toLowerCase()).map((m) => m.group(0)!).toList();
}
