import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/generated/app_localizations.dart';
import 'package:knew/src/features/settings/data/secure_storage_repository.dart';
import 'package:knew/src/features/settings/data/settings_repository.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
import 'package:knew/src/features/settings/presentation/settings_screen.dart';

class FakeSettingsRepository implements SettingsRepository {
  int sessionSize = 20;
  String theme = 'system';
  String model = 'gemini-3.8-flash';
  String lastSource = '';
  String language = 'system';

  @override
  Future<int> getSessionSize() async => sessionSize;

  @override
  Future<void> setSessionSize(int size) async {
    sessionSize = size;
  }

  @override
  Future<String> getTheme() async => theme;

  @override
  Future<void> setTheme(String t) async {
    theme = t;
  }

  @override
  Future<String> getModel() async => model;

  @override
  Future<void> setModel(String m) async {
    model = m;
  }

  @override
  Future<String> getLastSource() async => lastSource;

  @override
  Future<void> setLastSource(String s) async {
    lastSource = s;
  }

  @override
  Future<String> getLanguage() async => language;

  @override
  Future<void> setLanguage(String l) async {
    language = l;
  }
}

class FakeSecureStorageRepository implements SecureStorageRepository {
  @override
  Future<String?> getApiKey() async => '';
  @override
  Future<void> setApiKey(String key) async {}
  @override
  Future<void> deleteApiKey() async {}
}

void main() {
  testWidgets('SettingsScreen displays app language option and updates provider state', (tester) async {
    final fakeRepo = FakeSettingsRepository();
    final fakeSecure = FakeSecureStorageRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(fakeRepo),
          secureStorageRepositoryProvider.overrideWithValue(fakeSecure),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();

    // Verify App Language header is rendered
    expect(find.text('App Language'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Hebrew (עברית)'), findsOneWidget);

    // Tap Hebrew option
    await tester.tap(find.text('Hebrew (עברית)'));
    await tester.pump();
    await tester.pump(Duration.zero);
    await tester.pump();

    expect(fakeRepo.language, 'he');
  });
}
