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
}
