import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/data/sqlite_words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/settings/data/sqlite_settings_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

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
          Meaning(partOfSpeech: 'verb', definition: 'Tolerate', hebrewTranslations: ['להשלים']),
        ],
      );

      final entry2 = Entry.create(
        english: '  put UP  with ',
        meanings: [
          Meaning(partOfSpeech: 'verb', definition: 'Tolerate duplicate', hebrewTranslations: ['סבל']),
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
          Meaning(partOfSpeech: 'adj', definition: 'Unyielding', hebrewTranslations: ['בלתי נלאה']),
        ],
      );
      await wordsRepository.insertEntry(entry);

      expect(await wordsRepository.existsEnglishKey('relentless'), isTrue);
      expect(await wordsRepository.existsEnglishKey('RELENTLESS'), isTrue);
      expect(await wordsRepository.existsEnglishKey('relentless', excludeId: entry.id), isFalse);
      expect(await wordsRepository.existsEnglishKey('unknown'), isFalse);
    });

    test('updates and deletes an entry', () async {
      final entry = Entry.create(
        english: 'diligent',
        meanings: [
          Meaning(partOfSpeech: 'adj', definition: 'Hardworking', hebrewTranslations: ['שקדן']),
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

    test('retrieves all entries sorted by creation time', () async {
      final entry1 = Entry.create(
        english: 'apple',
        meanings: [Meaning(partOfSpeech: 'n', definition: 'fruit', hebrewTranslations: ['תפוח'])],
        createdAt: DateTime.now().toUtc().subtract(const Duration(seconds: 10)),
      );
      final entry2 = Entry.create(
        english: 'banana',
        meanings: [Meaning(partOfSpeech: 'n', definition: 'fruit', hebrewTranslations: ['בננה'])],
        createdAt: DateTime.now().toUtc(),
      );

      await wordsRepository.insertEntry(entry1);
      await wordsRepository.insertEntry(entry2);

      final list = await wordsRepository.getAllEntries();
      expect(list.length, 2);
    });

    test('settings repository saves and retrieves values with defaults', () async {
      final defaultSession = await settingsRepository.getSessionSize();
      expect(defaultSession, 20);

      await settingsRepository.setSessionSize(30);
      expect(await settingsRepository.getSessionSize(), 30);

      expect(await settingsRepository.getTheme(), 'system');
      await settingsRepository.setTheme('dark');
      expect(await settingsRepository.getTheme(), 'dark');

      expect(await settingsRepository.getModel(), 'gemini-2.5-flash');
      await settingsRepository.setModel('gemini-1.5-pro');
      expect(await settingsRepository.getModel(), 'gemini-1.5-pro');

      expect(await settingsRepository.getLastSource(), '');
      await settingsRepository.setLastSource('Book');
      expect(await settingsRepository.getLastSource(), 'Book');
    });
  });
}
