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
  String get discoverTitle => 'Discover';

  @override
  String get discoverNewBatch => 'New batch';

  @override
  String get discoverAllCaughtUp => 'All caught up';

  @override
  String get discoverMoreWords => 'More terms';

  @override
  String get discoverRevealMeaning => 'Reveal meaning';

  @override
  String get discoverKnown => 'I know this';

  @override
  String get discoverSkip => 'Skip';

  @override
  String get discoverLearn => 'Learn';

  @override
  String get searchPlaceholder => 'Search terms or meanings...';

  @override
  String get noTermsFound => 'No terms found';

  @override
  String get noTermsYet =>
      'Your vocabulary library is empty.\nTap \'+\' to add your first term.';

  @override
  String get reviewStatusTitle => 'Review';

  @override
  String reviewDueCount(int count) {
    return 'Due: $count';
  }

  @override
  String reviewNext(String date) {
    return 'Next review: $date';
  }

  @override
  String get reviewNoneUpcoming => 'No upcoming review';

  @override
  String reviewProgress(int newCount, int familiarCount, int learnedCount) {
    return 'New $newCount · Familiar $familiarCount · Learned $learnedCount';
  }

  @override
  String reviewProcessingCount(int count) {
    return 'Processing: $count';
  }

  @override
  String reviewFailedCount(int count) {
    return 'Failed: $count';
  }

  @override
  String get scheduledPractice => 'Scheduled practice';

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
  String get allCaughtUpTitle => 'All caught up for today!';

  @override
  String get allCaughtUpDesc =>
      'You\'ve practiced all your scheduled terms for today.';

  @override
  String get earlyReviewTitle => 'Advance (Early Review)';

  @override
  String get earlyReviewDesc =>
      'Practice now to advance terms to the next stage early.';

  @override
  String get repracticeTitle => 'Repractice (Extra Practice)';

  @override
  String get repracticeDesc =>
      'Practice terms without changing their review schedules or levels.';

  @override
  String reviewedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terms reviewed today',
      one: '1 term reviewed today',
    );
    return '$_temp0';
  }

  @override
  String get earlyReviewBadge => 'Early Review';

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
  String get quickCaptureTitle => 'Add terms';

  @override
  String get quickCaptureAdd => 'Add and continue';

  @override
  String get quickCaptureProcessing => 'Gemini is processing terms…';

  @override
  String get quickCaptureTermLabel => 'English term';

  @override
  String get quickCaptureTermHint => 'e.g., persistent';

  @override
  String get quickCaptureEnglishRequired => 'Enter an English term.';

  @override
  String get quickCaptureDuplicate => 'This term is already in your library.';

  @override
  String get quickCaptureWaiting =>
      'Terms are processed while the app is open.';

  @override
  String get pendingEntryProcessing => 'Processing';

  @override
  String get pendingEntryRetry => 'Retry';

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
  String get apiKeyHint =>
      'Paste an AI Studio auth key here. Restrict it to Gemini and this app where appropriate.';

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
  String sentenceProductionPrompt(String term) {
    return 'Write a sentence using “$term”.';
  }

  @override
  String get sentenceProductionHint => 'Write your sentence in English';

  @override
  String get getFeedback => 'Get feedback';

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

  @override
  String get listen => 'Listen';

  @override
  String get retry => 'Retry';

  @override
  String get next => 'Next';

  @override
  String get checkAnswer => 'Check answer';

  @override
  String get showAnswer => 'Show answer';

  @override
  String get didntKnow => 'Didn\'t know';

  @override
  String get knewIt => 'Knew it';

  @override
  String get addEntry => 'Add entry';

  @override
  String get noEntriesForPractice => 'No entries available for practice.';

  @override
  String questionProgress(int current, int total) {
    return 'Question $current of $total';
  }

  @override
  String repeatProgress(int current, int total) {
    return 'Repeat $current of $total';
  }

  @override
  String get selectOptionAbove => 'Select an option above';

  @override
  String get multipleChoiceUnavailable => 'Multiple choice unavailable';

  @override
  String get selectHebrewTranslation =>
      'Select the correct Hebrew translation:';

  @override
  String get selectEnglishTerm => 'Select the correct English term:';

  @override
  String get fillBlank => 'Fill in the blank';

  @override
  String get showFirstLetter => 'Show first letter';

  @override
  String answer(String answer) {
    return 'Answer: $answer';
  }

  @override
  String get countTypoCorrect => 'Count as correct (typo)';

  @override
  String get exactMatch => 'Exact match!';

  @override
  String typoExpected(String answer) {
    return 'Correct (typo: expected \"$answer\")';
  }

  @override
  String incorrectExpected(String answer) {
    return 'Incorrect. Expected: \"$answer\"';
  }

  @override
  String get tapToShowAnswer => 'Tap to show answer';

  @override
  String get stageProgress => 'Stage Progress';

  @override
  String get deleteEntryTitle => 'Delete Entry?';

  @override
  String deleteEntryConfirm(String term) {
    return 'Are you sure you want to delete \"$term\"?';
  }

  @override
  String get listenToPronunciation => 'Listen to pronunciation';

  @override
  String sourceValue(String source) {
    return 'Source: $source';
  }

  @override
  String get learningProgress => 'Learning Progress';

  @override
  String get levelLabel => 'Level:';

  @override
  String get nextDueDate => 'Next Due Date:';

  @override
  String get lastReviewedLabel => 'Last Reviewed:';

  @override
  String get never => 'Never';

  @override
  String get timesCorrect => 'Times Correct:';

  @override
  String get timesIncorrect => 'Times Incorrect:';

  @override
  String get editEntry => 'Edit Entry';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get libraryEnrichment => 'Library Enrichment';

  @override
  String enrichmentProgress(
    int completed,
    int total,
    int remaining,
    String term,
  ) {
    return '$completed/$total complete · $remaining remaining$term';
  }

  @override
  String entriesNeedEnrichment(int count) {
    return '$count entries need enrichment';
  }

  @override
  String get startEnrichment => 'Start enrichment';

  @override
  String get stopEnrichment => 'Stop enrichment';

  @override
  String customModelSet(String model) {
    return 'Custom model set to: $model';
  }

  @override
  String get apiKeyRequired =>
      'Add your Gemini API key in Settings, or enter the term manually.';

  @override
  String connectionError(String error) {
    return 'Connection error: $error';
  }

  @override
  String settingsLoadError(String error) {
    return 'Error loading settings: $error';
  }

  @override
  String get modelPickerTitle => 'Select Gemini Model';

  @override
  String get modelPickerDescription =>
      'Primary choice for automated lookups. Automatically falls back if rate-limited.';

  @override
  String get modelDefault => 'Default - Strongest model';

  @override
  String get modelHighPerformance => 'High performance model';

  @override
  String get modelFastCapable => 'Fast & capable model';

  @override
  String get modelBalanced => 'Balanced standard model';

  @override
  String get modelFallback => 'Lightweight fast fallback';

  @override
  String get modelCustomDescription => 'Specify custom model identifier';

  @override
  String get exportEmpty => 'No vocabulary entries to export.';

  @override
  String get backupShared => 'Vocabulary backup shared successfully.';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importComplete => 'Import Complete';

  @override
  String importTotal(int count) {
    return 'Total entries processed: $count';
  }

  @override
  String importAdded(int count) {
    return '• Added: $count';
  }

  @override
  String importUpdated(int count) {
    return '• Updated: $count';
  }

  @override
  String importKept(int count) {
    return '• Kept existing (skipped): $count';
  }

  @override
  String get importFailed => 'Import Failed';

  @override
  String importError(String error) {
    return 'Error importing backup: $error';
  }

  @override
  String get clearInput => 'Clear input';

  @override
  String get viewEntry => 'View Entry';

  @override
  String get openSettings => 'Open Settings';

  @override
  String entrySaved(String term) {
    return 'Saved \"$term\" to library';
  }

  @override
  String entrySaveError(String error) {
    return 'Error saving entry: $error';
  }

  @override
  String libraryLoadError(String error) {
    return 'Error loading library: $error';
  }

  @override
  String targetTermFeedback(String result) {
    return 'Target term: $result';
  }

  @override
  String meaningFeedback(String result) {
    return 'Meaning: $result';
  }

  @override
  String grammarFeedback(String result) {
    return 'Grammar: $result';
  }

  @override
  String naturalnessFeedback(String result) {
    return 'Naturalness (feedback only): $result';
  }
}
