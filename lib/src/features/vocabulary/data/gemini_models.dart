class GeminiModels {
  static const String gemini38Flash = 'gemini-3.8-flash';
  static const String gemini37Flash = 'gemini-3.7-flash';
  static const String gemini36Flash = 'gemini-3.6-flash';
  static const String gemini35Flash = 'gemini-3.5-flash';
  static const String gemini35FlashLite = 'gemini-3.5-flash-lite';

  static const String defaultModel = gemini38Flash;

  static const List<String> availableModels = [
    gemini38Flash,
    gemini37Flash,
    gemini36Flash,
    gemini35Flash,
    gemini35FlashLite,
  ];

  static List<String> getFallbackSequence(String primaryModel) {
    if (primaryModel == gemini35FlashLite) {
      return [gemini35FlashLite];
    }
    return [primaryModel, gemini35FlashLite];
  }
}
