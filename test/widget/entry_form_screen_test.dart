import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:knew/src/core/theme/app_theme.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
import 'package:knew/src/features/vocabulary/data/gemini_client.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/presentation/entry_form_screen.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';

class TestSettingsNotifier extends SettingsNotifier {
  final SettingsState _initialState;
  TestSettingsNotifier(this._initialState);

  @override
  Future<SettingsState> build() async => _initialState;
}

class FakeWordsRepository implements WordsRepository {
  final Map<String, Entry> _entries = {};

  @override
  Future<void> insertEntry(Entry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    _entries[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.remove(id);
  }

  @override
  Future<Entry?> getEntryById(String id) async {
    return _entries[id];
  }

  @override
  Future<Entry?> getEntryByEnglishKey(String englishTerm) async {
    final key = Entry.generateKey(englishTerm);
    for (var entry in _entries.values) {
      if (entry.englishKey == key) return entry;
    }
    return null;
  }

  @override
  Future<bool> existsEnglishKey(String englishKey, {String? excludeId}) async {
    for (var entry in _entries.values) {
      if (entry.englishKey == englishKey && entry.id != excludeId) return true;
    }
    return false;
  }

  @override
  Future<List<Entry>> getAllEntries() async {
    return _entries.values.toList();
  }

  @override
  Future<List<Entry>> getDueEntries(String dateStr) async {
    return [];
  }

  @override
  Future<ImportMergeResult> mergeEntries(List<Entry> incomingEntries) async {
    return const ImportMergeResult(added: 0, updated: 0, skipped: 0);
  }

  @override
  Future<void> resetProgress(String id) async {}
}

void main() {
  group('EntryFormScreen Assisted Lookup Widget Tests', () {
    testWidgets('displays Gemini Assisted Lookup card for new entries', (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      const testSettings = SettingsState(
        sessionSize: 20,
        theme: 'system',
        model: 'gemini-3.8-flash',
        apiKey: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordsRepositoryProvider.overrideWithValue(fakeRepo),
            settingsProvider.overrideWith(() => TestSettingsNotifier(testSettings)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EntryFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Gemini Assisted Lookup'), findsOneWidget);
      expect(find.text('Look up'), findsOneWidget);
      expect(find.text('English Term *'), findsOneWidget);
    });

    testWidgets('shows error when performing lookup with no API key', (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      const testSettings = SettingsState(
        sessionSize: 20,
        theme: 'system',
        model: 'gemini-3.8-flash',
        apiKey: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordsRepositoryProvider.overrideWithValue(fakeRepo),
            settingsProvider.overrideWith(() => TestSettingsNotifier(testSettings)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EntryFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lookup_field')), 'persistent');
      await tester.tap(find.byKey(const Key('lookup_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Add your Gemini API key in Settings'), findsOneWidget);
    });

    testWidgets('auto-populates form fields on successful lookup', (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      final mockHttpClient = MockClient((request) async {
        final payload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'valid': true,
                      'suggestion': null,
                      'english': 'persistent',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'adjective',
                          'hebrew': ['עקשן', 'מתמיד'],
                          'definition': 'Continuing firmly in a course of action.'
                        }
                      ]
                    })
                  }
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(payload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final testGeminiClient = GeminiClient(httpClient: mockHttpClient);
      const testSettings = SettingsState(
        sessionSize: 20,
        theme: 'system',
        model: 'gemini-3.8-flash',
        apiKey: 'fake_key',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordsRepositoryProvider.overrideWithValue(fakeRepo),
            geminiClientProvider.overrideWithValue(testGeminiClient),
            settingsProvider.overrideWith(() => TestSettingsNotifier(testSettings)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EntryFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lookup_field')), 'persistent');
      await tester.tap(find.byKey(const Key('lookup_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('persistent'), findsAtLeast(1));
      expect(find.text('adjective'), findsOneWidget);
      expect(find.text('Continuing firmly in a course of action.'), findsOneWidget);
      expect(find.text('עקשן'), findsOneWidget);
    });

    testWidgets('displays suggestion button when invalid input returns suggestion', (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      final mockHttpClient = MockClient((request) async {
        final payload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'valid': false,
                      'suggestion': 'persistent',
                      'english': '',
                      'englishAlternatives': [],
                      'meanings': []
                    })
                  }
                ]
              },
              'finishReason': 'STOP'
            }
          ]
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(payload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final testGeminiClient = GeminiClient(httpClient: mockHttpClient);
      const testSettings = SettingsState(
        sessionSize: 20,
        theme: 'system',
        model: 'gemini-3.8-flash',
        apiKey: 'fake_key',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            wordsRepositoryProvider.overrideWithValue(fakeRepo),
            geminiClientProvider.overrideWithValue(testGeminiClient),
            settingsProvider.overrideWith(() => TestSettingsNotifier(testSettings)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const EntryFormScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('lookup_field')), 'persistant');
      await tester.tap(find.byKey(const Key('lookup_button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.textContaining('Did you mean "persistent"?'), findsOneWidget);
      expect(find.text('Use "persistent"'), findsOneWidget);
    });
  });
}
