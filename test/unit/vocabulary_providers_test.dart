import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/features/vocabulary/data/sqlite_words_repository.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';

void main() {
  group('Vocabulary Providers', () {
    late Database db;
    late WordsRepository wordsRepository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await SQLiteDatabaseHelper.createTables(db);
        },
      );
      wordsRepository = SQLiteWordsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('vocabularyListNotifier loads entries from repository', () async {
      final entry = Entry.create(
        english: 'eloquent',
        meanings: [
          Meaning(partOfSpeech: 'adj', definition: 'Fluent or persuasive', hebrewTranslations: ['רהוט'])
        ],
      );
      await wordsRepository.insertEntry(entry);

      final container = ProviderContainer(
        overrides: [
          wordsRepositoryProvider.overrideWithValue(wordsRepository),
        ],
      );
      addTearDown(container.dispose);

      final state = await container.read(vocabularyListProvider.future);
      expect(state.length, 1);
      expect(state.first.english, 'eloquent');
    });

    test('deleting an entry refreshes vocabularyListProvider state', () async {
      final entry = Entry.create(
        english: 'tenacious',
        meanings: [
          Meaning(partOfSpeech: 'adj', definition: 'Persistent', hebrewTranslations: ['עקשן'])
        ],
      );
      await wordsRepository.insertEntry(entry);

      final container = ProviderContainer(
        overrides: [
          wordsRepositoryProvider.overrideWithValue(wordsRepository),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(vocabularyListProvider.notifier);
      await container.read(vocabularyListProvider.future);

      await notifier.deleteEntry(entry.id);

      final stateAfterDelete = await container.read(vocabularyListProvider.future);
      expect(stateAfterDelete.isEmpty, isTrue);
    });
  });
}
