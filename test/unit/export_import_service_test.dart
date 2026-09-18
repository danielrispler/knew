import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/data/export_import_service.dart';

void main() {
  group('ExportImportService Payload & Validation Tests', () {
    late Entry validEntry;

    setUp(() {
      validEntry = Entry(
        id: '46e2cf36-d1b9-49b0-b481-8d85f8b6d0a1',
        english: 'persistent',
        englishKey: 'persistent',
        meanings: const [
          Meaning(
            partOfSpeech: 'adjective',
            hebrewTranslations: ['מתמיד', 'עיקש'],
            definition: 'continuing to try even when something is hard',
          ),
        ],
        source: 'A book',
        context: null,
        level: 2,
        dueDate: '2026-09-17',
        lastReviewedAt: '2026-09-15T08:00:00.000Z',
        timesCorrect: 2,
        timesWrong: 0,
        createdAt: '2026-09-13T08:00:00.000Z',
        updatedAt: '2026-09-15T08:00:00.000Z',
      );
    });

    test('generateExportPayload formats valid JSON v1 payload', () {
      final jsonStr = ExportImportService.generateExportPayload([validEntry]);
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;

      expect(map['version'], equals(1));
      expect(map['exportedAt'], isNotNull);
      final words = map['words'] as List;
      expect(words.length, equals(1));

      final first = words.first as Map<String, dynamic>;
      expect(first['id'], equals(validEntry.id));
      expect(first['english'], equals('persistent'));
      expect(first['level'], equals(2));
      expect(first['dueDate'], equals('2026-09-17'));
      expect(first['lastReviewedAt'], equals('2026-09-15T08:00:00.000Z'));
      expect(first['timesCorrect'], equals(2));
      expect(first['timesWrong'], equals(0));
    });

    test('validateAndParseImport accepts valid export payload', () {
      final jsonStr = ExportImportService.generateExportPayload([validEntry]);
      final entries = ExportImportService.validateAndParseImport(
        utf8.encode(jsonStr),
      );

      expect(entries.length, equals(1));
      expect(entries.first.id, equals(validEntry.id));
      expect(entries.first.english, equals(validEntry.english));
    });

    test('exports and parses optional discovery history', () {
      final jsonStr = ExportImportService.generateExportPayload(
        [validEntry],
        discovery: {
          'bandCenter': 42,
          'known': [
            {'key': 'known', 'updatedAt': '2026-09-15T08:00:00.000Z'},
          ],
          'learned': [
            {'key': 'learned', 'updatedAt': '2026-09-16T08:00:00.000Z'},
          ],
        },
      );

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(map['discovery'], isA<Map>());
      expect(
        ExportImportService.parseDiscoveryImport(utf8.encode(jsonStr)),
        equals(map['discovery']),
      );
    });

    test('accepts backups without discovery history', () {
      final jsonStr = ExportImportService.generateExportPayload([validEntry]);

      expect(
        ExportImportService.parseDiscoveryImport(utf8.encode(jsonStr)),
        isNull,
      );
    });

    test('rejects file larger than 10MB', () {
      final dummyBytes = List<int>.filled(10 * 1024 * 1024 + 1, 0);
      expect(
        () => ExportImportService.validateAndParseImport(dummyBytes),
        throwsA(
          isA<ExportImportException>().having(
            (e) => e.message,
            'message',
            contains('10 MB'),
          ),
        ),
      );
    });

    test('rejects unsupported backup version', () {
      final payload = {
        'version': 2,
        'exportedAt': '2026-09-15T09:00:00.000Z',
        'words': [],
      };
      expect(
        () => ExportImportService.validateAndParseImport(
          utf8.encode(jsonEncode(payload)),
        ),
        throwsA(
          isA<ExportImportException>().having(
            (e) => e.message,
            'message',
            contains('This backup needs a newer version of knew'),
          ),
        ),
      );
    });

    test('rejects invalid level 0 entry with lastReviewedAt', () {
      final payload = {
        'version': 1,
        'exportedAt': '2026-09-15T09:00:00.000Z',
        'words': [
          {
            'id': '46e2cf36-d1b9-49b0-b481-8d85f8b6d0a1',
            'english': 'invalid',
            'meanings': [
              {
                'partOfSpeech': 'noun',
                'hebrew': ['משהו'],
                'definition': 'something',
              },
            ],
            'level': 0,
            'dueDate': '2026-09-15',
            'lastReviewedAt': '2026-09-15T08:00:00.000Z',
            'timesCorrect': 0,
            'timesWrong': 0,
            'createdAt': '2026-09-15T08:00:00.000Z',
            'updatedAt': '2026-09-15T08:00:00.000Z',
          },
        ],
      };
      expect(
        () => ExportImportService.validateAndParseImport(
          utf8.encode(jsonEncode(payload)),
        ),
        throwsA(isA<ExportImportException>()),
      );
    });

    test('rejects duplicate terms inside file', () {
      final payload = {
        'version': 1,
        'exportedAt': '2026-09-15T09:00:00.000Z',
        'words': [
          {
            'id': '46e2cf36-d1b9-49b0-b481-8d85f8b6d0a1',
            'english': 'test',
            'meanings': [
              {
                'partOfSpeech': 'noun',
                'hebrew': ['בדיקה'],
                'definition': 'test',
              },
            ],
            'level': 0,
            'dueDate': '2026-09-15',
            'lastReviewedAt': null,
            'timesCorrect': 0,
            'timesWrong': 0,
            'createdAt': '2026-09-15T08:00:00.000Z',
            'updatedAt': '2026-09-15T08:00:00.000Z',
          },
          {
            'id': '55e2cf36-d1b9-49b0-b481-8d85f8b6d0a2',
            'english': 'Test', // duplicate term key
            'meanings': [
              {
                'partOfSpeech': 'noun',
                'hebrew': ['בדיקה'],
                'definition': 'test',
              },
            ],
            'level': 0,
            'dueDate': '2026-09-15',
            'lastReviewedAt': null,
            'timesCorrect': 0,
            'timesWrong': 0,
            'createdAt': '2026-09-15T08:00:00.000Z',
            'updatedAt': '2026-09-15T08:00:00.000Z',
          },
        ],
      };
      expect(
        () => ExportImportService.validateAndParseImport(
          utf8.encode(jsonEncode(payload)),
        ),
        throwsA(
          isA<ExportImportException>().having(
            (e) => e.message,
            'message',
            contains('Duplicate term key'),
          ),
        ),
      );
    });

    test('rejects invalid calendar date (e.g. 2026-02-30)', () {
      final payload = {
        'version': 1,
        'exportedAt': '2026-09-15T09:00:00.000Z',
        'words': [
          {
            'id': '46e2cf36-d1b9-49b0-b481-8d85f8b6d0a1',
            'english': 'test',
            'meanings': [
              {
                'partOfSpeech': 'noun',
                'hebrew': ['בדיקה'],
                'definition': 'test',
              },
            ],
            'level': 0,
            'dueDate': '2026-02-30', // Invalid calendar date
            'lastReviewedAt': null,
            'timesCorrect': 0,
            'timesWrong': 0,
            'createdAt': '2026-09-15T08:00:00.000Z',
            'updatedAt': '2026-09-15T08:00:00.000Z',
          },
        ],
      };
      expect(
        () => ExportImportService.validateAndParseImport(
          utf8.encode(jsonEncode(payload)),
        ),
        throwsA(
          isA<ExportImportException>().having(
            (e) => e.message,
            'message',
            contains('invalid calendar date'),
          ),
        ),
      );
    });
  });
}
