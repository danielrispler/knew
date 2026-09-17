class ExampleUsage {
  final String sentence;
  final String target;
  final String clozeSentence;

  const ExampleUsage._(this.sentence, this.target, this.clozeSentence);

  static ExampleUsage? parse(
    String markedSentence,
    Iterable<String> allowedForms,
  ) {
    final matches = RegExp(
      r'\[\[([^\[\]]+)\]\]',
    ).allMatches(markedSentence).toList();
    if (matches.length != 1) return null;
    final match = matches.single;
    final target = match.group(1)!.trim();
    if (target.isEmpty || !allowedForms.any((form) => _same(target, form))) {
      return null;
    }
    final sentence = markedSentence
        .replaceRange(match.start, match.end, target)
        .trim();
    if (sentence.isEmpty) return null;
    return ExampleUsage._(
      sentence,
      target,
      markedSentence.replaceRange(match.start, match.end, '_____').trim(),
    );
  }

  static bool _same(String a, String b) =>
      a.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ==
      b.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
}
