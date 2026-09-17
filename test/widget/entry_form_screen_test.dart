import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:knew/src/core/theme/app_theme.dart';
import 'package:knew/src/features/practice/data/tts_service.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
import 'package:knew/src/features/vocabulary/data/gemini_client.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/presentation/entry_form_screen.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';

class TestSettingsNotifier extends SettingsNotifier {
  final SettingsState _initialState;
  TestSettingsNotifier(this._initialState);

  @override
  Future<SettingsState> build() async => _initialState;
}

class FakeWordsRepository implements WordsRepository {
  final Map<String, Entry> entries = {};

  @override
  Future<void> insertEntry(Entry entry) async {
    entries[entry.id] = entry;
  }

  @override
  Future<void> updateEntry(Entry entry) async {
    entries[entry.id] = entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.remove(id);
  }

  @override
  Future<Entry?> getEntryById(String id) async {
    return entries[id];
  }

  @override
  Future<Entry?> getEntryByEnglishKey(String englishTerm) async {
    final key = Entry.generateKey(englishTerm);
    for (var entry in entries.values) {
      if (entry.englishKey == key) return entry;
    }
    return null;
  }

  @override
  Future<bool> existsEnglishKey(String englishKey, {String? excludeId}) async {
    for (var entry in entries.values) {
      if (entry.englishKey == englishKey && entry.id != excludeId) return true;
    }
    return false;
  }

