import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/features/discover/data/suggested_words_repository.dart';
import 'package:knew/src/features/reading/data/chapter_words_repository.dart';
import 'package:knew/src/features/reading/domain/reading.dart';
import 'package:knew/src/features/vocabulary/data/sqlite_words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

ChapterWord word(String term) => ChapterWord(
  key: term.toLowerCase(),
  term: term,
  hebrew: 'עברית',
  definition: 'A definition.',
);

void main() {
  late Database db;
  late ChapterWordsRepository repository;
  final chapter5 = Reading(readingBooks.first, 5);
  final chapter6 = Reading(readingBooks.first, 6);

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: SQLiteDatabaseHelper.currentSchemaVersion,
      onCreate: (db, _) => SQLiteDatabaseHelper.createTables(db),
    );
    repository = ChapterWordsRepository(db);
  });
  tearDown(() => db.close());

  Future<List<String>> waiting(Reading reading) async =>
      (await repository.words(reading)).map((w) => w.key).toList();

  test('remembers the Reading and defaults to book 1 chapter 1', () async {
    var reading = await repository.reading();
    expect(reading.book.number, 1);
    expect(reading.chapter, 1);

    await repository.setReading(Reading(readingBooks[6], 37));
    reading = await repository.reading();
    expect(reading.book.number, 7);
    expect(reading.isEpilogue, isTrue);
    expect(reading.source, 'Harry Potter 7 · epilogue');
    expect(chapter5.source, 'Harry Potter 1 · ch. 5');
  });

  test('caches a chapter and ignores repeats and non-words', () async {
    expect(await repository.hasWords(chapter5), isFalse);

    await repository.save(chapter5, [
      word('vault'),
      word('Dodge'),
      word('Expelliarmus 2'),
    ]);
    await repository.save(chapter5, [word('vault'), word('gleam')]);

    expect(await repository.hasWords(chapter5), isTrue);
    expect(await waiting(chapter5), ['vault', 'dodge', 'gleam']);
    expect(await repository.alreadySuggested(chapter5), [
      'vault',
      'Dodge',
      'gleam',
    ]);
    expect(await repository.hasWords(chapter6), isFalse);
  });

  test(
    'Skip hides a word for its chapter only and keeps it suggested',
    () async {
      await repository.save(chapter5, [word('vault')]);
      await repository.save(chapter6, [word('vault')]);

      await repository.skip(chapter5, 'vault');

      expect(await waiting(chapter5), isEmpty);
      expect(await repository.alreadySuggested(chapter5), ['vault']);
      expect(await waiting(chapter6), ['vault']);
    },
  );

  test('Known is shared with Discover and applies to every chapter', () async {
    await repository.save(chapter5, [word('vault'), word('dodge')]);
    await repository.save(chapter6, [word('vault')]);

    await repository.known(word('vault'));

    expect(await waiting(chapter5), ['dodge']);
    expect(await waiting(chapter6), isEmpty);
    final discover = await SuggestedWordsRepository(db).exportHistory();
    expect((discover['known'] as List).single['key'], 'vault');
    expect(await repository.recentTerms('known'), ['vault']);
  });

  test('a word marked Known in Discover is not waiting in Reading', () async {
    await SuggestedWordsRepository(db).markKnownTerm('vault', 'vault');
    await repository.save(chapter5, [word('vault'), word('dodge')]);
    expect(await waiting(chapter5), ['dodge']);
  });

  test('a word becomes learned only once it is in the library', () async {
    await repository.save(chapter5, [word('vault'), word('dodge')]);
    expect(await repository.recentTerms('learned'), isEmpty);

    await SQLiteWordsRepository(db).insertEntry(
      Entry.create(
        english: 'vault',
        meanings: const [],
        status: EntryStatus.pending,
        source: chapter5.source,
      ),
    );

    expect(await waiting(chapter5), ['dodge']);
    expect(await repository.recentTerms('learned'), ['vault']);
  });

  test('reveal is remembered', () async {
    await repository.save(chapter5, [word('vault')]);
    await repository.reveal(chapter5, 'vault');
    expect((await repository.words(chapter5)).single.revealed, isTrue);
  });

  test('upgrading from schema 3 adds chapter_words and keeps data', () async {
    final old = await openDatabase(
      inMemoryDatabasePath,
      version: 3,
      singleInstance: false,
      onCreate: (db, _) async {
        await SQLiteDatabaseHelper.createTables(db);
        await db.execute('DROP TABLE chapter_words');
      },
    );
    await SuggestedWordsRepository(old).markKnownTerm('vault', 'vault');

    await SQLiteDatabaseHelper.handleUpgrade(old, 3, 4);

    await ChapterWordsRepository(old).save(chapter5, [word('dodge')]);
    expect(await ChapterWordsRepository(old).hasWords(chapter5), isTrue);
    expect(await old.query('suggested_words'), hasLength(1));
    await old.close();
  });
}
