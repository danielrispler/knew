abstract class SettingsRepository {
  Future<int> getSessionSize();
  Future<void> setSessionSize(int size);

  Future<String> getTheme();
  Future<void> setTheme(String theme);

  Future<String> getModel();
  Future<void> setModel(String model);

  Future<String> getLastSource();
  Future<void> setLastSource(String source);
}
