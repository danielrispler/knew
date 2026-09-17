import '../../vocabulary/domain/entry.dart';
import '../../vocabulary/domain/example_usage.dart';
import 'distractor_generator.dart';

enum PromptDirection { englishToHebrew, hebrewToEnglish }

enum QuestionFormat { flashcard, typing, multipleChoice, cloze }

class PracticeQuestion {
  final Entry entry;
  final PromptDirection direction;
  final QuestionFormat format;
  final bool isRepeat;
  final DistractorResult? distractorResult;
  final int? meaningIndex;
  final ExampleUsage? exampleUsage;

  const PracticeQuestion({
    required this.entry,
    required this.direction,
    this.format = QuestionFormat.flashcard,
    this.isRepeat = false,
    this.distractorResult,
    this.meaningIndex,
    this.exampleUsage,
  });

  PracticeQuestion copyWith({
    Entry? entry,
    PromptDirection? direction,
    QuestionFormat? format,
    bool? isRepeat,
    DistractorResult? distractorResult,
    int? meaningIndex,
    ExampleUsage? exampleUsage,
  }) {
    return PracticeQuestion(
      entry: entry ?? this.entry,
      direction: direction ?? this.direction,
      format: format ?? this.format,
      isRepeat: isRepeat ?? this.isRepeat,
      distractorResult: distractorResult ?? this.distractorResult,
      meaningIndex: meaningIndex ?? this.meaningIndex,
      exampleUsage: exampleUsage ?? this.exampleUsage,
    );
  }
}
