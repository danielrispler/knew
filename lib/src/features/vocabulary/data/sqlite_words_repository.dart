import 'package:sqflite/sqflite.dart';
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

    final count = await db.update(
      'words',
      entry.toDatabaseMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    if (count == 0) {
      throw Exception('Entry with ID ${entry.id} not found to update.');
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
}
