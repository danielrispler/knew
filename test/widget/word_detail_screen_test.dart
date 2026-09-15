import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/data/sqlite_words_repository.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';
import 'package:knew/src/features/vocabulary/presentation/word_detail_screen.dart';

void main() {
  group('WordDetailScreen Widget Tests', () {
    late Database db;
    late SQLiteWordsRepository wordsRepository;
    late Entry testEntry;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await SQLiteDatabaseHelper.createTables(db);
        },
      );
      wordsRepository = SQLiteWordsRepository(db);

      testEntry = Entry.create(
        english: 'persistent',
        meanings: const [
          Meaning(
            partOfSpeech: 'adjective',
            definition: 'Continuing firmly in a course of action',
            hebrewTranslations: ['מתמיד', 'עיקש'],
          ),
        ],
        source: 'Reading Book',
        context: 'He was persistent in his studies.',
        level: 2,
        dueDate: '2026-09-17',
        lastReviewedAt: '2026-09-15T08:00:00.000Z',
        timesCorrect: 2,
        timesWrong: 0,
      );

      await wordsRepository.insertEntry(testEntry);
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          wordsRepositoryProvider.overrideWithValue(wordsRepository),
        ],
        child: MaterialApp(
          home: WordDetailScreen(initialEntry: testEntry),
        ),
      );
    }

    testWidgets('renders entry details, meanings, source, context, and stats', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('persistent'), findsNWidgets(2)); // Title & Header
      expect(find.text('Source: Reading Book'), findsOneWidget);
      expect(find.text('"He was persistent in his studies."'), findsOneWidget);
      expect(find.text('adjective'), findsOneWidget);
      expect(find.text('Continuing firmly in a course of action'), findsOneWidget);
      expect(find.text('מתמיד, עיקש'), findsOneWidget);
      expect(find.text('Reset Progress'), findsOneWidget);
      expect(find.text('Edit Entry'), findsOneWidget);
    });

    testWidgets('reset progress opens dialog and updates entry state', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset Progress'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Reset Progress'), findsAtLeast(1));
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Reset Progress inside confirmation dialog
      await tester.tap(find.widgetWithText(TextButton, 'Reset Progress'));
      await tester.pumpAndSettle();

      final reset = await wordsRepository.getEntryById(testEntry.id);
      expect(reset!.level, equals(0));
      expect(reset.lastReviewedAt, isNull);
    });
  });
}
