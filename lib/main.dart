import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/theme/app_theme.dart';
import 'package:knew/src/features/settings/presentation/settings_providers.dart';
import 'package:knew/src/features/vocabulary/presentation/vocabulary_list_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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

    return MaterialApp(
      title: 'knew',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const VocabularyListScreen(),
    );
  }
}
