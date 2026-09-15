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

void main() {
  group('VocabularyListScreen Widget Tests', () {
    testWidgets('shows empty state when no entries exist', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            vocabularyListProvider.overrideWith(() => TestVocabularyListNotifier([])),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const VocabularyListScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('knew'), findsOneWidget);
      expect(find.textContaining('No vocabulary entries saved yet'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays list of entries when data is present', (WidgetTester tester) async {
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
            vocabularyListProvider.overrideWith(() => TestVocabularyListNotifier([entry])),
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
    });
  });
}
