import '../../vocabulary/domain/entry.dart';

enum PromptDirection {
  englishToHebrew,
  hebrewToEnglish,
}

enum QuestionFormat {
  flashcard,
  typing,
  multipleChoice,
}

class PracticeQuestion {
  final Entry entry;
  final PromptDirection direction;
  final QuestionFormat format;
  final bool isRepeat;

  const PracticeQuestion({
    required this.entry,
    required this.direction,
    this.format = QuestionFormat.flashcard,
    this.isRepeat = false,
  });

  PracticeQuestion copyWith({
    Entry? entry,
    PromptDirection? direction,
    QuestionFormat? format,
    bool? isRepeat,
  }) {
    return PracticeQuestion(
      entry: entry ?? this.entry,
      direction: direction ?? this.direction,
      format: format ?? this.format,
      isRepeat: isRepeat ?? this.isRepeat,
    );
  }
}
