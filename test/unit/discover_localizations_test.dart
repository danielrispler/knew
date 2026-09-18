import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/core/l10n/generated/app_localizations_en.dart';
import 'package:knew/src/core/l10n/generated/app_localizations_he.dart';

void main() {
  test('localizes the Discover title in English and Hebrew', () {
    expect(AppLocalizationsEn().discoverTitle, 'Discover');
    expect(AppLocalizationsHe().discoverTitle, 'גילוי');
  });
}
