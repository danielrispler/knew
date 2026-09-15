import '../domain/entry.dart';

class DuplicateEntryException implements Exception {
  final String term;
  final String existingId;

  DuplicateEntryException({required this.term, required this.existingId});

  @override
  String toString() => 'DuplicateEntryException: Entry with term "$term" already exists (ID: $existingId)';
}

abstract class WordsRepository {
  Future<void> insertEntry(Entry entry);
  Future<void> updateEntry(Entry entry);
  Future<void> deleteEntry(String id);
  Future<Entry?> getEntryById(String id);
  Future<Entry?> getEntryByEnglishKey(String englishKey);
  Future<bool> existsEnglishKey(String englishKey, {String? excludeId});
  Future<List<Entry>> getAllEntries();
  Future<List<Entry>> getDueEntries(String dateYYYYMMDD);
}
