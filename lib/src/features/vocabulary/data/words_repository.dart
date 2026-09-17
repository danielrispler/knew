import '../domain/entry.dart';
import '../domain/meaning.dart';

class DuplicateEntryException implements Exception {
  final String term;
  final String existingId;

  DuplicateEntryException({required this.term, required this.existingId});

  @override
  String toString() =>
      'DuplicateEntryException: Entry with term "$term" already exists (ID: $existingId)';
}

class ImportMergeResult {
  final int added;
  final int updated;
  final int skipped;

  const ImportMergeResult({
    required this.added,
    required this.updated,
    required this.skipped,
  });
}

abstract class WordsRepository {
  Future<void> insertEntry(Entry entry);
  Future<void> updateEntry(Entry entry);
  Future<void> updateProgress(Entry entry);
  Future<bool> updateSemanticEntry(Entry original, Entry updated);
  Future<bool> applyEnrichment(Entry original, List<Meaning> meanings);
  Future<void> deleteEntry(String id);
  Future<void> resetProgress(String id);
  Future<Entry?> getEntryById(String id);
  Future<Entry?> getEntryByEnglishKey(String englishKey);
  Future<bool> existsEnglishKey(String englishKey, {String? excludeId});
  Future<List<Entry>> getAllEntries();
  Future<List<Entry>> getDueEntries(String dateYYYYMMDD);
  Future<ImportMergeResult> mergeEntries(List<Entry> incomingEntries);
}
