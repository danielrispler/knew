import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/theme/app_theme.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_list_screen.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';

class TestVocabularyListNotifier extends VocabularyListNotifier {
  final List<Entry> _initialEntries;

  TestVocabularyListNotifier(this._initialEntries);

  @override
  Future<List<Entry>> build() async {
    return _initialEntries;
  }
}

class LoadingVocabularyListNotifier extends VocabularyListNotifier {
  @override
  Future<List<Entry>> build() => Completer<List<Entry>>().future;
}

class FailingVocabularyListNotifier extends VocabularyListNotifier {
  @override
  Future<List<Entry>> build() async => throw StateError('load failed');
}

void main() {
  group('VocabularyListScreen Widget Tests', () {
    testWidgets('disables Practice while the vocabulary library is loading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyListProvider.overrideWith(
              () => LoadingVocabularyListNotifier(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VocabularyListScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.school_outlined),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disables Practice when the vocabulary library fails to load', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyListProvider.overrideWith(
              () => FailingVocabularyListNotifier(),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VocabularyListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.school_outlined),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.textContaining('Error loading library'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows empty state when no entries exist', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyListProvider.overrideWith(
              () => TestVocabularyListNotifier([]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VocabularyListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('knew'), findsOneWidget);
      expect(
        find.textContaining('Your vocabulary library is empty'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.school_outlined),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNull,
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays list of entries when data is present', (
      WidgetTester tester,
    ) async {
      final entry = Entry.create(
        english: 'resilient',
        meanings: [
          Meaning(
            partOfSpeech: 'adj',
            definition: 'Able to withstand hardship',
            hebrewTranslations: ['עמיד', 'בעל כושר התאוששות'],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyListProvider.overrideWith(
              () => TestVocabularyListNotifier([entry]),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VocabularyListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('resilient'), findsOneWidget);
      expect(find.text('[adj] Able to withstand hardship'), findsOneWidget);
      expect(find.text('עמיד, בעל כושר התאוששות'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
      expect(find.text('Review'), findsOneWidget);
      expect(find.text('Scheduled practice'), findsOneWidget);
      expect(
        tester
            .widget<IconButton>(
              find.ancestor(
                of: find.byIcon(Icons.school_outlined),
                matching: find.byType(IconButton),
              ),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('shows Processing and Failed Entry status in Review', (
      tester,
    ) async {
      final entries = [
        Entry.create(
          english: 'waiting',
          meanings: [],
          status: EntryStatus.pending,
        ),
        Entry.create(
          english: 'retry',
          meanings: [],
          status: EntryStatus.failed,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyListProvider.overrideWith(
              () => TestVocabularyListNotifier(entries),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VocabularyListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Processing: 1'), findsOneWidget);
      expect(find.text('Failed: 1'), findsOneWidget);
      expect(find.text('Scheduled practice'), findsNothing);
    });
  });
}
