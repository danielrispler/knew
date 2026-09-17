import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/sqlite_database_helper.dart';
import '../data/gemini_client.dart';
import '../data/sqlite_words_repository.dart';
import '../data/words_repository.dart';
import '../domain/entry.dart';

final databaseProvider = FutureProvider<Database>((ref) async {
  return await SQLiteDatabaseHelper.getDatabase();
});

final geminiClientProvider = Provider<GeminiClient>((ref) {
  return GeminiClient();
});

final wordsRepositoryProvider = Provider<WordsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => SQLiteWordsRepository(db),
    loading: () => throw UnimplementedError('Database is loading'),
    error: (err, stack) => throw err,
  );
});

class VocabularyListNotifier extends AsyncNotifier<List<Entry>> {
  @override
  Future<List<Entry>> build() async {
    final repository = ref.watch(wordsRepositoryProvider);
    return await repository.getAllEntries();
  }

  Future<void> refreshList() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(wordsRepositoryProvider);
      return await repository.getAllEntries();
    });
  }

  Future<void> deleteEntry(String id) async {
    final repository = ref.read(wordsRepositoryProvider);
    await repository.deleteEntry(id);
    await refreshList();
  }

  Future<void> resetProgress(String id) async {
    final repository = ref.read(wordsRepositoryProvider);
    await repository.resetProgress(id);
    await refreshList();
  }
}

final vocabularyListProvider =
    AsyncNotifierProvider<VocabularyListNotifier, List<Entry>>(() {
      return VocabularyListNotifier();
    });
