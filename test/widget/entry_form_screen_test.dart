import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/l10n/generated/app_localizations.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/gemini_lookup_result.dart';
import 'package:knew/src/features/vocabulary/domain/pending_entry_controller.dart';
import 'package:knew/src/features/vocabulary/presentation/entry_form_screen.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';

class _Repository extends Fake implements WordsRepository {
  final entries = <Entry>[];

  @override
  Future<void> insertEntry(Entry entry) async => entries.add(entry);

  @override
  Future<void> updateEntry(Entry entry) async {}

  @override
  Future<Entry?> getEntryById(String id) async {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<bool> existsEnglishKey(String key, {String? excludeId}) async => false;

  @override
  Future<List<Entry>> getAllEntries() async => List.of(entries);
}

void main() {
  testWidgets(
    'captures an English term and keeps the field ready for another',
    (tester) async {
      final repository = _Repository();
      final queue = PendingEntryController(
        repository: repository,
        lookup: (term) async => GeminiErrorResult(
          errorType: GeminiErrorType.networkError,
          message: 'offline',
          originalInput: term,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordsRepositoryProvider.overrideWithValue(repository),
            pendingEntryProvider.overrideWithValue(queue),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const EntryFormScreen(),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('quick_capture_field')),
        'swift',
      );
      await tester.tap(find.text('Add and continue'));
      await tester.pump();

      expect(repository.entries.single.english, 'swift');
      expect(repository.entries.single.status, isNot(EntryStatus.ready));
      expect(find.byKey(const Key('quick_capture_field')), findsOneWidget);
    },
  );
}
