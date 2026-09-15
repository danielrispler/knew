import 'dart:math';
import '../../vocabulary/domain/entry.dart';
import 'answer_checker.dart';
import 'practice_question.dart';

class DistractorResult {
  final bool isAvailable;
  final List<String> options;
  final int correctOptionIndex;
  final String correctOption;

  const DistractorResult({
    required this.isAvailable,
    required this.options,
    required this.correctOptionIndex,
    required this.correctOption,
  });

  factory DistractorResult.unavailable() {
    return const DistractorResult(
      isAvailable: false,
      options: [],
      correctOptionIndex: -1,
      correctOption: '',
    );
  }
}

abstract class DistractorGenerator {
  static DistractorResult generate({
    required Entry target,
    required PromptDirection direction,
    required List<Entry> library,
    Random? random,
  }) {
    if (library.length < 4 || target.meanings.isEmpty) {
      return DistractorResult.unavailable();
    }

    final rng = random ?? Random();

    // 1. Determine correct option rendering
    final correctOption = direction == PromptDirection.englishToHebrew
        ? target.meanings.first.hebrewTranslations.join(', ')
        : target.english;

    final normalizedCorrectOption = StringNormalizer.normalize(correctOption);
    if (normalizedCorrectOption.isEmpty) {
      return DistractorResult.unavailable();
    }

    // 2. Gather normalized accepted target translations for ambiguity checks
    final targetAcceptedNormalized = <String>{};
    if (direction == PromptDirection.englishToHebrew) {
      for (final meaning in target.meanings) {
        for (final tr in meaning.hebrewTranslations) {
          final norm = StringNormalizer.normalize(tr);
          if (norm.isNotEmpty) {
            targetAcceptedNormalized.add(norm);
          }
        }
      }
    } else {
      targetAcceptedNormalized.add(StringNormalizer.normalize(target.english));
    }

    // 3. Separate library candidates (excluding target) by Part of Speech
    final candidates = library.where((e) => e.id != target.id).toList();

    final targetPos = target.meanings.first.partOfSpeech;
    final samePosGroup = <Entry>[];
    final diffPosGroup = <Entry>[];

    for (final candidate in candidates) {
      if (candidate.meanings.isNotEmpty &&
          candidate.meanings.first.partOfSpeech == targetPos) {
        samePosGroup.add(candidate);
      } else {
        diffPosGroup.add(candidate);
      }
    }

    // Shuffle each group for deterministic/reproducible randomness
    samePosGroup.shuffle(rng);
    diffPosGroup.shuffle(rng);

    final orderedCandidates = [...samePosGroup, ...diffPosGroup];

    // 4. Select 3 valid distractors
    final selectedDistractors = <String>[];
    final selectedNormalized = <String>{normalizedCorrectOption};

    for (final candidate in orderedCandidates) {
      if (candidate.meanings.isEmpty) continue;

      final candRendering = direction == PromptDirection.englishToHebrew
          ? candidate.meanings.first.hebrewTranslations.join(', ')
          : candidate.english;

      final candNorm = StringNormalizer.normalize(candRendering);
      if (candNorm.isEmpty || selectedNormalized.contains(candNorm)) {
        continue;
      }

      // Ambiguity check for Hebrew options
      if (direction == PromptDirection.englishToHebrew) {
        bool isAmbiguous = false;
        for (final candTr in candidate.meanings.first.hebrewTranslations) {
          final normCandTr = StringNormalizer.normalize(candTr);
          if (targetAcceptedNormalized.contains(normCandTr)) {
            isAmbiguous = true;
            break;
          }
        }
        if (isAmbiguous) continue;
      }

      selectedDistractors.add(candRendering);
      selectedNormalized.add(candNorm);

      if (selectedDistractors.length == 3) {
        break;
      }
    }

    if (selectedDistractors.length < 3) {
      return DistractorResult.unavailable();
    }

    // 5. Combine and shuffle options
    final options = [correctOption, ...selectedDistractors];
    options.shuffle(rng);

    final correctIndex = options.indexOf(correctOption);

    return DistractorResult(
      isAvailable: true,
      options: options,
      correctOptionIndex: correctIndex,
      correctOption: correctOption,
    );
  }
}
