import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/domain/answer_checker.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';

void main() {
  group('StringNormalizer', () {
    test('trims leading/trailing whitespace and collapses internal whitespace', () {
      expect(StringNormalizer.normalize('  hello   world  '), equals('hello world'));
    });

    test('lowercases English text', () {
      expect(StringNormalizer.normalize('Persistent'), equals('persistent'));
    });

    test('strips Hebrew niqqud diacritics', () {
      // Hebrew word with niqqud: "שָׁלוֹם"
      final withNiqqud = 'שָׁלוֹם';
      final plain = 'שלום';
      expect(StringNormalizer.normalize(withNiqqud), equals(plain));
    });

    test('strips punctuation', () {
      expect(StringNormalizer.normalize('put up with, (v.)!'), equals('put up with v'));
    });

    test('handles mixed script with niqqud and punctuation', () {
      expect(StringNormalizer.normalize('  שָׁלוֹם, world! '), equals('שלום world'));
    });
  });

  group('AnswerChecker - Code point Levenshtein distance', () {
    test('returns exactMatch for identical normalized strings', () {
      final result = AnswerChecker.evaluate(
        userInput: '  Persistent ',
        expectedAnswers: ['persistent'],
      );
      expect(result.status, equals(AnswerCheckStatus.exactMatch));
      expect(result.matchedTarget, equals('persistent'));
    });

    test('returns typoMatch for 1 edit on length <= 5', () {
      // "hello" (len 5), "helo" (len 4, 1 delete) -> dist 1
      final result = AnswerChecker.evaluate(
        userInput: 'helo',
        expectedAnswers: ['hello'],
      );
      expect(result.status, equals(AnswerCheckStatus.typoMatch));
      expect(result.matchedTarget, equals('hello'));
    });

    test('rejects 2 edits on length <= 5', () {
      // "hello" (len 5), "heo" (len 3, 2 deletes) -> dist 2 > max 1
      final result = AnswerChecker.evaluate(
        userInput: 'heo',
        expectedAnswers: ['hello'],
      );
      expect(result.status, equals(AnswerCheckStatus.noMatch));
    });

    test('returns typoMatch for 2 edits on length > 5', () {
      // "persistent" (len 10), "persistentt" (1 insert) or "persistent" with 2 typos "perxistenn"
      final result = AnswerChecker.evaluate(
        userInput: 'perxistenn',
        expectedAnswers: ['persistent'],
      );
      expect(result.status, equals(AnswerCheckStatus.typoMatch));
      expect(result.matchedTarget, equals('persistent'));
    });

    test('rejects 3 edits on length > 5', () {
      // "persistent" (len 10), "perxxxxent" (3+ edits)
      final result = AnswerChecker.evaluate(
        userInput: 'perxxxxent',
        expectedAnswers: ['persistent'],
      );
      expect(result.status, equals(AnswerCheckStatus.noMatch));
    });

    test('rejects empty normalized input', () {
      final result = AnswerChecker.evaluate(
        userInput: '   !?, ',
        expectedAnswers: ['hello'],
      );
      expect(result.status, equals(AnswerCheckStatus.noMatch));
    });
  });

  group('AnswerChecker - Multi-meaning & Multi-translation matching', () {
    final entry = Entry.create(
      id: '1',
      english: 'put up with',
      meanings: [
        Meaning(
          partOfSpeech: 'verb',
          definition: 'tolerate',
          hebrewTranslations: ['לסבול', 'להשלים עם'],
        ),
        Meaning(
          partOfSpeech: 'verb',
          definition: 'endure',
          hebrewTranslations: ['לשתות בצמא'],
        ),
      ],
      level: 1,
      dueDate: '2026-09-15',
    );

    test('matches any Hebrew translation across any meaning for English->Hebrew', () {
      final check1 = AnswerChecker.checkHebrewAnswer(
        userInput: 'לסבול',
        entry: entry,
      );
      expect(check1.status, equals(AnswerCheckStatus.exactMatch));

      final check2 = AnswerChecker.checkHebrewAnswer(
        userInput: 'להשלים עם',
        entry: entry,
      );
      expect(check2.status, equals(AnswerCheckStatus.exactMatch));

      final check3 = AnswerChecker.checkHebrewAnswer(
        userInput: 'לשתות בצמא',
        entry: entry,
      );
      expect(check3.status, equals(AnswerCheckStatus.exactMatch));
    });

    test('strips niqqud when user enters Hebrew answer with niqqud', () {
      final check = AnswerChecker.checkHebrewAnswer(
        userInput: 'לִסְבּוֹל',
        entry: entry,
      );
      expect(check.status, equals(AnswerCheckStatus.exactMatch));
    });

    test('matches English term for Hebrew->English', () {
      final check = AnswerChecker.checkEnglishAnswer(
        userInput: 'Put up with',
        entry: entry,
      );
      expect(check.status, equals(AnswerCheckStatus.exactMatch));
    });
  });
}
