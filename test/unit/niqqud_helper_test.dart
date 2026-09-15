import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/domain/niqqud_helper.dart';

void main() {
  group('NiqqudHelper', () {
    test('stripNiqqud removes Hebrew diacritics / niqqud combining marks', () {
      // Hebrew word "שָׁלוֹם" with niqqud -> "שלום"
      const withNiqqud = 'שָׁלוֹם';
      final stripped = stripNiqqud(withNiqqud);
      expect(stripped, equals('שלום'));
    });

    test('stripNiqqud leaves text without niqqud unchanged', () {
      const plainHebrew = 'עיקש';
      expect(stripNiqqud(plainHebrew), equals('עיקש'));
    });

    test('normalizeForSearch lowercases, trims, and strips niqqud', () {
      const input = '  מִתְמַדֵּא  ';
      expect(normalizeForSearch(input), equals('מתמדא'));
    });

    test('normalizeForSearch works on English terms', () {
      const input = '  Persistent ';
      expect(normalizeForSearch(input), equals('persistent'));
    });
  });
}
