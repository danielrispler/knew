import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/domain/practice_question.dart';
import 'package:knew/src/features/practice/domain/question_format_selector.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';

void main() {
  Entry createEntry({
    required String id,
    required int level,
    String pos = 'noun',
  }) {
    return Entry.create(
      id: id,
      english: 'word_$id',
      meanings: [
        Meaning(
          partOfSpeech: pos,
          definition: 'def',
          hebrewTranslations: ['תרגום_$id'],
        ),
      ],
      level: level,
      dueDate: '2026-09-15',
    );
  }

  group('QuestionFormatSelector - Legality Rules', () {
    test('Level 0 entry only allows flashcard when MC distractors are unavailable', () {
      final target = createEntry(id: '1', level: 0);
      final library = [target]; // < 4 entries, so MC unavailable

      final format = QuestionFormatSelector.selectFormat(
        entry: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
        wasAboveLevelZeroAtSessionStart: false,
        lastFormat: null,
        consecutiveCount: 0,
      );

      expect(format, equals(QuestionFormat.flashcard));
    });

    test('Level 0 entry allows Multiple Choice when 3 distractors exist, but typing is illegal', () {
      final target = createEntry(id: 'target', level: 0);
      final library = [
        target,
        createEntry(id: '1', level: 1),
        createEntry(id: '2', level: 1),
        createEntry(id: '3', level: 1),
      ];

      // Run multiple iterations with different seeds
      final selectedFormats = <QuestionFormat>{};
      for (int i = 0; i < 20; i++) {
        final format = QuestionFormatSelector.selectFormat(
          entry: target,
          direction: PromptDirection.englishToHebrew,
          library: library,
          wasAboveLevelZeroAtSessionStart: false,
          lastFormat: null,
          consecutiveCount: 0,
          random: Random(i),
        );
        selectedFormats.add(format);
      }

      expect(selectedFormats.contains(QuestionFormat.typing), isFalse);
      expect(selectedFormats.contains(QuestionFormat.flashcard), isTrue);
      expect(selectedFormats.contains(QuestionFormat.multipleChoice), isTrue);
    });

    test('Level 1+ entry allows Typing', () {
      final target = createEntry(id: 'target', level: 1);
      final library = [target]; // < 4 entries, so MC unavailable

      final selectedFormats = <QuestionFormat>{};
      for (int i = 0; i < 20; i++) {
        final format = QuestionFormatSelector.selectFormat(
          entry: target,
          direction: PromptDirection.englishToHebrew,
          library: library,
          wasAboveLevelZeroAtSessionStart: true,
          lastFormat: null,
          consecutiveCount: 0,
          random: Random(i),
        );
        selectedFormats.add(format);
      }

      expect(selectedFormats.contains(QuestionFormat.flashcard), isTrue);
      expect(selectedFormats.contains(QuestionFormat.typing), isTrue);
    });

    test('Enforces 3-in-a-row format limit when alternative legal format exists', () {
      final target = createEntry(id: 'target', level: 1);
      final library = [target]; // Flashcard and Typing legal

      // 3 consecutive flashcards
      final format = QuestionFormatSelector.selectFormat(
        entry: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
        wasAboveLevelZeroAtSessionStart: true,
        lastFormat: QuestionFormat.flashcard,
        consecutiveCount: 3,
      );

      expect(format, equals(QuestionFormat.typing));
    });

    test('3-in-a-row limit yields when flashcard is the ONLY legal format', () {
      final target = createEntry(id: 'target', level: 0);
      final library = [target]; // Only Flashcard is legal

      final format = QuestionFormatSelector.selectFormat(
        entry: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
        wasAboveLevelZeroAtSessionStart: false,
        lastFormat: QuestionFormat.flashcard,
        consecutiveCount: 3,
      );

      expect(format, equals(QuestionFormat.flashcard));
    });
  });
}
