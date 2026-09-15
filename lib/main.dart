import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/generated/app_localizations.dart';
import 'package:knew/src/core/theme/app_theme.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['FrankRuhlLibre'], license);
  });
  runApp(const ProviderScope(child: KnewApp()));
}

class KnewApp extends ConsumerWidget {
  const KnewApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeMode = settingsAsync.when(
      data: (s) => s.themeMode,
      loading: () => ThemeMode.system,
      error: (err, stack) => ThemeMode.system,
    );
    final locale = settingsAsync.when(
      data: (s) => s.locale,
      loading: () => null,
      error: (err, stack) => null,
    );

    return MaterialApp(
      title: 'knew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const VocabularyListScreen(),
    );
  }
}
