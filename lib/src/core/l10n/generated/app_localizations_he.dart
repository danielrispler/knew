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
  String get searchPlaceholder => 'חיפוש מונחים או תרגומים...';

  @override
  String get noTermsFound => 'לא נמצאו מונחים';

  @override
  String get noTermsYet =>
      'אוסף המילים שלך ריק.\nלחץ על \'+\' כדי להוסיף את המונח הראשון שלך.';

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
  String get apiKeyHint => 'הדבק מפתח API כאן';

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
}
