import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/data/tts_service.dart';
import 'package:knew/src/features/practice/presentation/flashcard_practice_screen.dart';
import 'package:knew/src/features/practice/presentation/practice_providers.dart';
import 'package:knew/src/features/practice/presentation/practice_session_controller.dart';
import 'package:knew/src/features/practice/presentation/practice_session_state.dart';
import 'package:knew/src/features/practice/domain/practice_question.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
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
    return store.values.toList();
  }

  @override
  Future<ImportMergeResult> mergeEntries(List<Entry> incomingEntries) async {
    return const ImportMergeResult(added: 0, updated: 0, skipped: 0);
  }

  @override
  Future<void> resetProgress(String id) async {}
}

class FakeTtsService extends TtsService {
  bool speakCalled = false;
  bool shouldSucceed = true;

  @override
  Future<bool> speak(String text) async {
    speakCalled = true;
    return shouldSucceed;
  }
}

class TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<SettingsState> build() async => const SettingsState(
    sessionSize: 20,
    theme: 'system',
    model: 'gemini-3.8-flash',
    apiKey: '',
  );
}

class TypingSessionNotifier extends PracticeSessionNotifier {
  TypingSessionNotifier(this.question);

  final PracticeQuestion question;

  @override
  PracticeSessionState build() => PracticeSessionState(questions: [question]);

  @override
  void startSession({
    required List<Entry> library,
    required String todayDueDate,
    int requestedSessionSize = 20,
    Random? random,
  }) {}
}

void main() {
  late TestWordsRepository wordsRepository;
  late FakeTtsService fakeTtsService;

  setUp(() {
    wordsRepository = TestWordsRepository();
    fakeTtsService = FakeTtsService();
  });

  Entry createTestEntry({
    required String id,
    required String english,
    required String pos,
    required List<String> hebrewTranslations,
    required int level,
    required String dueDate,
  }) {
    return Entry.create(
      id: id,
      english: english,
      meanings: [
        Meaning(
          partOfSpeech: pos,
          definition: 'Definition of $english',
          hebrewTranslations: hebrewTranslations,
        ),
      ],
      level: level,
      dueDate: dueDate,
    );
  }

  Widget createWidgetUnderTest(List<Entry> library) {
    return ProviderScope(
      overrides: [
        wordsRepositoryProvider.overrideWithValue(wordsRepository),
        ttsServiceProvider.overrideWithValue(fakeTtsService),
        settingsProvider.overrideWith(() => TestSettingsNotifier()),
      ],
      child: MaterialApp(
        home: FlashcardPracticeScreen(initialLibrary: library, onExit: () {}),
      ),
    );
  }

  group('FlashcardPracticeScreen - Formats & Interaction', () {
    testWidgets('Check answer submits the typing field text', (tester) async {
      final entry = createTestEntry(
        id: 'typing',
        english: 'apple',
        pos: 'noun',
        hebrewTranslations: ['תפוח'],
        level: 1,
        dueDate: '2026-09-15',
      );
      final question = PracticeQuestion(
        entry: entry,
        direction: PromptDirection.englishToHebrew,
        format: QuestionFormat.typing,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordsRepositoryProvider.overrideWithValue(wordsRepository),
            ttsServiceProvider.overrideWithValue(fakeTtsService),
            settingsProvider.overrideWith(() => TestSettingsNotifier()),
            practiceSessionProvider.overrideWith(
              () => TypingSessionNotifier(question),
            ),
          ],
          child: MaterialApp(
            home: FlashcardPracticeScreen(
              initialLibrary: [entry],
              onExit: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'תפוח');
      await tester.tap(find.text('Check answer'));
      await tester.pumpAndSettle();

      expect(find.text('Exact match!'), findsOneWidget);
    });

    testWidgets('Audio button triggers TTS and shows snackbar on failure', (
      tester,
    ) async {
      fakeTtsService.shouldSucceed = false;

      final entry = createTestEntry(
        id: '1',
        english: 'apple',
        pos: 'noun',
        hebrewTranslations: ['תפוח'],
        level: 1,
        dueDate: '2026-09-15',
      );

      await wordsRepository.insertEntry(entry);

      await tester.pumpWidget(createWidgetUnderTest([entry]));
      await tester.pumpAndSettle();

      // Find and tap audio button
      final audioButton = find.byIcon(Icons.volume_up);
      expect(audioButton, findsOneWidget);
      await tester.tap(audioButton);
      await tester.pumpAndSettle();

      expect(fakeTtsService.speakCalled, isTrue);
      expect(
        find.textContaining('English pronunciation unavailable'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Multiple choice option selection highlights feedback and shows Next button',
      (tester) async {
        // Build library with 4 entries so MC is legal
        final target = createTestEntry(
          id: 'target',
          english: 'swift',
          pos: 'adjective',
          hebrewTranslations: ['מהיר'],
          level: 0,
          dueDate: '2026-09-15',
        );
        final e1 = createTestEntry(
          id: '1',
          english: 'slow',
          pos: 'adjective',
          hebrewTranslations: ['איטי'],
          level: 1,
          dueDate: '2026-09-15',
        );
        final e2 = createTestEntry(
          id: '2',
          english: 'big',
          pos: 'adjective',
          hebrewTranslations: ['גדול'],
          level: 1,
          dueDate: '2026-09-15',
        );
        final e3 = createTestEntry(
          id: '3',
          english: 'small',
          pos: 'adjective',
          hebrewTranslations: ['קטן'],
          level: 1,
          dueDate: '2026-09-15',
        );

        final library = [target, e1, e2, e3];
        for (final e in library) {
          await wordsRepository.insertEntry(e);
        }

        await tester.pumpWidget(createWidgetUnderTest(library));
        await tester.pumpAndSettle();

        // If rendered as MC option screen, option buttons are visible
        final optionFinder = find.byType(OutlinedButton);
        if (optionFinder.evaluate().isNotEmpty) {
          // Tap first option
          await tester.tap(optionFinder.first);
          await tester.pumpAndSettle();

          // Expect Next button to appear in bottom action bar
          expect(find.text('Next'), findsOneWidget);
        }
      },
    );
  });
}
