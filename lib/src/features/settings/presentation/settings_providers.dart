import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
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

final secureStorageRepositoryProvider = Provider<SecureStorageRepository>((ref) {
  return SecureStorageRepository();
});

class SettingsState {
  final int sessionSize;
  final String theme;
  final String model;
  final String apiKey;
  final bool isLoading;

  const SettingsState({
    required this.sessionSize,
    required this.theme,
    required this.model,
    required this.apiKey,
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

  SettingsState copyWith({
    int? sessionSize,
    String? theme,
    String? model,
    String? apiKey,
    bool? isLoading,
  }) {
    return SettingsState(
      sessionSize: sessionSize ?? this.sessionSize,
      theme: theme ?? this.theme,
      model: model ?? this.model,
      apiKey: apiKey ?? this.apiKey,
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

    return SettingsState(
      sessionSize: sessionSize,
      theme: theme,
      model: model,
      apiKey: apiKey,
    );
  }

  Future<void> setSessionSize(int size) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setSessionSize(size);
    state = AsyncValue.data(
      (state.value ?? const SettingsState(sessionSize: 20, theme: 'system', model: 'gemini-2.5-flash', apiKey: ''))
          .copyWith(sessionSize: size),
    );
  }

  Future<void> setTheme(String theme) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setTheme(theme);
    state = AsyncValue.data(
      (state.value ?? const SettingsState(sessionSize: 20, theme: 'system', model: 'gemini-2.5-flash', apiKey: ''))
          .copyWith(theme: theme),
    );
  }

  Future<void> setModel(String model) async {
    final settingsRepo = ref.read(settingsRepositoryProvider);
    await settingsRepo.setModel(model);
    state = AsyncValue.data(
      (state.value ?? const SettingsState(sessionSize: 20, theme: 'system', model: 'gemini-2.5-flash', apiKey: ''))
          .copyWith(model: model),
    );
  }

  Future<void> setApiKey(String apiKey) async {
    final secureStorageRepo = ref.read(secureStorageRepositoryProvider);
    await secureStorageRepo.setApiKey(apiKey);
    state = AsyncValue.data(
      (state.value ?? const SettingsState(sessionSize: 20, theme: 'system', model: 'gemini-2.5-flash', apiKey: ''))
          .copyWith(apiKey: apiKey),
    );
  }
}

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
