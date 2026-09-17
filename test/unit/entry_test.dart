import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/domain/example_usage.dart';

void main() {
  group('Meaning', () {
    test('serializes to and from JSON map', () {
      final meaning = Meaning(
        partOfSpeech: 'noun',
        definition: 'A short explanation in simple English.',
        hebrewTranslations: ['הסבר', 'פירוש'],
      );

      final json = meaning.toJson();
      final restored = Meaning.fromJson(json);

      expect(restored.partOfSpeech, 'noun');
      expect(restored.definition, 'A short explanation in simple English.');
      expect(restored.hebrewTranslations, ['הסבר', 'פירוש']);
    });

    test('reads legacy JSON and round-trips enrichment fields', () {
      final legacy = Meaning.fromJson({
        'partOfSpeech': 'noun',
        'definition': 'thing',
        'hebrewTranslations': ['דבר'],
      });
      expect(legacy.examples, isEmpty);
      expect(legacy.enrichedAt, isNull);
      final enriched = legacy.copyWith(
        examples: ['I [[thing]] so.'],
        collocations: ['a thing'],
        validInflections: ['things'],
        enrichedAt: '2026-09-17T00:00:00.000Z',
      );
      expect(Meaning.fromJson(enriched.toJson()).validInflections, ['things']);
    });

    test('accepts exactly one marked allowed target', () {
      final usage = ExampleUsage.parse('She [[ran]] home.', ['run', 'ran']);
      expect(usage?.sentence, 'She ran home.');
      expect(usage?.clozeSentence, 'She _____ home.');
      expect(
        ExampleUsage.parse('She [[walked]] [[home]].', ['walked']),
        isNull,
      );
    });
  });

  group('Entry', () {
    test('normalizes english term and generates english_key', () {
      final entry = Entry.create(
        english: '  put   up  with  ',
        meanings: [
          Meaning(
            partOfSpeech: 'verb',
            definition: 'To tolerate or accept.',
            hebrewTranslations: ['להשלים עם'],
          ),
        ],
      );

      expect(entry.english, 'put up with');
      expect(entry.englishKey, 'put up with');
      expect(entry.level, 0);
      expect(entry.stage, Stage.newStage);
      expect(entry.dueDate.length, 10);
    });

    test('stage is correctly derived from level', () {
      final entry0 = Entry.create(
        english: 'test',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'd',
            hebrewTranslations: ['t'],
          ),
        ],
        level: 0,
      );
      expect(entry0.stage, Stage.newStage);

      final entry2 = entry0.copyWith(level: 2);
      expect(entry2.stage, Stage.newStage);

      final entry3 = entry0.copyWith(level: 3);
      expect(entry3.stage, Stage.familiar);

      final entry4 = entry0.copyWith(level: 4);
      expect(entry4.stage, Stage.familiar);

      final entry5 = entry0.copyWith(level: 5);
      expect(entry5.stage, Stage.learned);

      final entry6 = entry0.copyWith(level: 6);
      expect(entry6.stage, Stage.learned);
    });

    test('serializes to and from SQLite map representation', () {
      final entry = Entry.create(
        id: '123e4567-e89b-12d3-a456-426614174000',
        english: 'persistent',
        meanings: [
          Meaning(
            partOfSpeech: 'adjective',
            definition: 'Continuing firmly in a course of action.',
            hebrewTranslations: ['עקשן', 'מתמיד'],
          ),
        ],
        source: 'reading',
        context: 'He was persistent in his studies.',
      );

      final dbMap = entry.toDatabaseMap();
      final restored = Entry.fromDatabaseMap(dbMap);

      expect(restored.id, entry.id);
      expect(restored.english, 'persistent');
      expect(restored.englishKey, 'persistent');
      expect(restored.meanings.length, 1);
      expect(restored.meanings.first.hebrewTranslations, ['עקשן', 'מתמיד']);
      expect(restored.source, 'reading');
      expect(restored.context, 'He was persistent in his studies.');
      expect(restored.level, 0);
      expect(restored.timesCorrect, 0);
      expect(restored.timesWrong, 0);
    });
  });
}
