import '../../vocabulary/domain/example_usage.dart';

enum ClozeAnswerStatus { exact, wrongInflection, possibleTypo, incorrect }

class ClozeAnswerResult {
  final ClozeAnswerStatus status;
  final String? matchedTarget;
  const ClozeAnswerResult(this.status, {this.matchedTarget});
}

abstract class ClozeAnswerChecker {
  static ClozeAnswerResult check({
    required String input,
    required ExampleUsage example,
    required Iterable<String> validInflections,
  }) {
    final answer = normalize(input);
    final target = normalize(example.target);
    if (answer.isEmpty)
      return const ClozeAnswerResult(ClozeAnswerStatus.incorrect);
    if (answer == target)
      return ClozeAnswerResult(
        ClozeAnswerStatus.exact,
        matchedTarget: example.target,
      );
    final inflection = validInflections.cast<String?>().firstWhere(
      (form) => form != null && normalize(form) == answer,
      orElse: () => null,
    );
    if (inflection != null)
      return ClozeAnswerResult(
        ClozeAnswerStatus.wrongInflection,
        matchedTarget: inflection,
      );
    if (!answer.contains(' ') &&
        !target.contains(' ') &&
        _distance(answer.runes.toList(), target.runes.toList()) == 1) {
      return ClozeAnswerResult(
        ClozeAnswerStatus.possibleTypo,
        matchedTarget: example.target,
      );
    }
    return const ClozeAnswerResult(ClozeAnswerStatus.incorrect);
  }

  static String normalize(String input) => input
      .trim()
      .toLowerCase()
      .replaceAll('\u2019', "'")
      .replaceFirst(RegExp(r'^[\p{P}]+', unicode: true), '')
      .replaceFirst(RegExp(r'[\p{P}]+$', unicode: true), '')
      .replaceAll(RegExp(r'\s+'), ' ');

  static int _distance(List<int> a, List<int> b) {
    var row = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final next = List<int>.filled(b.length + 1, 0)..[0] = i + 1;
      for (var j = 0; j < b.length; j++) {
        next[j + 1] = [
          next[j] + 1,
          row[j + 1] + 1,
          row[j] + (a[i] == b[j] ? 0 : 1),
        ].reduce((a, b) => a < b ? a : b);
      }
      row = next;
    }
    return row.last;
  }
}
