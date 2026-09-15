import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../domain/entry.dart';
import 'words_repository.dart';

class SQLiteWordsRepository implements WordsRepository {
  final Database db;

  SQLiteWordsRepository(this.db);

  @override
  Future<void> insertEntry(Entry entry) async {
    final existing = await getEntryByEnglishKey(entry.englishKey);
    if (existing != null) {
      throw DuplicateEntryException(term: entry.english, existingId: existing.id);
    }

    try {
      await db.insert(
        'words',
        entry.toDatabaseMap(),
        conflictAlgorithm: ConflictAlgorithm.fail,
      );
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        final current = await getEntryByEnglishKey(entry.englishKey);
        throw DuplicateEntryException(
          term: entry.english,
          existingId: current?.id ?? '',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    final existing = await getEntryByEnglishKey(entry.englishKey);
    if (existing != null && existing.id != entry.id) {
      throw DuplicateEntryException(term: entry.english, existingId: existing.id);
    }

    try {
      final count = await db.update(
        'words',
        entry.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [entry.id],
      );

      if (count == 0) {
        throw Exception('Entry with ID ${entry.id} not found to update.');
      }
    } on DatabaseException catch (e) {
      if (e.isUniqueConstraintError()) {
        final current = await getEntryByEnglishKey(entry.englishKey);
        throw DuplicateEntryException(
          term: entry.english,
          existingId: current?.id ?? '',
        );
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    await db.delete(
      'words',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<void> resetProgress(String id) async {
    final entry = await getEntryById(id);
    if (entry == null) {
      throw Exception('Entry with ID $id not found.');
    }

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final nowUtc = DateTime.now().toUtc().toIso8601String();

    final resetEntry = entry.copyWith(
      level: 0,
      dueDate: todayStr,
      lastReviewedAt: null,
      clearLastReviewedAt: true,
      timesCorrect: 0,
      timesWrong: 0,
      updatedAt: nowUtc,
    );

    await updateEntry(resetEntry);
  }

  @override
  Future<Entry?> getEntryById(String id) async {
    final maps = await db.query(
      'words',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Entry.fromDatabaseMap(maps.first);
  }

  @override
  Future<Entry?> getEntryByEnglishKey(String englishKey) async {
    final normalizedKey = Entry.generateKey(englishKey);
    final maps = await db.query(
      'words',
      where: 'english_key = ?',
      whereArgs: [normalizedKey],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Entry.fromDatabaseMap(maps.first);
  }

  @override
  Future<bool> existsEnglishKey(String englishKey, {String? excludeId}) async {
    final normalizedKey = Entry.generateKey(englishKey);
    if (excludeId != null) {
      final maps = await db.query(
        'words',
        columns: ['id'],
        where: 'english_key = ? AND id != ?',
        whereArgs: [normalizedKey, excludeId],
        limit: 1,
      );
      return maps.isNotEmpty;
    } else {
      final maps = await db.query(
        'words',
        columns: ['id'],
        where: 'english_key = ?',
        whereArgs: [normalizedKey],
        limit: 1,
      );
      return maps.isNotEmpty;
    }
  }

  @override
  Future<List<Entry>> getAllEntries() async {
    final maps = await db.query(
      'words',
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Entry.fromDatabaseMap(map)).toList();
  }

  @override
  Future<List<Entry>> getDueEntries(String dateYYYYMMDD) async {
    final maps = await db.query(
      'words',
      where: 'due_date <= ?',
      whereArgs: [dateYYYYMMDD],
      orderBy: 'due_date ASC, created_at ASC',
    );
    return maps.map((map) => Entry.fromDatabaseMap(map)).toList();
  }

  @override
  Future<ImportMergeResult> mergeEntries(List<Entry> incomingEntries) async {
    int added = 0;
    int updated = 0;
    int skipped = 0;

    await db.transaction((txn) async {
      final existingRows = await txn.query('words');
      final Map<String, Entry> localByKey = {};
      final Set<String> usedIds = {};

      for (final row in existingRows) {
        final localEntry = Entry.fromDatabaseMap(row);
        localByKey[localEntry.englishKey] = localEntry;
        usedIds.add(localEntry.id);
      }

      for (final incoming in incomingEntries) {
        final local = localByKey[incoming.englishKey];

        if (local == null) {
          // Absent term
          String targetId = incoming.id;
          if (usedIds.contains(targetId)) {
            // UUID collision on a distinct term -> assign new UUID
            targetId = const Uuid().v4();
          }

          final newEntry = incoming.copyWith(id: targetId);
          await txn.insert('words', newEntry.toDatabaseMap());
          usedIds.add(targetId);
          localByKey[newEntry.englishKey] = newEntry;
          added++;
        } else {
          // Matched term
          final incomingUpdatedInst = DateTime.parse(incoming.updatedAt).toUtc();
          final localUpdatedInst = DateTime.parse(local.updatedAt).toUtc();

          if (incomingUpdatedInst.isAfter(localUpdatedInst)) {
            // Replace local record preserving local ID
            final updatedEntry = incoming.copyWith(id: local.id);
            await txn.update(
              'words',
              updatedEntry.toDatabaseMap(),
              where: 'id = ?',
              whereArgs: [local.id],
            );
            localByKey[local.englishKey] = updatedEntry;
            updated++;
          } else {
            // Keep local record
            skipped++;
          }
        }
      }
    });

    return ImportMergeResult(
      added: added,
      updated: updated,
      skipped: skipped,
    );
  }
}
