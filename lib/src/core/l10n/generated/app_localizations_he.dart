// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hebrew (`he`).
class AppLocalizationsHe extends AppLocalizations {
  AppLocalizationsHe([String locale = 'he']) : super(locale);

  @override
  String get appTitle => 'knew';

  @override
  String get cancel => 'ביטול';

  @override
  String get save => 'שמירה';

  @override
  String get delete => 'מחיקה';

  @override
  String get ok => 'אישור';

  @override
  String get done => 'סיום';

  @override
  String get error => 'שגיאה';

  @override
  String get search => 'חיפוש';

  @override
  String get close => 'סגירה';

  @override
  String get vocabularyTitle => 'אוסף מילים';

  @override
  String get practiceTitle => 'סשן תרגול';

  @override
  String get practiceSummary => 'סיכום תרגול';

  @override
  String get settingsTitle => 'הגדרות';

  @override
  String get addTermTitle => 'הוספת מונח';

  @override
  String get editTermTitle => 'עריכת מונח';

  @override
  String get discoverTitle => 'גילוי';

  @override
  String get discoverNewBatch => 'קבוצה חדשה';

  @override
  String get discoverAllCaughtUp => 'סיימת לעת עתה';

  @override
  String get discoverMoreWords => 'מונחים נוספים';

  @override
  String get discoverRevealMeaning => 'חשוף משמעות';

  @override
  String get discoverKnown => 'אני מכיר/ה את זה';

  @override
  String get discoverSkip => 'דלג/י';

  @override
  String get discoverLearn => 'למד/י';

  @override
  String get searchPlaceholder => 'חיפוש מונחים או תרגומים...';

  @override
  String get noTermsFound => 'לא נמצאו מונחים';

  @override
  String get noTermsYet =>
      'אוסף המילים שלך ריק.\nלחץ על \'+\' כדי להוסיף את המונח הראשון שלך.';

  @override
  String get reviewStatusTitle => 'תרגול';

  @override
  String reviewDueCount(int count) {
    return 'ממתינים לתרגול: $count';
  }

  @override
  String reviewNext(String date) {
    return 'התרגול הבא: $date';
  }

  @override
  String get reviewNoneUpcoming => 'אין תרגול מתוכנן';

  @override
  String reviewProgress(int newCount, int familiarCount, int learnedCount) {
    return 'חדשים $newCount · מוכרים $familiarCount · נלמדו $learnedCount';
  }

  @override
  String reviewProcessingCount(int count) {
    return 'בעיבוד: $count';
  }

  @override
  String reviewFailedCount(int count) {
    return 'נכשלו: $count';
  }

  @override
  String get scheduledPractice => 'תרגול מתוזמן';

  @override
  String get filterAll => 'הכל';

  @override
  String get filterNew => 'חדשים (0-2)';

  @override
  String get filterFamiliar => 'מוכרים (3-4)';

  @override
  String get filterLearned => 'נלמדו (5-6)';

  @override
  String get dueBadge => 'לתרגול';

  @override
  String get startPractice => 'התחל תרגול';

  @override
  String get extraPractice => 'תרגול נוסף';

  @override
  String get noDueForPractice => 'אין מונחים הממתינים לתרגול';

  @override
  String get allCaughtUpTitle => 'סיימת את כל התרגולים להיום!';

  @override
  String get allCaughtUpDesc => 'תרגלת את כל המונחים שתוזמנו להיום.';

  @override
  String get earlyReviewTitle => 'התקדמות (תרגול מקדים)';

  @override
  String get earlyReviewDesc =>
      'תרגל כעת כדי לקדם מונחים לרמה הבאה לפני המועד.';

  @override
  String get repracticeTitle => 'תרגול חוזר (ללא שינוי רמה)';

  @override
  String get repracticeDesc =>
      'תרגול מונחים מבלי לשנות את רמתם או מועד התרגול הבא.';

