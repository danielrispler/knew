library;

/// Helper functions for Hebrew niqqud stripping and search string normalization
/// per sqlite-schema.md.

/// Removes Hebrew combining marks (U+0591–U+05BD, U+05BF, U+05C1–U+05C2, U+05C4–U+05C5, U+05C7).
String stripNiqqud(String input) {
  final buffer = StringBuffer();
  for (final codeUnit in input.codeUnits) {
    if ((codeUnit >= 0x0591 && codeUnit <= 0x05BD) ||
        codeUnit == 0x05BF ||
        (codeUnit >= 0x05C1 && codeUnit <= 0x05C2) ||
        (codeUnit >= 0x05C4 && codeUnit <= 0x05C5) ||
        codeUnit == 0x05C7) {
      continue;
    }
    buffer.writeCharCode(codeUnit);
  }
  return buffer.toString();
}

/// Lowercases, trims, collapses internal whitespace, and strips Hebrew niqqud.
String normalizeForSearch(String input) {
  final stripped = stripNiqqud(input).trim().toLowerCase();
  return stripped.replaceAll(RegExp(r'\s+'), ' ');
}
