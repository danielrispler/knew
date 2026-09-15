// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'knew';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get error => 'Error';

  @override
  String get search => 'Search';

  @override
  String get close => 'Close';

  @override
  String get vocabularyTitle => 'Vocabulary';

  @override
  String get practiceTitle => 'Practice Session';

  @override
  String get practiceSummary => 'Practice Summary';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get addTermTitle => 'Add Term';

  @override
  String get editTermTitle => 'Edit Term';

  @override
  String get searchPlaceholder => 'Search terms or meanings...';

  @override
  String get noTermsFound => 'No terms found';

  @override
  String get noTermsYet =>
      'Your vocabulary library is empty.\nTap \'+\' to add your first term.';

  @override
  String get filterAll => 'All';

  @override
  String get filterNew => 'New (0-2)';

  @override
  String get filterFamiliar => 'Familiar (3-4)';

  @override
  String get filterLearned => 'Learned (5-6)';

  @override
  String get dueBadge => 'Due';

  @override
  String get startPractice => 'Start Practice';

  @override
  String get extraPractice => 'Extra Practice';

  @override
  String get noDueForPractice => 'No terms due for practice';

  @override
  String get wordDetailTitle => 'Term Details';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String get stageNew => 'New';

  @override
  String get stageFamiliar => 'Familiar';

  @override
  String get stageLearned => 'Learned';

  @override
  String get meanings => 'Meanings';

  @override
  String get source => 'Source';

  @override
  String get context => 'Context';

  @override
  String lastReviewed(String date) {
    return 'Last reviewed: $date';
  }

  @override
  String get neverReviewed => 'Last reviewed: Never';

  @override
  String nextReview(String date) {
    return 'Next review: $date';
  }

  @override
  String get resetProgress => 'Reset Progress';

  @override
  String get resetProgressConfirm =>
      'Are you sure you want to reset learning progress for this term?';

  @override
  String get deleteTermConfirm => 'Are you sure you want to delete this term?';

  @override
  String get termLabel => 'Term (English)';

  @override
  String get termHint => 'e.g., persistent';

  @override
  String get lookupWithGemini => 'Lookup with Gemini';

  @override
  String get meaningSection => 'Meanings';

  @override
  String get partOfSpeech => 'Part of speech';

  @override
  String get hebrewTranslations => 'Hebrew translations (comma separated)';

  @override
  String get englishDefinition => 'English definition (optional)';

  @override
  String get addMeaning => 'Add Meaning';

  @override
  String get removeMeaning => 'Remove';

  @override
  String get sourceLabel => 'Source (optional)';

  @override
  String get sourceHint => 'e.g., Book: 1984, Article title';

  @override
  String get contextSentenceLabel => 'Context sentence (optional)';

  @override
  String get contextSentenceHint =>
      'e.g., She was persistent in seeking the truth.';

  @override
  String get saveTerm => 'Save Term';

  @override
  String get termRequired => 'Please enter a term';

  @override
  String get atLeastOneMeaningRequired =>
      'Please add at least one meaning with a translation';

  @override
  String get practiceDefaults => 'Practice Defaults';

  @override
  String get sessionSize => 'Session Size';

  @override
  String entriesPerSession(int count) {
    return '$count entries per session';
  }

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get appLanguage => 'App Language';

  @override
  String get languageSystem => 'System Default';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageHebrew => 'Hebrew (עברית)';

  @override
  String get geminiSettings => 'Gemini Assisted Lookup Settings';

  @override
  String get primaryModelChoice => 'Primary Model Choice';

  @override
  String get modelFallbackHelper =>
      'Automatically falls back to lower models (down to 3.5 Flash Lite) if rate-limited.';

  @override
  String get customModel => 'Custom Model...';

  @override
  String get customModelName => 'Custom Model Name';

  @override
  String get customModelHint => 'e.g., gemini-1.5-pro, tunedModels/my-model';

  @override
  String get customModelHelper =>
      'Enter exact model identifier. Fallbacks will apply if unavailable.';

  @override
  String get geminiApiKey => 'Gemini API Key';

  @override
  String get apiKeyHint => 'Paste API key here';

  @override
  String get apiKeySaved => 'API Key saved securely';

  @override
  String get testKeyConnection => 'Test Key Connection';

  @override
  String get connectionSuccessful =>
      'Connection successful! Gemini API key is active.';

  @override
  String get dataBackup => 'Data & Backup';

  @override
  String get dataBackupDesc =>
      'Export or import your vocabulary library and learning progress as a backup JSON file.';

  @override
  String get exportBackup => 'Export Backup';

  @override
  String get importBackup => 'Import Backup';

  @override
  String get revealAnswer => 'Reveal Answer';

  @override
  String get correct => 'Correct';

  @override
  String get incorrect => 'Incorrect';

  @override
  String get countAsCorrect => 'Count as correct';

  @override
  String get typeAnswerInHebrew => 'Answer in Hebrew';

  @override
  String get typeAnswerInEnglish => 'Answer in English';

  @override
  String get typeHebrewHint => 'הקלד תשובה';

  @override
  String get typeEnglishHint => 'Type an answer';

  @override
  String get submitAnswer => 'Submit';

  @override
  String get nextQuestion => 'Next Question';

  @override
  String get sessionComplete => 'Practice Complete!';

  @override
  String sessionCompleteDesc(int count) {
    return 'Great job! You reviewed $count terms.';
  }

  @override
  String accuracy(int percent) {
    return 'Accuracy: $percent%';
  }

  @override
  String get returnToLibrary => 'Return to Library';

  @override
  String get pronunciationUnavailable => 'English pronunciation unavailable.';
}
