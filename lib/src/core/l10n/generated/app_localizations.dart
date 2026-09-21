import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_he.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('he'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'knew'**
  String get appTitle;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @vocabularyTitle.
  ///
  /// In en, this message translates to:
  /// **'Vocabulary'**
  String get vocabularyTitle;

  /// No description provided for @practiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Practice Session'**
  String get practiceTitle;

  /// No description provided for @practiceSummary.
  ///
  /// In en, this message translates to:
  /// **'Practice Summary'**
  String get practiceSummary;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @addTermTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Term'**
  String get addTermTitle;

  /// No description provided for @editTermTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Term'**
  String get editTermTitle;

  /// No description provided for @discoverTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get discoverTitle;

  /// No description provided for @discoverNewBatch.
  ///
  /// In en, this message translates to:
  /// **'New batch'**
  String get discoverNewBatch;

  /// No description provided for @discoverAllCaughtUp.
  ///
  /// In en, this message translates to:
  /// **'All caught up'**
  String get discoverAllCaughtUp;

  /// No description provided for @discoverMoreWords.
  ///
  /// In en, this message translates to:
  /// **'More terms'**
  String get discoverMoreWords;

  /// No description provided for @discoverRevealMeaning.
  ///
  /// In en, this message translates to:
  /// **'Reveal meaning'**
  String get discoverRevealMeaning;

  /// No description provided for @discoverKnown.
  ///
  /// In en, this message translates to:
  /// **'I know this'**
  String get discoverKnown;

  /// No description provided for @discoverSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get discoverSkip;

  /// No description provided for @discoverLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get discoverLearn;

  /// No description provided for @searchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search terms or meanings...'**
  String get searchPlaceholder;

  /// No description provided for @noTermsFound.
  ///
  /// In en, this message translates to:
  /// **'No terms found'**
  String get noTermsFound;

  /// No description provided for @noTermsYet.
  ///
  /// In en, this message translates to:
  /// **'Your vocabulary library is empty.\nTap \'+\' to add your first term.'**
  String get noTermsYet;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterNew.
  ///
  /// In en, this message translates to:
  /// **'New (0-2)'**
  String get filterNew;

  /// No description provided for @filterFamiliar.
  ///
  /// In en, this message translates to:
  /// **'Familiar (3-4)'**
  String get filterFamiliar;

  /// No description provided for @filterLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned (5-6)'**
  String get filterLearned;

  /// No description provided for @dueBadge.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get dueBadge;

  /// No description provided for @startPractice.
  ///
  /// In en, this message translates to:
  /// **'Start Practice'**
  String get startPractice;

  /// No description provided for @extraPractice.
  ///
  /// In en, this message translates to:
  /// **'Extra Practice'**
  String get extraPractice;

  /// No description provided for @noDueForPractice.
  ///
  /// In en, this message translates to:
  /// **'No terms due for practice'**
  String get noDueForPractice;

  /// No description provided for @allCaughtUpTitle.
  ///
  /// In en, this message translates to:
  /// **'All caught up for today!'**
  String get allCaughtUpTitle;

  /// No description provided for @allCaughtUpDesc.
  ///
  /// In en, this message translates to:
  /// **'You\'ve practiced all your scheduled terms for today.'**
  String get allCaughtUpDesc;

  /// No description provided for @earlyReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Advance (Early Review)'**
  String get earlyReviewTitle;

  /// No description provided for @earlyReviewDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice now to advance terms to the next stage early.'**
  String get earlyReviewDesc;

  /// No description provided for @repracticeTitle.
  ///
  /// In en, this message translates to:
  /// **'Repractice (Extra Practice)'**
  String get repracticeTitle;

  /// No description provided for @repracticeDesc.
  ///
  /// In en, this message translates to:
  /// **'Practice terms without changing their review schedules or levels.'**
  String get repracticeDesc;

  /// No description provided for @reviewedTodayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 term reviewed today} other{{count} terms reviewed today}}'**
  String reviewedTodayCount(int count);

  /// No description provided for @earlyReviewBadge.
  ///
  /// In en, this message translates to:
  /// **'Early Review'**
  String get earlyReviewBadge;

  /// No description provided for @wordDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Term Details'**
  String get wordDetailTitle;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @stageNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get stageNew;

  /// No description provided for @stageFamiliar.
  ///
  /// In en, this message translates to:
  /// **'Familiar'**
  String get stageFamiliar;

  /// No description provided for @stageLearned.
  ///
  /// In en, this message translates to:
  /// **'Learned'**
  String get stageLearned;

  /// No description provided for @meanings.
  ///
  /// In en, this message translates to:
  /// **'Meanings'**
  String get meanings;

  /// No description provided for @source.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @context.
  ///
  /// In en, this message translates to:
  /// **'Context'**
  String get context;

  /// No description provided for @lastReviewed.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed: {date}'**
  String lastReviewed(String date);

  /// No description provided for @neverReviewed.
  ///
  /// In en, this message translates to:
  /// **'Last reviewed: Never'**
  String get neverReviewed;

  /// No description provided for @nextReview.
  ///
  /// In en, this message translates to:
  /// **'Next review: {date}'**
  String nextReview(String date);

  /// No description provided for @resetProgress.
  ///
  /// In en, this message translates to:
  /// **'Reset Progress'**
  String get resetProgress;

  /// No description provided for @resetProgressConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to reset learning progress for this term?'**
  String get resetProgressConfirm;

  /// No description provided for @deleteTermConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this term?'**
  String get deleteTermConfirm;

  /// No description provided for @termLabel.
  ///
  /// In en, this message translates to:
  /// **'Term (English)'**
  String get termLabel;

  /// No description provided for @termHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., persistent'**
  String get termHint;

  /// No description provided for @lookupWithGemini.
  ///
  /// In en, this message translates to:
  /// **'Lookup with Gemini'**
  String get lookupWithGemini;

  /// No description provided for @quickCaptureTitle.
  ///
  /// In en, this message translates to:
  /// **'Add terms'**
  String get quickCaptureTitle;

  /// No description provided for @quickCaptureAdd.
  ///
  /// In en, this message translates to:
  /// **'Add and continue'**
  String get quickCaptureAdd;

  /// No description provided for @quickCaptureProcessing.
  ///
  /// In en, this message translates to:
  /// **'Gemini is processing terms…'**
  String get quickCaptureProcessing;

  /// No description provided for @meaningSection.
  ///
  /// In en, this message translates to:
  /// **'Meanings'**
  String get meaningSection;

  /// No description provided for @partOfSpeech.
  ///
  /// In en, this message translates to:
  /// **'Part of speech'**
  String get partOfSpeech;

  /// No description provided for @hebrewTranslations.
  ///
  /// In en, this message translates to:
  /// **'Hebrew translations (comma separated)'**
  String get hebrewTranslations;

  /// No description provided for @englishDefinition.
  ///
  /// In en, this message translates to:
  /// **'English definition (optional)'**
  String get englishDefinition;

  /// No description provided for @addMeaning.
  ///
  /// In en, this message translates to:
  /// **'Add Meaning'**
  String get addMeaning;

  /// No description provided for @removeMeaning.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeMeaning;

  /// No description provided for @sourceLabel.
  ///
  /// In en, this message translates to:
  /// **'Source (optional)'**
  String get sourceLabel;

  /// No description provided for @sourceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., Book: 1984, Article title'**
  String get sourceHint;

  /// No description provided for @contextSentenceLabel.
  ///
  /// In en, this message translates to:
  /// **'Context sentence (optional)'**
  String get contextSentenceLabel;

  /// No description provided for @contextSentenceHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., She was persistent in seeking the truth.'**
  String get contextSentenceHint;

  /// No description provided for @saveTerm.
  ///
  /// In en, this message translates to:
  /// **'Save Term'**
  String get saveTerm;

  /// No description provided for @termRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a term'**
  String get termRequired;

  /// No description provided for @atLeastOneMeaningRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one meaning with a translation'**
  String get atLeastOneMeaningRequired;

  /// No description provided for @practiceDefaults.
  ///
  /// In en, this message translates to:
  /// **'Practice Defaults'**
  String get practiceDefaults;

  /// No description provided for @sessionSize.
  ///
  /// In en, this message translates to:
  /// **'Session Size'**
  String get sessionSize;

  /// No description provided for @entriesPerSession.
  ///
  /// In en, this message translates to:
  /// **'{count} entries per session'**
  String entriesPerSession(int count);

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App Language'**
  String get appLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System Default'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageHebrew.
  ///
  /// In en, this message translates to:
  /// **'Hebrew (עברית)'**
  String get languageHebrew;

  /// No description provided for @geminiSettings.
  ///
  /// In en, this message translates to:
  /// **'Gemini Assisted Lookup Settings'**
  String get geminiSettings;

  /// No description provided for @primaryModelChoice.
  ///
  /// In en, this message translates to:
  /// **'Primary Model Choice'**
  String get primaryModelChoice;

  /// No description provided for @modelFallbackHelper.
  ///
  /// In en, this message translates to:
  /// **'Automatically falls back to lower models (down to 3.5 Flash Lite) if rate-limited.'**
  String get modelFallbackHelper;

  /// No description provided for @customModel.
  ///
  /// In en, this message translates to:
  /// **'Custom Model...'**
  String get customModel;

  /// No description provided for @customModelName.
  ///
  /// In en, this message translates to:
  /// **'Custom Model Name'**
  String get customModelName;

  /// No description provided for @customModelHint.
  ///
  /// In en, this message translates to:
  /// **'e.g., gemini-1.5-pro, tunedModels/my-model'**
  String get customModelHint;

  /// No description provided for @customModelHelper.
  ///
  /// In en, this message translates to:
  /// **'Enter exact model identifier. Fallbacks will apply if unavailable.'**
  String get customModelHelper;

  /// No description provided for @geminiApiKey.
  ///
  /// In en, this message translates to:
  /// **'Gemini API Key'**
  String get geminiApiKey;

  /// No description provided for @apiKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Paste an AI Studio auth key here. Restrict it to Gemini and this app where appropriate.'**
  String get apiKeyHint;

  /// No description provided for @apiKeySaved.
  ///
  /// In en, this message translates to:
  /// **'API Key saved securely'**
  String get apiKeySaved;

  /// No description provided for @testKeyConnection.
  ///
  /// In en, this message translates to:
  /// **'Test Key Connection'**
  String get testKeyConnection;

  /// No description provided for @connectionSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Connection successful! Gemini API key is active.'**
  String get connectionSuccessful;

  /// No description provided for @dataBackup.
  ///
  /// In en, this message translates to:
  /// **'Data & Backup'**
  String get dataBackup;

  /// No description provided for @dataBackupDesc.
  ///
  /// In en, this message translates to:
  /// **'Export or import your vocabulary library and learning progress as a backup JSON file.'**
  String get dataBackupDesc;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export Backup'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import Backup'**
  String get importBackup;

  /// No description provided for @revealAnswer.
  ///
  /// In en, this message translates to:
  /// **'Reveal Answer'**
  String get revealAnswer;

  /// No description provided for @correct.
  ///
  /// In en, this message translates to:
  /// **'Correct'**
  String get correct;

  /// No description provided for @incorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect'**
  String get incorrect;

  /// No description provided for @countAsCorrect.
  ///
  /// In en, this message translates to:
  /// **'Count as correct'**
  String get countAsCorrect;

  /// No description provided for @typeAnswerInHebrew.
  ///
  /// In en, this message translates to:
  /// **'Answer in Hebrew'**
  String get typeAnswerInHebrew;

  /// No description provided for @typeAnswerInEnglish.
  ///
  /// In en, this message translates to:
  /// **'Answer in English'**
  String get typeAnswerInEnglish;

  /// No description provided for @typeHebrewHint.
  ///
  /// In en, this message translates to:
  /// **'הקלד תשובה'**
  String get typeHebrewHint;

  /// No description provided for @typeEnglishHint.
  ///
  /// In en, this message translates to:
  /// **'Type an answer'**
  String get typeEnglishHint;

  /// No description provided for @submitAnswer.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submitAnswer;

  /// No description provided for @sentenceProductionPrompt.
  ///
  /// In en, this message translates to:
  /// **'Write a sentence using “{term}”.'**
  String sentenceProductionPrompt(String term);

  /// No description provided for @sentenceProductionHint.
  ///
  /// In en, this message translates to:
  /// **'Write your sentence in English'**
  String get sentenceProductionHint;

  /// No description provided for @getFeedback.
  ///
  /// In en, this message translates to:
  /// **'Get feedback'**
  String get getFeedback;

  /// No description provided for @nextQuestion.
  ///
  /// In en, this message translates to:
  /// **'Next Question'**
  String get nextQuestion;

  /// No description provided for @sessionComplete.
  ///
  /// In en, this message translates to:
  /// **'Practice Complete!'**
  String get sessionComplete;

  /// No description provided for @sessionCompleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Great job! You reviewed {count} terms.'**
  String sessionCompleteDesc(int count);

  /// No description provided for @accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy: {percent}%'**
  String accuracy(int percent);

  /// No description provided for @returnToLibrary.
  ///
  /// In en, this message translates to:
  /// **'Return to Library'**
  String get returnToLibrary;

  /// No description provided for @pronunciationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'English pronunciation unavailable.'**
  String get pronunciationUnavailable;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'he'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'he':
      return AppLocalizationsHe();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
