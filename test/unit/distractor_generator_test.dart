import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/domain/distractor_generator.dart';
import 'package:knew/src/features/practice/domain/practice_question.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';

void main() {
  Entry createEntry({
    required String id,
    required String english,
    required String pos,
    required List<String> hebrewTranslations,
  }) {
    return Entry.create(
      id: id,
      english: english,
      meanings: [
        Meaning(
          partOfSpeech: pos,
          definition: 'def of $english',
          hebrewTranslations: hebrewTranslations,
        ),
      ],
      level: 1,
      dueDate: '2026-09-15',
    );
  }

  group('DistractorGenerator - Basic Functionality & Formatting', () {
    final target = createEntry(
      id: 'target',
      english: 'persistent',
      pos: 'adjective',
      hebrewTranslations: ['עקשן', 'מתמיד'],
    );

    final library = [
      target,
      createEntry(id: '1', english: 'diligent', pos: 'adjective', hebrewTranslations: ['חרוץ']),
      createEntry(id: '2', english: 'stubborn', pos: 'adjective', hebrewTranslations: ['עקשן דפוק']), // distractor 2
      createEntry(id: '3', english: 'calm', pos: 'adjective', hebrewTranslations: ['רגוע']),
      createEntry(id: '4', english: 'run', pos: 'verb', hebrewTranslations: ['לרוץ']),
    ];

    test('English->Hebrew joins first meaning translations with comma', () {
      final rng = Random(42);
      final result = DistractorGenerator.generate(
        target: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
        random: rng,
      );

      expect(result.isAvailable, isTrue);
      expect(result.options.length, equals(4));
      expect(result.correctOption, equals('עקשן, מתמיד'));
      expect(result.options.contains('עקשן, מתמיד'), isTrue);
      expect(result.options[result.correctOptionIndex], equals('עקשן, מתמיד'));
    });

    test('Hebrew->English uses target English term', () {
      final rng = Random(42);
      final result = DistractorGenerator.generate(
        target: target,
        direction: PromptDirection.hebrewToEnglish,
        library: library,
        random: rng,
      );

      expect(result.isAvailable, isTrue);
      expect(result.options.length, equals(4));
      expect(result.correctOption, equals('persistent'));
      expect(result.options.contains('persistent'), isTrue);
      expect(result.options[result.correctOptionIndex], equals('persistent'));
    });
  });

  group('DistractorGenerator - Filtering & Ambiguity Rules', () {
    test('Excludes target entry and duplicate Hebrew translations', () {
      final target = createEntry(
        id: 'target',
        english: 'dog',
        pos: 'noun',
        hebrewTranslations: ['כלב'],
      );

      final library = [
        target,
        // Entry 1 has identical Hebrew translation to target -> MUST BE REJECTED
        createEntry(id: '1', english: 'hound', pos: 'noun', hebrewTranslations: ['כלב']),
        createEntry(id: '2', english: 'cat', pos: 'noun', hebrewTranslations: ['חתול']),
        createEntry(id: '3', english: 'bird', pos: 'noun', hebrewTranslations: ['ציפור']),
        createEntry(id: '4', english: 'fish', pos: 'noun', hebrewTranslations: ['דג']),
      ];

      final result = DistractorGenerator.generate(
        target: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
        random: Random(1),
      );

      expect(result.isAvailable, isTrue);
      expect(result.options.contains('כלב'), isTrue); // Correct option
      expect(result.options.where((o) => o == 'כלב').length, equals(1)); // No duplicate 'כלב'
      expect(result.options, containsAll(['כלב', 'חתול', 'ציפור', 'דג']));
    });

    test('Prefers entries with same part of speech before fallback', () {
      final target = createEntry(
        id: 'target',
        english: 'swift',
        pos: 'adjective',
        hebrewTranslations: ['מהיר'],
      );

      final samePos1 = createEntry(id: '1', english: 'fast', pos: 'adjective', hebrewTranslations: ['זריז']);
      final samePos2 = createEntry(id: '2', english: 'slow', pos: 'adjective', hebrewTranslations: ['איטי']);
      final samePos3 = createEntry(id: '3', english: 'big', pos: 'adjective', hebrewTranslations: ['גדול']);
      final diffPos = createEntry(id: '4', english: 'run', pos: 'verb', hebrewTranslations: ['לרוץ']);

      final library = [target, samePos1, samePos2, samePos3, diffPos];

      final result = DistractorGenerator.generate(
        target: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
        random: Random(42),
      );

      expect(result.isAvailable, isTrue);
      // All 3 distractors should be selected from same POS items ('fast', 'slow', 'big')
      expect(result.options, containsAll(['מהיר', 'זריז', 'איטי', 'גדול']));
      expect(result.options.contains('לרוץ'), isFalse);
    });

    test('Returns isAvailable = false if fewer than 3 valid distractors remain', () {
      final target = createEntry(
        id: 'target',
        english: 'one',
        pos: 'noun',
        hebrewTranslations: ['אחד'],
      );

      final library = [
        target,
        createEntry(id: '1', english: 'two', pos: 'noun', hebrewTranslations: ['שתיים']),
        createEntry(id: '2', english: 'three', pos: 'noun', hebrewTranslations: ['שלוש']),
        // Only 2 candidate entries in library (fewer than 3 distractors needed)
      ];

      final result = DistractorGenerator.generate(
        target: target,
        direction: PromptDirection.englishToHebrew,
        library: library,
      );

      expect(result.isAvailable, isFalse);
      expect(result.options, isEmpty);
    });
  });
}
