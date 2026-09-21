import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/l10n/generated/app_localizations_en.dart';
import 'package:knew/src/core/l10n/generated/app_localizations_he.dart';

void main() {
  test('localizes the Discover title in English and Hebrew', () {
    expect(AppLocalizationsEn().discoverTitle, 'Discover');
    expect(AppLocalizationsHe().discoverTitle, 'גילוי');
  });

  test('localizes practice and backup feedback in both locales', () {
    final en = AppLocalizationsEn();
    final he = AppLocalizationsHe();

    expect(en.noEntriesForPractice, 'No entries available for practice.');
    expect(he.noEntriesForPractice, 'אין מונחים זמינים לתרגול.');
    expect(en.exportFailed('network'), 'Export failed: network');
    expect(he.exportFailed('network'), 'הייצוא נכשל: network');
  });
}
