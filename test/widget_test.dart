import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/main.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_providers.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';

class TestVocabularyListNotifier extends VocabularyListNotifier {
  @override
  Future<List<Entry>> build() async {
    return [];
  }
}

class TestSettingsNotifier extends SettingsNotifier {
  @override
  Future<SettingsState> build() async {
    return const SettingsState(
      sessionSize: 20,
      theme: 'system',
      model: 'gemini-3.8-flash',
      apiKey: '',
    );
  }
}

void main() {
  testWidgets('KnewApp renders VocabularyListScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vocabularyListProvider.overrideWith(() => TestVocabularyListNotifier()),
          settingsProvider.overrideWith(() => TestSettingsNotifier()),
        ],
        child: const KnewApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('knew'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}
