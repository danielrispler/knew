import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/domain/cloze_answer_checker.dart';
import 'package:knew/src/features/vocabulary/domain/example_usage.dart';

void main() {
  final example = ExampleUsage.parse('She [[ran]] home.', ['run', 'ran'])!;

  test(
    'Cloze preserves meaningful punctuation and distinguishes inflections',
    () {
      expect(
        ClozeAnswerChecker.check(
          input: '“ran!”',
          example: example,
          validInflections: const ['run'],
        ).status,
        ClozeAnswerStatus.exact,
      );
      expect(
        ClozeAnswerChecker.check(
          input: 'run',
          example: example,
          validInflections: const ['run'],
        ).status,
        ClozeAnswerStatus.wrongInflection,
      );
      expect(
        ClozeAnswerChecker.check(
          input: 'ranx',
          example: example,
          validInflections: const ['run'],
        ).status,
        ClozeAnswerStatus.possibleTypo,
      );
    },
  );
}
