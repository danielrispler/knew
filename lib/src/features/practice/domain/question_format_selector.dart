import 'dart:math';
import '../../vocabulary/domain/entry.dart';
import 'distractor_generator.dart';
import 'practice_question.dart';

abstract class QuestionFormatSelector {
  /// Weights are deliberately data, so Phase 2 can enable its format without
  /// changing the selection rules.
  static const _weights = <List<int>>[
    [80, 0, 20, 0, 0],
    [50, 30, 20, 0, 0],
    [35, 30, 20, 15, 0],
    [25, 25, 20, 30, 0],
    [20, 20, 20, 40, 0],
    [15, 15, 15, 30, 25],
    [15, 15, 15, 30, 25],
  ];

  static List<double> computeWeights({
    required int levelSnapshot,
    required Set<QuestionFormat> availability,
    required List<QuestionFormat> recentFormats,
  }) {
    final row = _weights[levelSnapshot.clamp(0, 6)];
    final formats = QuestionFormat.values;
    final weights = List<double>.generate(
      formats.length,
      (i) => availability.contains(formats[i]) ? row[i].toDouble() : 0,
    );
    if (recentFormats.length >= 3 &&
        recentFormats
            .sublist(recentFormats.length - 3)
            .every((format) => format == recentFormats.last)) {
      final index = recentFormats.last.index;
      if (weights.where((weight) => weight > 0).length > 1) weights[index] = 0;
    }
    final total = weights.fold<double>(0, (sum, weight) => sum + weight);
    if (total == 0) return [1, 0, 0, 0];
    return weights.map((weight) => weight / total).toList();
  }

  static QuestionFormat selectFormat({
    required Entry entry,
    required PromptDirection direction,
    required List<Entry> library,
    required bool wasAboveLevelZeroAtSessionStart,
    required QuestionFormat? lastFormat,
    required int consecutiveCount,
    bool hasClozeExample = false,
    bool hasSentenceMeaning = false,
    bool sentenceProductionEnabled = true,
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
    if (hasClozeExample && entry.level >= 3)
      legalFormats.add(QuestionFormat.cloze);
    if (sentenceProductionEnabled && hasSentenceMeaning && entry.level >= 5) {
      legalFormats.add(QuestionFormat.sentenceProduction);
    }

    // 4. Apply 3-in-a-row constraint
    List<QuestionFormat> eligibleFormats = legalFormats;
    if (consecutiveCount >= 3 && lastFormat != null) {
      final filtered = legalFormats.where((f) => f != lastFormat).toList();
      if (filtered.isNotEmpty) {
        eligibleFormats = filtered;
      }
    }

    final weights = computeWeights(
      levelSnapshot: entry.level,
      availability: eligibleFormats.toSet(),
      recentFormats: consecutiveCount >= 3 && lastFormat != null
          ? [lastFormat, lastFormat, lastFormat]
          : const [],
    );
    var draw = rng.nextDouble();
    for (var i = 0; i < weights.length; i++) {
      draw -= weights[i];
      if (draw <= 0) return QuestionFormat.values[i];
    }
    return QuestionFormat.flashcard;
  }
}
