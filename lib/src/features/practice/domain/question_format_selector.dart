import 'dart:math';
import '../../vocabulary/domain/entry.dart';
import 'distractor_generator.dart';
import 'practice_question.dart';

abstract class QuestionFormatSelector {
  static QuestionFormat selectFormat({
    required Entry entry,
    required PromptDirection direction,
    required List<Entry> library,
    required bool wasAboveLevelZeroAtSessionStart,
    required QuestionFormat? lastFormat,
    required int consecutiveCount,
    Random? random,
  }) {
    final rng = random ?? Random();

    // 1. Flashcard is always legal
    final legalFormats = <QuestionFormat>[QuestionFormat.flashcard];

    // 2. Typing is legal if entry level > 0 at session start
    if (wasAboveLevelZeroAtSessionStart) {
      legalFormats.add(QuestionFormat.typing);
    }

    // 3. Multiple choice is legal if 3 distinct, unambiguous distractors exist
    final distractorResult = DistractorGenerator.generate(
      target: entry,
      direction: direction,
      library: library,
      random: rng,
    );

    if (distractorResult.isAvailable) {
      legalFormats.add(QuestionFormat.multipleChoice);
    }

    // 4. Apply 3-in-a-row constraint
    List<QuestionFormat> eligibleFormats = legalFormats;
    if (consecutiveCount >= 3 && lastFormat != null) {
      final filtered = legalFormats.where((f) => f != lastFormat).toList();
      if (filtered.isNotEmpty) {
        eligibleFormats = filtered;
      }
    }

    // 5. Pick uniformly from remaining formats
    eligibleFormats.sort((a, b) => a.index.compareTo(b.index));
    final index = rng.nextInt(eligibleFormats.length);
    return eligibleFormats[index];
  }
}