  @override
  String reviewedTodayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count מונחים תורגלו היום',
      one: 'מונח אחד תורגל היום',
    );
    return '$_temp0';
  }

  @override
  String get earlyReviewBadge => 'תרגול מקדים';

  @override
  String get wordDetailTitle => 'פרטי מונח';

  @override
  String level(int level) {
    return 'רמה $level';
  }

  @override
  String get stageNew => 'חדש';

  @override
  String get stageFamiliar => 'מוכר';

  @override
  String get stageLearned => 'נלמד';

  @override
  String get meanings => 'משמעויות';

  @override
  String get source => 'מקור';

  @override
  String get context => 'הקשר';

  @override
  String lastReviewed(String date) {
    return 'תרגול אחרון: $date';
  }

  @override
  String get neverReviewed => 'תרגול אחרון: אף פעם';

  @override
  String nextReview(String date) {
    return 'תרגול הבא: $date';
  }

  @override
  String get resetProgress => 'איפוס התקדמות';

  @override
  String get resetProgressConfirm =>
      'האם אתה בטוח שברצונך לאפס את התקדמות הלמידה של מונח זה?';

  @override
  String get deleteTermConfirm => 'האם אתה בטוח שברצונך למחוק מונח זה?';

  @override
  String get termLabel => 'מונח (אנגלית)';

  @override
  String get termHint => 'למשל, persistent';

  @override
  String get lookupWithGemini => 'חיפוש באמצעות Gemini';

  @override
  String get quickCaptureTitle => 'הוספת מונחים';

  @override
  String get quickCaptureAdd => 'הוסף והמשך';

  @override
  String get quickCaptureProcessing => 'Gemini מעבד מונחים…';

  @override
  String get quickCaptureTermLabel => 'מונח באנגלית';

  @override
  String get quickCaptureTermHint => 'לדוגמה, persistent';

  @override
  String get quickCaptureEnglishRequired => 'יש להזין מונח באנגלית.';

  @override
  String get quickCaptureDuplicate => 'המונח כבר נמצא בספרייה שלך.';

  @override
  String get quickCaptureWaiting => 'מונחים מעובדים כשהאפליקציה פתוחה.';

  @override
  String get pendingEntryProcessing => 'בעיבוד';

  @override
  String get pendingEntryRetry => 'נסה שוב';

  @override
  String get meaningSection => 'משמעויות';

  @override
  String get partOfSpeech => 'חלק דיבר';

  @override
  String get hebrewTranslations => 'תרגומים לעברית (מופרדים בפסיקים)';

  @override
  String get englishDefinition => 'הגדרה באנגלית (רשות)';

  @override
  String get addMeaning => 'הוסף משמעות';

  @override
  String get removeMeaning => 'הסר';

  @override
  String get sourceLabel => 'מקור (רשות)';

  @override
  String get sourceHint => 'למשל, ספר: 1984, שם מאמר';

  @override
  String get contextSentenceLabel => 'משפט הקשר (רשות)';

  @override
  String get contextSentenceHint =>
      'למשל, She was persistent in seeking the truth.';

  @override
  String get saveTerm => 'שמור מונח';

  @override
  String get termRequired => 'נא להזין מונח';

  @override
  String get atLeastOneMeaningRequired => 'נא להוסיף לפחות משמעות אחת עם תרגום';

  @override
  String get practiceDefaults => 'ברירות מחדל לתרגול';

  @override
  String get sessionSize => 'גודל סשן';

  @override
  String entriesPerSession(int count) {
    return '$count מונחים בסשן';
  }

  @override
  String get appearance => 'מראה';

  @override
  String get themeSystem => 'מערכת';

  @override
  String get themeLight => 'בהיר';

  @override
  String get themeDark => 'כהה';

  @override
  String get appLanguage => 'שפת אפליקציה';

  @override
  String get languageSystem => 'ברירת מחדל של המערכת';

  @override
  String get languageEnglish => 'אנגלית (English)';

  @override
  String get languageHebrew => 'עברית';

  @override
  String get geminiSettings => 'הגדרות חיפוש מבוסס Gemini';

  @override
  String get primaryModelChoice => 'בחירת מודל ראשי';

  @override
  String get modelFallbackHelper =>
      'עובר אוטומטית למודלים נמוכים יותר (עד 3.5 Flash Lite) במקרה של עומס.';

  @override
  String get customModel => 'מודל מותאם אישית...';

  @override
  String get customModelName => 'שם מודל מותאם אישית';

  @override
  String get customModelHint => 'למשל, gemini-1.5-pro';

  @override
  String get customModelHelper =>
      'הזן מזהה מודל מדויק. גיבויים יופעלו אם המודל אינו זמין.';

  @override
  String get geminiApiKey => 'מפתח API של Gemini';

  @override
  String get apiKeyHint =>
      'הדבק כאן מפתח אימות מ-AI Studio. הגבל אותו ל-Gemini ולאפליקציה הזו כשמתאים.';

  @override
  String get apiKeySaved => 'מפתח ה-API נשמר בבטחה';

  @override
  String get testKeyConnection => 'בדוק חיבור מפתח';

  @override
  String get connectionSuccessful => 'החיבור הצליח! מפתח Gemini API פעיל.';

  @override
  String get dataBackup => 'נתונים וגיבוי';

  @override
  String get dataBackupDesc =>
      'ייצוא או ייבוא של אוסף המילים והתקדמות הלמידה שלך כקובץ גיבוי JSON.';

  @override
  String get exportBackup => 'ייצוא גיבוי';

  @override
  String get importBackup => 'ייבוא גיבוי';

  @override
  String get revealAnswer => 'חשוף תשובה';

  @override
  String get correct => 'נכון';

  @override
  String get incorrect => 'לא נכון';

  @override
  String get countAsCorrect => 'חשב כנכון';

  @override
  String get typeAnswerInHebrew => 'תשובה בעברית';

  @override
  String get typeAnswerInEnglish => 'תשובה באנגלית';

  @override
  String get typeHebrewHint => 'הקלד תשובה';

  @override
  String get typeEnglishHint => 'Type an answer';

  @override
  String get submitAnswer => 'שלח';

  @override
  String sentenceProductionPrompt(String term) {
    return 'כתוב משפט עם „$term”.';
  }

  @override
  String get sentenceProductionHint => 'כתוב את המשפט באנגלית';

  @override
  String get getFeedback => 'קבל משוב';

  @override
  String get nextQuestion => 'שאלה הבאה';

  @override
  String get sessionComplete => 'התרגול הושלם!';

  @override
  String sessionCompleteDesc(int count) {
    return 'עבודה מצוינת! סקרת $count מונחים.';
  }

  @override
  String accuracy(int percent) {
    return 'דיוק: $percent%';
  }

  @override
  String get returnToLibrary => 'חזור לספרייה';

  @override
  String get pronunciationUnavailable => 'הגייה באנגלית אינה זמינה.';

  @override
  String get listen => 'האזנה';

  @override
  String get retry => 'נסה שוב';

  @override
  String get next => 'הבא';

  @override
  String get checkAnswer => 'בדוק תשובה';

  @override
  String get showAnswer => 'הצג תשובה';

  @override
  String get didntKnow => 'לא ידעתי';

  @override
  String get knewIt => 'ידעתי';

  @override
  String get addEntry => 'הוסף מונח';

  @override
  String get noEntriesForPractice => 'אין מונחים זמינים לתרגול.';

  @override
  String questionProgress(int current, int total) {
    return 'שאלה $current מתוך $total';
  }

  @override
  String repeatProgress(int current, int total) {
    return 'חזרה $current מתוך $total';
  }

  @override
  String get selectOptionAbove => 'בחר אפשרות למעלה';

  @override
  String get multipleChoiceUnavailable => 'שאלה אמריקאית אינה זמינה';

  @override
  String get selectHebrewTranslation => 'בחר את התרגום הנכון לעברית:';

  @override
  String get selectEnglishTerm => 'בחר את המונח הנכון באנגלית:';

  @override
  String get fillBlank => 'השלם את החסר';

  @override
  String get showFirstLetter => 'הצג אות ראשונה';

  @override
  String answer(String answer) {
    return 'תשובה: $answer';
  }

  @override
  String get countTypoCorrect => 'חשב כנכון (טעות הקלדה)';

  @override
  String get exactMatch => 'התאמה מדויקת!';

  @override
  String typoExpected(String answer) {
    return 'נכון (טעות הקלדה: צפוי \"$answer\")';
  }

  @override
  String incorrectExpected(String answer) {
    return 'לא נכון. התשובה הצפויה: \"$answer\"';
  }

  @override
  String get tapToShowAnswer => 'לחץ להצגת התשובה';

  @override
  String get stageProgress => 'התקדמות בשלבים';

  @override
  String get deleteEntryTitle => 'למחוק מונח?';

  @override
  String deleteEntryConfirm(String term) {
    return 'האם למחוק את \"$term\"?';
  }

  @override
  String get listenToPronunciation => 'האזן להגייה';

  @override
  String sourceValue(String source) {
    return 'מקור: $source';
  }

  @override
  String get learningProgress => 'התקדמות למידה';

  @override
  String get levelLabel => 'רמה:';

  @override
  String get nextDueDate => 'מועד תרגול הבא:';

  @override
  String get lastReviewedLabel => 'תרגול אחרון:';

  @override
  String get never => 'אף פעם';

  @override
  String get timesCorrect => 'מספר תשובות נכונות:';

  @override
  String get timesIncorrect => 'מספר תשובות שגויות:';

  @override
  String get editEntry => 'ערוך מונח';

  @override
  String get deleteEntry => 'מחק מונח';

  @override
  String get libraryEnrichment => 'העשרת הספרייה';

  @override
  String enrichmentProgress(
    int completed,
    int total,
    int remaining,
    String term,
  ) {
    return '$completed/$total הושלמו · נותרו $remaining$term';
  }

  @override
  String entriesNeedEnrichment(int count) {
    return '$count מונחים זקוקים להעשרה';
  }

  @override
  String get startEnrichment => 'התחל העשרה';

  @override
  String get stopEnrichment => 'הפסק העשרה';

  @override
  String customModelSet(String model) {
    return 'נבחר מודל מותאם אישית: $model';
  }

  @override
  String get apiKeyRequired =>
      'הוסף את מפתח ה-API של Gemini בהגדרות, או הזן את המונח ידנית.';

  @override
  String connectionError(String error) {
    return 'שגיאת חיבור: $error';
  }

  @override
  String settingsLoadError(String error) {
    return 'שגיאה בטעינת ההגדרות: $error';
  }

  @override
  String get modelPickerTitle => 'בחירת מודל Gemini';

  @override
  String get modelPickerDescription =>
      'בחירה ראשית לחיפושים אוטומטיים. המערכת עוברת למודל חלופי במקרה של עומס.';

  @override
  String get modelDefault => 'ברירת מחדל – המודל החזק ביותר';

  @override
  String get modelHighPerformance => 'מודל בביצועים גבוהים';

  @override
  String get modelFastCapable => 'מודל מהיר ויעיל';

  @override
  String get modelBalanced => 'מודל מאוזן';

  @override
  String get modelFallback => 'חלופה מהירה וקלה';

  @override
  String get modelCustomDescription => 'הזן מזהה מודל מותאם אישית';

  @override
  String get exportEmpty => 'אין מונחים לייצוא.';

  @override
  String get backupShared => 'גיבוי אוסף המילים שותף בהצלחה.';

  @override
  String exportFailed(String error) {
    return 'הייצוא נכשל: $error';
  }

  @override
  String get importComplete => 'הייבוא הושלם';

  @override
  String importTotal(int count) {
    return 'סך הכול מונחים שעובדו: $count';
  }

  @override
  String importAdded(int count) {
    return '• נוספו: $count';
  }

  @override
  String importUpdated(int count) {
    return '• עודכנו: $count';
  }

  @override
  String importKept(int count) {
    return '• נשמרו כפי שהם: $count';
  }

  @override
  String get importFailed => 'הייבוא נכשל';

  @override
  String importError(String error) {
    return 'שגיאה בייבוא הגיבוי: $error';
  }

  @override
  String get clearInput => 'נקה קלט';

  @override
  String get viewEntry => 'הצג מונח';

  @override
  String get openSettings => 'פתח הגדרות';

  @override
  String entrySaved(String term) {
    return '\"$term\" נשמר בספרייה';
  }

  @override
  String entrySaveError(String error) {
    return 'שגיאה בשמירת המונח: $error';
  }

  @override
  String libraryLoadError(String error) {
    return 'שגיאה בטעינת הספרייה: $error';
  }

  @override
  String targetTermFeedback(String result) {
    return 'מונח היעד: $result';
  }

  @override
  String meaningFeedback(String result) {
    return 'משמעות: $result';
  }

  @override
  String grammarFeedback(String result) {
    return 'דקדוק: $result';
  }

  @override
  String naturalnessFeedback(String result) {
    return 'טבעיות (למשוב בלבד): $result';
  }
}
