import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';
import 'package:knew/src/features/practice/presentation/practice_providers.dart';

class MockWordsRepository implements WordsRepository {
  final Map<String, Entry> store = {};
  bool shouldFail = false;

  @override
  Future<void> insertEntry(Entry entry) async {
    if (shouldFail) throw Exception('Database write failed');
    store[entry.id] = entry;
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    if (shouldFail) throw Exception('Database write failed');
    store[entry.id] = entry;
  }

  @override
  Future<void> updateProgress(Entry entry) => updateEntry(entry);

  @override
  Future<bool> updateSemanticEntry(Entry original, Entry updated) async {
    await updateEntry(updated);
    return true;
  }

  @override
  Future<bool> applyEnrichment(Entry original, List<Meaning> meanings) async {
    store[original.id] = original.copyWith(meanings: meanings);
    return true;
  }

  @override
  Future<void> deleteEntry(String id) async {
    store.remove(id);
  }

  @override
  Future<Entry?> getEntryById(String id) async {
    return store[id];
  }

  @override
  Future<Entry?> getEntryByEnglishKey(String englishKey) async {
    return null;
  }

  @override
  Future<bool> existsEnglishKey(String englishKey, {String? excludeId}) async {
    return false;
  }

  @override
  Future<List<Entry>> getAllEntries() async {
    return store.values.toList();
  }

  @override
  Future<List<Entry>> getDueEntries(String dateYYYYMMDD) async {
    return store.values
        .where((e) => e.dueDate.compareTo(dateYYYYMMDD) <= 0)
        .toList();
  }

  @override
  Future<ImportMergeResult> mergeEntries(List<Entry> incomingEntries) async {
    return const ImportMergeResult(added: 0, updated: 0, skipped: 0);
  }

  @override
  Future<void> resetProgress(String id) async {}
}

void main() {
  final testMeaning = Meaning(
    partOfSpeech: 'verb',
    definition: 'to learn',
    hebrewTranslations: ['ללמוד'],
  );

  Entry createTestEntry(
    String id, {
    int level = 0,
    String dueDate = '2026-09-15',
  }) {
    return Entry.create(
      id: id,
      english: 'learn_$id',
      meanings: [testMeaning],
      level: level,
      dueDate: dueDate,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  late MockWordsRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = MockWordsRepository();
    container = ProviderContainer(
      overrides: [wordsRepositoryProvider.overrideWithValue(repository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PracticeSessionNotifier - Initial Queue & Progression', () {
    test('Starts session and builds questions from queue selection', () async {
      final e1 = createTestEntry('1', level: 0);
      final e2 = createTestEntry('2', level: 1);
      await repository.insertEntry(e1);
      await repository.insertEntry(e2);

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(library: [e1, e2], todayDueDate: '2026-09-15');

      final state = container.read(practiceSessionProvider);
      expect(state.questions.length, equals(2));
      expect(state.currentIndex, equals(0));
      expect(state.isRevealed, isFalse);
      expect(state.isCompleted, isFalse);
    });

    test('First-pass correct answer updates repository immediately', () async {
      final e1 = createTestEntry('1', level: 0);
      await repository.insertEntry(e1);

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(library: [e1], todayDueDate: '2026-09-15');

      notifier.reveal();
      expect(container.read(practiceSessionProvider).isRevealed, isTrue);

      await notifier.gradeCurrent(correct: true);

      final updatedInDb = await repository.getEntryById('1');
      expect(updatedInDb?.level, equals(1));
      expect(updatedInDb?.timesCorrect, equals(1));
      expect(container.read(practiceSessionProvider).isCompleted, isTrue);
    });

    test('First-pass incorrect answer adds entry to repeat queue', () async {
      final e1 = createTestEntry('1', level: 1);
      await repository.insertEntry(e1);

      final notifier = container.read(practiceSessionProvider.notifier);
      notifier.startSession(library: [e1], todayDueDate: '2026-09-15');

      notifier.reveal();
      await notifier.gradeCurrent(correct: false);

      final updatedInDb = await repository.getEntryById('1');
      expect(updatedInDb?.timesWrong, equals(1));

      var state = container.read(practiceSessionProvider);
      expect(state.currentQuestion?.isRepeat, isTrue);
      expect(state.isCompleted, isFalse);

      notifier.reveal();
      await notifier.gradeCurrent(correct: true);

      final dbAfterRepeat = await repository.getEntryById('1');
      expect(dbAfterRepeat?.timesCorrect, equals(0));
      expect(container.read(practiceSessionProvider).isCompleted, isTrue);
    });

    test(
      'Single-tap override (Count as correct) replaces wrong grade in DB and removes repeat',
      () async {
        final e1 = createTestEntry('1', level: 2, dueDate: '2026-09-15');
        await repository.insertEntry(e1);

        final notifier = container.read(practiceSessionProvider.notifier);
        notifier.startSession(library: [e1], todayDueDate: '2026-09-15');

        notifier.reveal();
        await notifier.gradeCurrent(correct: false);

        expect(container.read(practiceSessionProvider).canOverride, isTrue);

        await notifier.countAsCorrect();

        final dbAfterOverride = await repository.getEntryById('1');
        expect(dbAfterOverride?.level, equals(3));
        expect(dbAfterOverride?.timesCorrect, equals(1));
        expect(dbAfterOverride?.timesWrong, equals(0));
        expect(container.read(practiceSessionProvider).canOverride, isFalse);
      },
    );

    test(
      'Database write failure pauses on question and shows save error',
      () async {
        final e1 = createTestEntry('1', level: 0);
        await repository.insertEntry(e1);
        repository.shouldFail = true;

        final notifier = container.read(practiceSessionProvider.notifier);
        notifier.startSession(library: [e1], todayDueDate: '2026-09-15');

        notifier.reveal();
        await notifier.gradeCurrent(correct: true);

        var state = container.read(practiceSessionProvider);
        expect(state.saveError, isNotNull);
        expect(state.currentIndex, equals(0));
        expect(state.isCompleted, isFalse);

        repository.shouldFail = false;
        await notifier.retrySave();

        state = container.read(practiceSessionProvider);
        expect(state.saveError, isNull);
        expect(state.isCompleted, isTrue);
      },
    );
  });
}