  @override
  Future<List<Entry>> getAllEntries() async {
    return entries.values.toList();
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

class FakeTtsService extends TtsService {
  String? lastSpokenText;
  bool speakCalled = false;

  @override
  Future<bool> init() async => true;

  @override
  Future<bool> speak(String text) async {
    speakCalled = true;
    lastSpokenText = text;
    return true;
  }
}

void main() {
  group('EntryFormScreen Instant AI Card & Collapsible Drawer Tests', () {
    testWidgets('displays Hero Term Field and collapsed custom drawer by default for new entries',
        (WidgetTester tester) async {
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

      // Hero Term Field at top
      expect(find.byKey(const Key('hero_term_field')), findsOneWidget);
      expect(find.text('Enter English term or Hebrew word...'), findsOneWidget);

      // Collapsible drawer header present and collapsed
      expect(find.text('Need custom meaning or notes? ▾'), findsOneWidget);
      expect(find.byKey(const Key('source_field')), findsNothing);
      expect(find.byKey(const Key('context_field')), findsNothing);

      // Save button at bottom
      expect(find.text('Save to Library'), findsOneWidget);
    });

    testWidgets('triggers automatic lookup with 600ms debounce when 2+ characters typed',
        (WidgetTester tester) async {
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

      // Type 1 character -> no lookup
      await tester.enterText(find.byKey(const Key('hero_term_field')), 'p');
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.byKey(const Key('instant_ai_card')), findsNothing);

      // Type 2+ characters -> 600ms debounce
      await tester.enterText(find.byKey(const Key('hero_term_field')), 'persistent');
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('instant_ai_card')), findsNothing);

      // After 600ms total
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // Instant AI Card displays
      expect(find.byKey(const Key('instant_ai_card')), findsOneWidget);
      expect(find.text('persistent'), findsAtLeast(1));
      expect(find.text('ADJECTIVE'), findsOneWidget);
      expect(find.text('Continuing firmly in a course of action.'), findsOneWidget);
      expect(find.text('עקשן'), findsOneWidget);
      expect(find.text('מתמיד'), findsOneWidget);
    });

    testWidgets('triggers immediate lookup on keyboard submit action without waiting for debounce',
        (WidgetTester tester) async {
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
                      'english': 'swift',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'adjective',
                          'hebrew': ['מהיר'],
                          'definition': 'Moving with great speed.'
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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'swift');
      // Submit immediately on keyboard action
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('instant_ai_card')), findsOneWidget);
      expect(find.text('swift'), findsAtLeast(1));
      expect(find.text('Moving with great speed.'), findsOneWidget);
    });

    testWidgets('clear button clears input and resets AI card', (WidgetTester tester) async {
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
                      'english': 'swift',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'adjective',
                          'hebrew': ['מהיר'],
                          'definition': 'Moving with great speed.'
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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'swift');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('instant_ai_card')), findsOneWidget);

      // Tap clear button
      await tester.tap(find.byKey(const Key('clear_hero_term_button')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('instant_ai_card')), findsNothing);
      final heroField = tester.widget<TextField>(find.byKey(const Key('hero_term_field')));
      expect(heroField.controller?.text, isEmpty);
    });

    testWidgets('hebrew translation chips are selectable (RTL) with primary pre-selected and toggling updates selection',
        (WidgetTester tester) async {
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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'persistent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Find FilterChips for translations
      final chip1Finder = find.widgetWithText(FilterChip, 'עקשן');
      final chip2Finder = find.widgetWithText(FilterChip, 'מתמיד');

      expect(chip1Finder, findsOneWidget);
      expect(chip2Finder, findsOneWidget);

      // Primary translation pre-selected
      final chip1 = tester.widget<FilterChip>(chip1Finder);
      final chip2 = tester.widget<FilterChip>(chip2Finder);
      expect(chip1.selected, isTrue);
      expect(chip2.selected, isFalse);

      // Tap chip2 to also select it
      await tester.tap(chip2Finder);
      await tester.pumpAndSettle();

      final updatedChip2 = tester.widget<FilterChip>(chip2Finder);
      expect(updatedChip2.selected, isTrue);
    });

    testWidgets('multi-sense switcher allows switching between senses when Gemini returns >1 meaning sense',
        (WidgetTester tester) async {
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
                      'english': 'run',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'verb',
                          'hebrew': ['לרוץ'],
                          'definition': 'Move fast using one\'s feet.'
                        },
                        {
                          'partOfSpeech': 'noun',
                          'hebrew': ['ריצה'],
                          'definition': 'An act or spell of running.'
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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'run');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Multi-sense switcher chips present
      expect(find.byKey(const Key('sense_switcher')), findsOneWidget);
      expect(find.text('1: Verb'), findsOneWidget);
      expect(find.text('2: Noun'), findsOneWidget);

      // Initially on sense 1 (Verb)
      expect(find.text('VERB'), findsOneWidget);
      expect(find.text('Move fast using one\'s feet.'), findsOneWidget);
      expect(find.text('לרוץ'), findsOneWidget);

      // Switch to sense 2 (Noun)
      await tester.tap(find.text('2: Noun'));
      await tester.pumpAndSettle();

      expect(find.text('NOUN'), findsOneWidget);
      expect(find.text('An act or spell of running.'), findsOneWidget);
      expect(find.text('ריצה'), findsOneWidget);
    });

    testWidgets('spelling suggestion chip displays on invalid input and one-tap corrects and looks up',
        (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      final mockHttpClient = MockClient((request) async {
        final decoded = jsonDecode(request.body) as Map<String, dynamic>;
        final userContent = decoded['contents'][0]['parts'][0]['text'];
        final innerJson = jsonDecode(userContent);
        final input = innerJson['input'];

        final Map<String, dynamic> payload;
        if (input == 'persistant') {
          payload = {
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
        } else {
          payload = {
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
                            'hebrew': ['עקשן'],
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
        }

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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'persistant');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Spelling suggestion chip
      expect(find.byKey(const Key('spelling_suggestion_chip')), findsOneWidget);
      expect(find.text('Did you mean "persistent"?'), findsOneWidget);

      // Tap suggestion chip
      await tester.tap(find.byKey(const Key('spelling_suggestion_chip')));
      await tester.pumpAndSettle();

      // Input updated and fresh lookup succeeded
      final heroField = tester.widget<TextField>(find.byKey(const Key('hero_term_field')));
      expect(heroField.controller?.text, 'persistent');
      expect(find.byKey(const Key('instant_ai_card')), findsOneWidget);
      expect(find.text('Continuing firmly in a course of action.'), findsOneWidget);
    });

    testWidgets('shows error and auto-expands custom drawer on lookup failure (no API key)',
        (WidgetTester tester) async {
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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'persistent');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Error message shown
      expect(find.textContaining('Add your Gemini API key in Settings'), findsOneWidget);

      // Collapsible drawer auto-expanded so user is not blocked
      expect(find.byKey(const Key('source_field')), findsOneWidget);
      expect(find.byKey(const Key('context_field')), findsOneWidget);
      expect(find.byKey(const Key('manual_meanings_section')), findsOneWidget);
    });

    testWidgets('collapsible custom drawer auto-expands when editing existing entry with custom metadata',
        (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      final existingEntry = Entry.create(
        english: 'persevere',
        source: 'Marcus Aurelius - Meditations',
        context: 'We must persevere despite obstacles.',
        meanings: [
          const Meaning(
            partOfSpeech: 'verb',
            definition: 'Continue in a course of action.',
            hebrewTranslations: ['להתמיד'],
          )
        ],
      );
      await fakeRepo.insertEntry(existingEntry);

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
            settingsProvider.overrideWith(() => TestSettingsNotifier(testSettings)),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: EntryFormScreen(initialEntry: existingEntry),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drawer auto-expanded for entry with metadata
      expect(find.byKey(const Key('source_field')), findsOneWidget);
      expect(find.text('Marcus Aurelius - Meditations'), findsOneWidget);
      expect(find.text('We must persevere despite obstacles.'), findsOneWidget);
    });

    testWidgets('Save to Library saves entry and navigates back with snackbar confirmation',
        (WidgetTester tester) async {
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
                      'english': 'tenacious',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'adjective',
                          'hebrew': ['עקשן', 'נחוש'],
                          'definition': 'Tending to keep a firm hold of something.'
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

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'tenacious');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Tap Save to Library
      await tester.tap(find.byKey(const Key('save_to_library_button')));
      await tester.pumpAndSettle();

      // Check saved in repository
      expect(fakeRepo.entries.length, 1);
      final savedEntry = fakeRepo.entries.values.first;
      expect(savedEntry.english, 'tenacious');
      expect(savedEntry.meanings.first.partOfSpeech, 'adjective');
      // Primary translation 'עקשן' was pre-selected
      expect(savedEntry.meanings.first.hebrewTranslations, ['עקשן']);
    });

    testWidgets('pronunciation speaker button triggers TTS', (WidgetTester tester) async {
      final fakeRepo = FakeWordsRepository();
      final fakeTts = FakeTtsService();
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
                      'english': 'resilient',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'adjective',
                          'hebrew': ['בעל כושר התאוששות'],
                          'definition': 'Able to withstand or recover quickly from difficult conditions.'
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
            home: EntryFormScreen(ttsService: fakeTts),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('hero_term_field')), 'resilient');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Listen to pronunciation'), findsOneWidget);
      await tester.tap(find.byTooltip('Listen to pronunciation'));
      await tester.pump();

      expect(fakeTts.speakCalled, isTrue);
      expect(fakeTts.lastSpokenText, 'resilient');
    });
  });
}
