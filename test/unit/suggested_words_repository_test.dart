import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/features/discover/data/suggested_words_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Database db;
  late SuggestedWordsRepository repository;

  setUp(() async {
    db = await openDatabase(
      inMemoryDatabasePath,
      version: 2,
      onCreate: (db, _) => SQLiteDatabaseHelper.createTables(db),
    );
    repository = SuggestedWordsRepository(
      db,
      pool: const [
        Candidate('one', 'אחד'),
        Candidate('two', 'שתיים'),
        Candidate('three', 'שלוש'),
        Candidate('four', 'ארבע'),
        Candidate('five', 'חמש'),
        Candidate('six', 'שש'),
        Candidate('known', 'ידוע'),
        Candidate('learned', 'נלמד'),
      ],
    );
  });
  tearDown(() => db.close());

  test(
    'keeps a five-word batch and applies progressive skip cooldowns',
    () async {
      final batch = await repository.loadOrCreateBatch();
      expect(batch, hasLength(5));
      expect(await repository.loadOrCreateBatch(), hasLength(5));

      await repository.skip(batch.first.key);
      var row = (await db.query(
        'suggested_words',
        where: 'english_key = ?',
        whereArgs: [batch.first.key],
      )).single;
      expect(row['skip_count'], 1);
      expect(
        DateTime.parse(
          row['next_eligible_at'] as String,
        ).difference(DateTime.now().toUtc()).inDays,
        inInclusiveRange(13, 14),
      );

      await repository.skip(batch.first.key);
      row = (await db.query(
        'suggested_words',
        where: 'english_key = ?',
        whereArgs: [batch.first.key],
      )).single;
      expect(row['skip_count'], 2);
      expect(
        DateTime.parse(
          row['next_eligible_at'] as String,
        ).difference(DateTime.now().toUtc()).inDays,
        inInclusiveRange(29, 30),
      );

      await db.update(
        'suggested_words',
        {'next_eligible_at': '2000-01-01T00:00:00.000Z'},
        where: 'english_key = ?',
        whereArgs: [batch.first.key],
      );
      final resurfaced = await repository.newBatch();
      await repository.skip(
        resurfaced.firstWhere((word) => word.key == batch.first.key).key,
      );
      row = (await db.query(
        'suggested_words',
        where: 'english_key = ?',
        whereArgs: [batch.first.key],
      )).single;
      expect(row['skip_count'], 3);
    },
  );

  test('merges discovery history without replacing the active batch', () async {
    final batch = await repository.loadOrCreateBatch();
    await repository.mergeHistory({
      'bandCenter': 4,
      'known': [
        {'key': 'known', 'updatedAt': '2026-09-15T08:00:00.000Z'},
      ],
      'learned': [
        {'key': 'learned', 'updatedAt': '2026-09-16T08:00:00.000Z'},
      ],
    });

    expect(
      (await repository.batch()).map((word) => word.key),
      equals(batch.map((word) => word.key)),
    );
    expect(
      await db.query(
        'suggested_words',
        where: "status IN ('known', 'learned')",
      ),
      hasLength(2),
    );
    expect(
      (await db.query(
        'settings',
        where: 'name = ?',
        whereArgs: ['discovery_band_center'],
      )).single['value'],
      '4',
    );
  });

  test(
    'uses a validated queued Gemini suggestion as the fifth batch word',
    () async {
      await repository.refillGeminiQueue((_) async => ['personal word']);

      final batch = await repository.newBatch();

      expect(
        await db.query(
          'suggested_words',
          where: 'status = ?',
          whereArgs: ['batch'],
        ),
        hasLength(5),
      );
      expect(batch, hasLength(5));
      expect(batch.map((word) => word.key), contains('personal word'));
    },
  );

  test(
    'builds role-distributed local batches without duplicate Candidates',
    () async {
      await db.insert('settings', {
        'name': 'discovery_band_center',
        'value': '4',
      });

      final batch = await repository.newBatch();

      expect(batch.map((word) => word.rank), equals([3, 4, 5, 6, 2]));
      expect(batch.map((word) => word.key).toSet(), hasLength(5));
    },
  );

  test('uses a fifth local target when Gemini is unavailable', () async {
    await db.insert('settings', {
      'name': 'discovery_band_center',
      'value': '1',
    });

    final batch = await repository.newBatch();

    expect(batch, hasLength(5));
    expect(batch.map((word) => word.key).toSet(), hasLength(5));
    expect(batch.map((word) => word.rank), equals([1, 2, 3, 4, 5]));
  });

  test(
    'falls back across excluded ranks without duplicate Candidates',
    () async {
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert('settings', {
        'name': 'discovery_band_center',
        'value': '4',
      });
      await db.insert('suggested_words', {
        'english_key': 'four',
        'term': 'four',
        'frequency_rank': 4,
        'status': 'known',
        'skip_count': 0,
        'created_at': now,
        'updated_at': now,
      });

      final batch = await repository.newBatch();

      expect(batch.map((word) => word.key), isNot(contains('four')));
      expect(batch.map((word) => word.key).toSet(), hasLength(5));
    },
  );

  test('uses imported history terms outside the Candidate Pool', () async {
    await repository.mergeHistory({
      'bandCenter': 4,
      'known': [
        {
          'key': 'personal term',
          'term': 'Personal Term',
          'updatedAt': '2026-09-15T08:00:00.000Z',
        },
      ],
      'learned': [],
    });

    final row = (await db.query(
      'suggested_words',
      where: 'english_key = ?',
      whereArgs: ['personal term'],
    )).single;
    expect(row['term'], 'Personal Term');
    expect(row['frequency_rank'], isNull);
    expect(row['status'], 'known');
  });

  test('imported history replaces a matching active batch record', () async {
    final batch = await repository.newBatch();
    final word = batch.first;

    await repository.mergeHistory({
      'bandCenter': 4,
      'known': [
        {
          'key': word.key,
          'term': word.term,
          'updatedAt': '2026-09-15T08:00:00.000Z',
        },
      ],
      'learned': [],
    });

    expect(await repository.batch(), isNot(contains(word)));
    expect(
      (await db.query(
        'suggested_words',
        where: 'english_key = ?',
        whereArgs: [word.key],
      )).single['status'],
      'known',
    );
  });

  test(
    'only marks the Suggested Word Learned when its saved key matches',
    () async {
      final word = (await repository.newBatch()).first;

      await repository.markLearnedIfSaved(word.key, 'edited term');
      expect(
        (await repository.batch()).map((item) => item.key),
        contains(word.key),
      );

      await repository.markLearnedIfSaved(word.key, word.key);
      expect(
        (await repository.batch()).map((item) => item.key),
        isNot(contains(word.key)),
      );
    },
  );

  test('uses the legacy key as an imported history term', () async {
    await repository.mergeHistory({
      'bandCenter': 4,
      'known': [],
      'learned': [
        {'key': 'legacy Gemini term', 'updatedAt': '2026-09-15T08:00:00.000Z'},
      ],
    });

    final history = await repository.exportHistory();
    expect(history['learned'], [
      {
        'key': 'legacy Gemini term',
        'term': 'legacy Gemini term',
        'updatedAt': '2026-09-15T08:00:00.000Z',
      },
    ]);
  });

  test(
    'does not promote a queued word that was added to the library',
    () async {
      await repository.refillGeminiQueue((_) async => ['personal word']);
      final now = DateTime.now().toUtc().toIso8601String();
      await db.insert('words', {
        'id': 'personal-word',
        'english': 'personal word',
        'english_key': 'personal word',
        'meanings': '[]',
        'level': 0,
        'due_date': '2026-09-18',
        'times_correct': 0,
        'times_wrong': 0,
        'created_at': now,
        'updated_at': now,
      });

      expect(
        (await repository.newBatch()).map((word) => word.key),
        isNot(contains('personal word')),
      );
    },
  );
}
