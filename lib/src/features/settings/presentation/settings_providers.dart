import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../../vocabulary/domain/library_enrichment_controller.dart';
import '../data/secure_storage_repository.dart';
import '../data/settings_repository.dart';
import '../data/sqlite_settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => SQLiteSettingsRepository(db),
    loading: () => throw UnimplementedError('Database is loading'),
    error: (err, stack) => throw err,
  );
});

final secureStorageRepositoryProvider = Provider<SecureStorageRepository>((
  ref,
) {
  return SecureStorageRepository();
});

class SettingsState {
  final int sessionSize;
  final String theme;
  final String model;
  final String apiKey;
  final String language;
  final bool isLoading;

  const SettingsState({
    required this.sessionSize,
    required this.theme,
    required this.model,
    required this.apiKey,
    this.language = 'system',
    this.isLoading = false,
  });

  ThemeMode get themeMode {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Locale? get locale {
    switch (language) {
      case 'en':
        return const Locale('en');
      case 'he':
        return const Locale('he');
      case 'system':
      default:
        return null;
    }
  }

  SettingsState copyWith({
    int? sessionSize,
    String? theme,
    String? model,
    String? apiKey,
    String? language,
    bool? isLoading,
  }) {
    return SettingsState(
      sessionSize: sessionSize ?? this.sessionSize,
      theme: theme ?? this.theme,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
      language: language ?? this.language,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SettingsNotifier extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final settingsRepo = ref.watch(settingsRepositoryProvider);
    final secureStorageRepo = ref.watch(secureStorageRepositoryProvider);

    final sessionSize = await settingsRepo.getSessionSize();
    final theme = await settingsRepo.getTheme();
    final model = await settingsRepo.getModel();
    final apiKey = await secureStorageRepo.getApiKey() ?? '';
    final language = await settingsRepo.getLanguage();

    return SettingsState(
      sessionSize: sessionSize,
      theme: theme,
      model: model,
      apiKey: apiKey,
      language: language,
    );
  }

  Future<void> setSessionSize(int size) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setSessionSize(size);
    state = AsyncValue.data(
      (state.value ??
              const SettingsState(
                sessionSize: 20,
                theme: 'system',
                model: 'gemini-3.8-flash',
                apiKey: '',
                language: 'system',
              ))
          .copyWith(sessionSize: size),
    );
  }

  Future<void> setTheme(String theme) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setTheme(theme);
    state = AsyncValue.data(
      (state.value ??
              const SettingsState(
                sessionSize: 20,
                theme: 'system',
                model: 'gemini-3.8-flash',
                apiKey: '',
                language: 'system',
              ))
          .copyWith(theme: theme),
    );
  }

  Future<void> setLanguage(String language) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setLanguage(language);
    state = AsyncValue.data(
      (state.value ??
              const SettingsState(
                sessionSize: 20,
                theme: 'system',
                model: 'gemini-3.8-flash',
                apiKey: '',
                language: 'system',
              ))
          .copyWith(language: language),
    );
  }

  Future<void> setModel(String model) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setModel(model);
    state = AsyncValue.data(
      (state.value ??
              const SettingsState(
                sessionSize: 20,
                theme: 'system',
                model: 'gemini-3.8-flash',
                apiKey: '',
                language: 'system',
              ))
          .copyWith(model: model),
    );
  }

  Future<void> setApiKey(String apiKey) async {
    final secureStorageRepo = ref.read(secureStorageRepositoryProvider);
    await secureStorageRepo.setApiKey(apiKey);
    state = AsyncValue.data(
      (state.value ??
              const SettingsState(
                sessionSize: 20,
                theme: 'system',
                model: 'gemini-3.8-flash',
                apiKey: '',
                language: 'system',
              ))
          .copyWith(apiKey: apiKey),
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(
  () {
    return SettingsNotifier();
  },
);

final libraryEnrichmentProvider =
    ChangeNotifierProvider<LibraryEnrichmentController>((ref) {
      final repository = ref.watch(wordsRepositoryProvider);
      final client = ref.watch(geminiClientProvider);
      final controller = LibraryEnrichmentController(
        repository: repository,
        enrich: (entry) {
          final settings = ref.read(settingsProvider).value!;
          return client.enrichWithFallback(
            term: entry.english,
            meanings: entry.meanings
                .where((meaning) => meaning.enrichedAt == null)
                .toList(),
            apiKey: settings.apiKey,
            primaryModel: settings.model,
          );
        },
      );
      controller.refresh();
      return controller;
    });
