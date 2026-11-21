import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/database/sqlite_database_helper.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import 'package:knew/src/features/reading/data/claude_client.dart';
import 'package:knew/src/features/reading/domain/reading.dart';
import 'package:knew/src/features/reading/presentation/reading_providers.dart';
import 'package:knew/src/features/reading/presentation/reading_screen.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _Settings extends SettingsNotifier {
  _Settings(this.claudeKey);
  final String claudeKey;
  @override
  Future<SettingsState> build() async => SettingsState(
    sessionSize: 20,
    theme: 'system',
    model: 'gemini-3.8-flash',
    apiKey: '',
    claudeApiKey: claudeKey,
  );
}

class _Claude extends ClaudeClient {
  _Claude({this.error});
  final ClaudeErrorType? error;
  final requests = <Reading>[];

  @override
  Future<List<ChapterWord>> chapterWords({
    required Reading reading,
    required String apiKey,
    List<String> alreadySuggested = const [],
    List<String> tooEasy = const [],
    List<String> rightLevel = const [],
  }) async {
    requests.add(reading);
    if (error != null) throw ClaudeException(error!);
    return const [
      ChapterWord(
        key: 'vault',
        term: 'vault',
        hebrew: 'כספת',
        definition: 'A locked room for valuables.',
      ),
      ChapterWord(
        key: 'dodge',
        term: 'dodge',
        hebrew: 'להתחמק',
        definition: 'Move quickly to avoid something.',
      ),
    ];
  }
}

void main() {
  late Database db;

  Future<void> open(
    WidgetTester tester, {
    required String claudeKey,
    required _Claude claude,
  }) async {
    await tester.runAsync(() async {
      db = await databaseFactoryFfi.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: SQLiteDatabaseHelper.currentSchemaVersion,
          onCreate: (db, _) => SQLiteDatabaseHelper.createTables(db),
          singleInstance: false,
        ),
      );
    });
    addTearDown(() => tester.runAsync(db.close));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWith((ref) async => db),
          settingsProvider.overrideWith(() => _Settings(claudeKey)),
          claudeClientProvider.overrideWithValue(claude),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ReadingScreen(),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('without a Claude key it points to Settings and asks nothing', (
    tester,
  ) async {
    final claude = _Claude();
    await open(tester, claudeKey: '', claude: claude);

    expect(find.text("Harry Potter 1 · Philosopher's Stone"), findsOneWidget);
    expect(find.text('Chapter 1 of 17'), findsOneWidget);
    expect(
      find.text(
        'Add your Claude API key in Settings to get words for a chapter.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('reading_get_words')), findsNothing);
    expect(claude.requests, isEmpty);
  });

  testWidgets('fetches a chapter once, on request, and acts on its words', (
    tester,
  ) async {
    final claude = _Claude();
    await open(tester, claudeKey: 'key', claude: claude);

    await tester.tap(find.byKey(const Key('reading_next_chapter')));
    await settle(tester);
    expect(find.text('Chapter 2 of 17'), findsOneWidget);
    expect(claude.requests, isEmpty);

    await tester.tap(find.byKey(const Key('reading_get_words')));
    await settle(tester);
    expect(claude.requests.single.chapter, 2);
    expect(find.text('vault'), findsOneWidget);
    expect(find.text('dodge'), findsOneWidget);
    expect(find.textContaining('כספת'), findsNothing);

    await tester.tap(find.text('Reveal meaning').first);
    await settle(tester);
    expect(find.textContaining('כספת'), findsOneWidget);

    await tester.tap(find.text('I know this').first);
    await settle(tester);
    expect(find.text('vault'), findsNothing);

    await tester.tap(find.text('Skip'));
    await settle(tester);
    expect(find.text('No words are waiting for this chapter.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('reading_previous_chapter')));
    await settle(tester);
    await tester.tap(find.byKey(const Key('reading_next_chapter')));
    await settle(tester);
    expect(find.text('No words are waiting for this chapter.'), findsOneWidget);
    expect(claude.requests, hasLength(1));
  });

  testWidgets('shows a Claude failure with a retry', (tester) async {
    final claude = _Claude(error: ClaudeErrorType.billing);
    await open(tester, claudeKey: 'key', claude: claude);

    await tester.tap(find.byKey(const Key('reading_get_words')));
    await settle(tester);

    expect(
      find.text(
        'Your Claude credit has run out. Check billing in the Claude Console.',
      ),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
  });
}

/// Lets real database work finish, then rebuilds.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
