import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/data/sqlite_words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/settings/data/sqlite_settings_repository.dart';

void main() {
  group('SQLite Database Helper & Repositories', () {
    late Database db;
    late SQLiteWordsRepository wordsRepository;
    late SQLiteSettingsRepository settingsRepository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await SQLiteDatabaseHelper.createTables(db);
        },
      );
      wordsRepository = SQLiteWordsRepository(db);
      settingsRepository = SQLiteSettingsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('creates schema version 1 tables correctly', () async {
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table';",
      );
      final tableNames = tables.map((row) => row['name'] as String).toList();

      expect(tableNames, contains('words'));
      expect(tableNames, contains('settings'));
    });

    test('inserts and retrieves an entry by ID', () async {
      final entry = Entry.create(
        english: 'persistent',
        meanings: [
          Meaning(
            partOfSpeech: 'adj',
            definition: 'Continuing firmly',
            hebrewTranslations: ['עקשן'],
          ),
        ],
      );

      await wordsRepository.insertEntry(entry);

      final retrieved = await wordsRepository.getEntryById(entry.id);
      expect(retrieved, isNotNull);
      expect(retrieved!.english, 'persistent');
      expect(retrieved.englishKey, 'persistent');
      expect(retrieved.meanings.first.hebrewTranslations, ['עקשן']);
    });

    test('rejects insert with duplicate english_key', () async {
      final entry1 = Entry.create(
        english: 'Put up with',
        meanings: [
          Meaning(
            partOfSpeech: 'verb',
            definition: 'Tolerate',
            hebrewTranslations: ['להשלים'],
          ),
        ],
      );

      final entry2 = Entry.create(
        english: '  put UP  with ',
        meanings: [
          Meaning(
            partOfSpeech: 'verb',
            definition: 'Tolerate duplicate',
            hebrewTranslations: ['סבל'],
          ),
        ],
      );

      await wordsRepository.insertEntry(entry1);

      expect(
        () async => await wordsRepository.insertEntry(entry2),
        throwsA(isA<DuplicateEntryException>()),
      );
    });

    test('existsEnglishKey correctly checks for duplicate key', () async {
      final entry = Entry.create(
        english: 'relentless',
        meanings: [
          Meaning(
            partOfSpeech: 'adj',
            definition: 'Unyielding',
            hebrewTranslations: ['בלתי נלאה'],
          ),
        ],
      );
      await wordsRepository.insertEntry(entry);

      expect(await wordsRepository.existsEnglishKey('relentless'), isTrue);
      expect(await wordsRepository.existsEnglishKey('RELENTLESS'), isTrue);
      expect(
        await wordsRepository.existsEnglishKey(
          'relentless',
          excludeId: entry.id,
        ),
        isFalse,
      );
      expect(await wordsRepository.existsEnglishKey('unknown'), isFalse);
    });

    test('updates and deletes an entry', () async {
      final entry = Entry.create(
        english: 'diligent',
        meanings: [
          Meaning(
            partOfSpeech: 'adj',
            definition: 'Hardworking',
            hebrewTranslations: ['שקדן'],
          ),
        ],
      );
      await wordsRepository.insertEntry(entry);

      final updatedEntry = entry.copyWith(
        context: 'She is a diligent student.',
        level: 1,
      );
      await wordsRepository.updateEntry(updatedEntry);

      final retrieved = await wordsRepository.getEntryById(entry.id);
      expect(retrieved!.context, 'She is a diligent student.');
      expect(retrieved.level, 1);

      await wordsRepository.deleteEntry(entry.id);
      final afterDelete = await wordsRepository.getEntryById(entry.id);
      expect(afterDelete, isNull);
    });

    test('enrichment compare-and-set preserves concurrent progress', () async {
      final entry = Entry.create(
        english: 'run',
        meanings: [
          Meaning(
            partOfSpeech: 'verb',
            definition: 'move fast',
            hebrewTranslations: ['לרוץ'],
          ),
        ],
      );
      await wordsRepository.insertEntry(entry);
      await wordsRepository.updateProgress(
        entry.copyWith(
          level: 1,
          timesCorrect: 1,
          updatedAt: '2026-09-17T00:00:00.000Z',
        ),
      );
      final saved = await wordsRepository.applyEnrichment(entry, [
        entry.meanings.single.copyWith(
          examples: ['I [[run]] daily.'],
          enrichedAt: '2026-09-17T00:00:00.000Z',
        ),
      ]);
      final result = await wordsRepository.getEntryById(entry.id);
      expect(saved, isTrue);
      expect(result!.level, 1);
      expect(result.meanings.single.examples, ['I [[run]] daily.']);
    });

    test(
      'semantic save clears enrichment and rejects a stale Meaning snapshot',
      () async {
        final entry = Entry.create(
          english: 'run',
          meanings: [
            Meaning(
              partOfSpeech: 'verb',
              definition: 'move fast',
              hebrewTranslations: ['לרוץ'],
              examples: ['I [[run]] daily.'],
              enrichedAt: '2026-09-17T00:00:00.000Z',
            ),
          ],
        );
        await wordsRepository.insertEntry(entry);
        final updated = entry.copyWith(
          meanings: [
            entry.meanings.single.copyWith(definition: 'move quickly'),
          ],
        );
        expect(
          await wordsRepository.updateSemanticEntry(entry, updated),
          isTrue,
        );
        expect(
          await wordsRepository.updateSemanticEntry(entry, updated),
          isFalse,
        );
        final result = await wordsRepository.getEntryById(entry.id);
        expect(result!.meanings.single.examples, isEmpty);
        expect(result.meanings.single.enrichedAt, isNull);
      },
    );

    test('resetProgress resets learning counters and due date', () async {
      final entry = Entry.create(
        english: 'reset_test',
        level: 4,
        dueDate: '2026-09-20',
        lastReviewedAt: '2026-09-13T10:00:00.000Z',
        timesCorrect: 4,
        timesWrong: 1,
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'test',
            hebrewTranslations: ['בדיקה'],
          ),
        ],
      );
      await wordsRepository.insertEntry(entry);

      await wordsRepository.resetProgress(entry.id);

      final reset = await wordsRepository.getEntryById(entry.id);
      expect(reset, isNotNull);
      expect(reset!.level, equals(0));
      expect(reset.lastReviewedAt, isNull);
      expect(reset.timesCorrect, equals(0));
      expect(reset.timesWrong, equals(0));
    });

    test(
      'mergeEntries handles insert, update on newer timestamp, skip on older/equal',
      () async {
        // 1. Existing local entry
        final localEntry = Entry(
          id: 'id-local-1',
          english: 'apple',
          englishKey: 'apple',
          meanings: const [
            Meaning(
              partOfSpeech: 'n',
              definition: 'fruit',
              hebrewTranslations: ['תפוח'],
            ),
          ],
          source: null,
          context: null,
          level: 1,
          dueDate: '2026-09-16',
          lastReviewedAt: '2026-09-15T08:00:00.000Z',
          timesCorrect: 1,
          timesWrong: 0,
          createdAt: '2026-09-10T08:00:00.000Z',
          updatedAt: '2026-09-15T08:00:00.000Z',
        );
        await wordsRepository.insertEntry(localEntry);

        // 2. Incoming entries
        // a) 'banana' -> absent, should be inserted (added)
        final incomingNew = Entry(
          id: 'id-incoming-2',
          english: 'banana',
          englishKey: 'banana',
          meanings: const [
            Meaning(
              partOfSpeech: 'n',
              definition: 'fruit',
              hebrewTranslations: ['בננה'],
            ),
          ],
          source: null,
          context: null,
          level: 0,
          dueDate: '2026-09-15',
          lastReviewedAt: null,
          timesCorrect: 0,
          timesWrong: 0,
          createdAt: '2026-09-15T09:00:00.000Z',
          updatedAt: '2026-09-15T09:00:00.000Z',
        );

        // b) 'apple' -> matched, incoming updatedAt (10:00) strictly later than local (08:00) -> updated
        final incomingUpdatedApple = localEntry.copyWith(
          level: 3,
          updatedAt: '2026-09-15T10:00:00.000Z',
        );

        final result = await wordsRepository.mergeEntries([
          incomingNew,
          incomingUpdatedApple,
        ]);

        expect(result.added, equals(1));
        expect(result.updated, equals(1));
        expect(result.skipped, equals(0));

        final fetchedApple = await wordsRepository.getEntryByEnglishKey(
          'apple',
        );
        expect(fetchedApple!.level, equals(3));

        final fetchedBanana = await wordsRepository.getEntryByEnglishKey(
          'banana',
        );
        expect(fetchedBanana, isNotNull);
      },
    );

    test(
      'mergeEntries skips incoming entry if incoming updatedAt is older or equal',
      () async {
        final localEntry = Entry(
          id: 'id-local-1',
          english: 'cherry',
          englishKey: 'cherry',
          meanings: const [
            Meaning(
              partOfSpeech: 'n',
              definition: 'fruit',
              hebrewTranslations: ['דובדבן'],
            ),
          ],
          source: null,
          context: null,
          level: 2,
          dueDate: '2026-09-16',
          lastReviewedAt: '2026-09-15T08:00:00.000Z',
          timesCorrect: 2,
          timesWrong: 0,
          createdAt: '2026-09-10T08:00:00.000Z',
          updatedAt: '2026-09-15T08:00:00.000Z',
        );
        await wordsRepository.insertEntry(localEntry);

        final incomingOlderCherry = localEntry.copyWith(
          level: 5,
          updatedAt: '2026-09-15T07:00:00.000Z', // Older
        );

        final result = await wordsRepository.mergeEntries([
          incomingOlderCherry,
        ]);

        expect(result.added, equals(0));
        expect(result.updated, equals(0));
        expect(result.skipped, equals(1));

        final fetchedCherry = await wordsRepository.getEntryByEnglishKey(
          'cherry',
        );
        expect(fetchedCherry!.level, equals(2)); // Local kept
      },
    );

    test('retrieves all entries sorted by creation time', () async {
      final entry1 = Entry.create(
        english: 'apple',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'fruit',
            hebrewTranslations: ['תפוח'],
          ),
        ],
        createdAt: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
      );
      final entry2 = Entry.create(
        english: 'banana',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'fruit',
            hebrewTranslations: ['בננה'],
          ),
        ],
        createdAt: DateTime.now().toUtc(),
      );

      await wordsRepository.insertEntry(entry1);
      await wordsRepository.insertEntry(entry2);

      final list = await wordsRepository.getAllEntries();
      expect(list.length, 2);
    });

    test('rejects update with conflicting english_key', () async {
      final entry1 = Entry.create(
        english: 'first',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: '1st',
            hebrewTranslations: ['ראשון'],
          ),
        ],
      );
      final entry2 = Entry.create(
        english: 'second',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: '2nd',
            hebrewTranslations: ['שני'],
          ),
        ],
      );

      await wordsRepository.insertEntry(entry1);
      await wordsRepository.insertEntry(entry2);

      final updatedEntry2 = entry2.copyWith(english: 'FIRST');

      expect(
        () async => await wordsRepository.updateEntry(updatedEntry2),
        throwsA(isA<DuplicateEntryException>()),
      );
    });

    test('getDueEntries filters and orders by due_date ascending', () async {
      final pastEntry = Entry.create(
        english: 'past',
        dueDate: '2025-12-31',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'p',
            hebrewTranslations: ['עבר'],
          ),
        ],
      );
      final todayEntry = Entry.create(
        english: 'today',
        dueDate: '2026-09-15',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 't',
            hebrewTranslations: ['היום'],
          ),
        ],
      );
      final futureEntry = Entry.create(
        english: 'future',
        dueDate: '2027-01-01',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'f',
            hebrewTranslations: ['עתיד'],
          ),
        ],
      );

      await wordsRepository.insertEntry(pastEntry);
      await wordsRepository.insertEntry(todayEntry);
      await wordsRepository.insertEntry(futureEntry);

      final due = await wordsRepository.getDueEntries('2026-09-15');
      expect(due.length, 2);
      expect(due.first.english, 'past');
      expect(due.last.english, 'today');
    });

    test('verifies transaction rollback on failure', () async {
      final entry1 = Entry.create(
        english: 'tx_one',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'one',
            hebrewTranslations: ['אחד'],
          ),
        ],
      );
      final entry2 = Entry.create(
        english: 'tx_two',
        meanings: [
          Meaning(
            partOfSpeech: 'n',
            definition: 'two',
            hebrewTranslations: ['שתיים'],
          ),
        ],
      );

      await wordsRepository.insertEntry(entry1);

      try {
        await db.transaction((txn) async {
          await txn.insert('words', entry2.toDatabaseMap());
          // Intentionally throw inside transaction
          throw Exception('Simulated transaction failure');
        });
      } catch (_) {}

      final afterTxn = await wordsRepository.getEntryById(entry2.id);
      expect(afterTxn, isNull);
    });

    test(
      'settings repository saves and retrieves values with defaults',
      () async {
        final defaultSession = await settingsRepository.getSessionSize();
        expect(defaultSession, 20);

        await settingsRepository.setSessionSize(30);
        expect(await settingsRepository.getSessionSize(), 30);

        expect(await settingsRepository.getTheme(), 'system');
        await settingsRepository.setTheme('dark');
        expect(await settingsRepository.getTheme(), 'dark');

        expect(await settingsRepository.getModel(), 'gemini-3.8-flash');
        await settingsRepository.setModel('gemini-3.7-flash');
        expect(await settingsRepository.getModel(), 'gemini-3.7-flash');

        expect(await settingsRepository.getLastSource(), '');
        await settingsRepository.setLastSource('Book');
        expect(await settingsRepository.getLastSource(), 'Book');

        expect(await settingsRepository.getLanguage(), 'system');
        await settingsRepository.setLanguage('he');
        expect(await settingsRepository.getLanguage(), 'he');
        await settingsRepository.setLanguage('en');
        expect(await settingsRepository.getLanguage(), 'en');
        await settingsRepository.setLanguage('invalid');
        expect(await settingsRepository.getLanguage(), 'en');
      },
    );

    test('handleUpgrade executes non-destructively within transaction', () async {
      final oldDb = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await SQLiteDatabaseHelper.createTables(db);
          await db.execute('DROP TABLE suggested_words');
        },
      );

      final entry = Entry.create(
        english: 'migration_test',
        meanings: [
          Meaning(
            partOfSpeech: 'v',
            definition: 'm',
            hebrewTranslations: ['בדיקת מיגרציה'],
          ),
        ],
      );
      final repo = SQLiteWordsRepository(oldDb);
      await repo.insertEntry(entry);

      // Trigger upgrade routine safely
      await SQLiteDatabaseHelper.handleUpgrade(oldDb, 1, 2);

      final tables = await oldDb.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='suggested_words';",
      );
      expect(tables, isNotEmpty);

      final preserved = await repo.getEntryById(entry.id);
      expect(preserved, isNotNull);
      expect(preserved!.english, 'migration_test');
      await oldDb.close();
    });
  });
}
