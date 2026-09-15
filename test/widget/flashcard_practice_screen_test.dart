import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/presentation/flashcard_practice_screen.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';

class TestWordsRepository implements WordsRepository {
  final Map<String, Entry> store = {};

  @override
  Future<void> insertEntry(Entry entry) async {
    store[entry.id] = entry;
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    store[entry.id] = entry;
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
    return store.values.toList();
  }
}

void main() {
  final testMeaning = Meaning(
    partOfSpeech: 'adjective',
    definition: 'lasting for a long time',
    hebrewTranslations: ['מתמיד', 'עקבי'],
  );

  final testEntry = Entry.create(
    id: 'entry_1',
    english: 'persistent',
    meanings: [testMeaning],
    level: 0,
    dueDate: '2026-09-15',
    createdAt: DateTime(2026, 1, 1),
  );

  testWidgets('FlashcardPracticeScreen displays prompt, reveals answer, and completes session',
      (WidgetTester tester) async {
    final repository = TestWordsRepository();
    await repository.insertEntry(testEntry);

    bool exited = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          wordsRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          home: FlashcardPracticeScreen(
            initialLibrary: [testEntry],
            onExit: () {
              exited = true;
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final isEngPrompt = find.text('persistent').evaluate().isNotEmpty;
    if (isEngPrompt) {
      expect(find.text('persistent'), findsOneWidget);
    } else {
      expect(find.text('מתמיד, עקבי'), findsOneWidget);
    }
    expect(find.text('Show answer'), findsOneWidget);

    // Tap Show answer to reveal
    await tester.tap(find.text('Show answer'));
    await tester.pumpAndSettle();

    // Verify revealed translation/term and actions visible
    if (isEngPrompt) {
      expect(find.text('מתמיד, עקבי'), findsOneWidget);
    } else {
      expect(find.text('persistent'), findsOneWidget);
    }
    expect(find.text('lasting for a long time'), findsOneWidget);
    expect(find.text("Didn't know"), findsOneWidget);
    expect(find.text('Knew it'), findsOneWidget);

    // Tap Knew it
    await tester.tap(find.text('Knew it'));
    await tester.pumpAndSettle();

    // Verify Practice Summary screen is shown
    expect(find.text('Practice Summary'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    // Tap Done on summary screen
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    expect(exited, isTrue);

    // Verify DB updated level to 1
    final updatedInDb = await repository.getEntryById('entry_1');
    expect(updatedInDb?.level, equals(1));
  });
}
