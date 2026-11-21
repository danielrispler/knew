import 'package:sqflite/sqflite.dart';

import '../../discover/data/suggested_words_repository.dart';
import '../domain/reading.dart';

class ChapterWordsRepository {
  final Database db;
  ChapterWordsRepository(this.db);

  static final _validKey = RegExp(r"^[a-z]+(?:[ '-][a-z]+)*$");

  Future<Reading> reading() async {
    final number = await _setting('reading_book') ?? 1;
    final book = readingBooks.firstWhere(
      (book) => book.number == number,
      orElse: () => readingBooks.first,
    );
    final chapter = (await _setting('reading_chapter') ?? 1).clamp(
      1,
      book.chapterCount,
    );
    return Reading(book, chapter);
  }

  Future<void> setReading(Reading reading) async {
    for (final entry in {
      'reading_book': reading.book.number,
      'reading_chapter': reading.chapter,
    }.entries) {
      await db.insert('settings', {
        'name': entry.key,
        'value': '${entry.value}',
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  /// True once Claude has been asked for this chapter, so it is not paid for
  /// again unless the learner asks for more words.
  Future<bool> hasWords(Reading reading) async =>
      (await _rows(reading)).isNotEmpty;

  /// Chapter Words still waiting for the learner's decision. A word saved to
  /// the library or marked Known anywhere stops waiting.
  Future<List<ChapterWord>> words(Reading reading) async {
    await _syncWithLibraryAndKnown();
    return (await _rows(reading, status: 'suggested'))
        .map(
          (row) => ChapterWord(
            key: row['english_key'] as String,
            term: row['term'] as String,
            hebrew: row['hebrew'] as String,
            definition: row['definition'] as String,
            revealed: row['revealed'] == 1,
          ),
        )
        .toList();
  }

  Future<void> save(Reading reading, List<ChapterWord> words) async {
    final now = DateTime.now().toUtc().toIso8601String();
    for (final word in words) {
      if (!_validKey.hasMatch(word.key)) continue;
      await db.insert('chapter_words', {
        'book': reading.book.number,
        'chapter': reading.chapter,
        'english_key': word.key,
        'term': word.term,
        'hebrew': word.hebrew,
        'definition': word.definition,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  Future<List<String>> alreadySuggested(Reading reading) async =>
      (await _rows(reading)).map((row) => row['term'] as String).toList();

  /// Recent terms with [status] `known` or `learned`, used to tell Claude the
  /// learner's level.
  Future<List<String>> recentTerms(String status, {int limit = 30}) async =>
      (await db.query(
        'chapter_words',
        columns: ['term'],
        distinct: true,
        where: 'status = ?',
        whereArgs: [status],
        orderBy: 'updated_at DESC',
        limit: limit,
      )).map((row) => row['term'] as String).toList();

  Future<void> reveal(Reading reading, String key) =>
      _update(reading, key, {'revealed': 1});

  Future<void> skip(Reading reading, String key) =>
      _update(reading, key, {'status': 'skipped'});

  /// Adds the word to the Known list shared with Discover.
  Future<void> known(ChapterWord word) async {
    await SuggestedWordsRepository(db).markKnownTerm(word.key, word.term);
    await _syncWithLibraryAndKnown();
  }

  Future<void> _syncWithLibraryAndKnown() async {
    final now = DateTime.now().toUtc().toIso8601String();
    await db.rawUpdate(
      "UPDATE chapter_words SET status = 'learned', updated_at = ? "
      "WHERE status = 'suggested' "
      'AND english_key IN (SELECT english_key FROM words)',
      [now],
    );
    await db.rawUpdate(
      "UPDATE chapter_words SET status = 'known', updated_at = ? "
      "WHERE status = 'suggested' AND english_key IN "
      "(SELECT english_key FROM suggested_words WHERE status = 'known')",
      [now],
    );
  }

  Future<List<Map<String, Object?>>> _rows(
    Reading reading, {
    String? status,
  }) => db.query(
    'chapter_words',
    where: 'book = ? AND chapter = ?${status == null ? '' : ' AND status = ?'}',
    whereArgs: [reading.book.number, reading.chapter, ?status],
    orderBy: 'created_at, rowid',
  );

  Future<void> _update(
    Reading reading,
    String key,
    Map<String, Object?> values,
  ) => db.update(
    'chapter_words',
    {...values, 'updated_at': DateTime.now().toUtc().toIso8601String()},
    where: 'book = ? AND chapter = ? AND english_key = ?',
    whereArgs: [reading.book.number, reading.chapter, key],
  );

  Future<int?> _setting(String name) async {
    final rows = await db.query(
      'settings',
      where: 'name = ?',
      whereArgs: [name],
    );
    return rows.isEmpty ? null : int.tryParse(rows.single['value'] as String);
  }
}
