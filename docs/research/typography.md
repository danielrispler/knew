# Frank Ruhl Libre and mixed-script typography

Research for [#5](https://github.com/danielrispler/knew/issues/5), within [map #2](https://github.com/danielrispler/knew/issues/2). Requirements: [original brief #1](https://github.com/danielrispler/knew/issues/1). Checked 2026-09-15.

## Recommendation

Bundle the upstream static Regular 400 and Medium 500 TTFs, plus their OFL licence. Use Frank Ruhl Libre only for the practiced word and its revealed translation; keep surrounding UI in the platform font. Both selected files cover English and Hebrew letters and ordinary niqqud. Use 48 logical pixels for a prompt and 36 for longer phrases/revealed translations, respecting the inherited text scaler and allowing wrapping and scrolling. These sizes are design choices for implementation, not a claim that a finished app has passed device testing.

## Exact assets and cost

Google Fonts currently distributes a variable font. Its metadata identifies Hebrew, Latin and Latin Extended subsets, a weight axis from 300–900, and upstream source commit `2372d1998e51dc011f86554c0d23f1ccf44afddf`. That same upstream commit also contains static faces; download those directly rather than relying on the changing contents of a Google Fonts ZIP. [Google Fonts metadata](https://raw.githubusercontent.com/google/fonts/main/ofl/frankruhllibre/METADATA.pb).

The following sizes were verified from the actual binary responses and the upstream Git tree. Sizes are uncompressed asset bytes, not installed APK/IPA impact; package compression changes the latter.

| Asset at pinned upstream commit | Bytes | Use |
| --- | ---: | --- |
| [fonts/ttf/FrankRuhlLibre-Regular.ttf](https://github.com/fontef/frankruhllibre/blob/2372d1998e51dc011f86554c0d23f1ccf44afddf/fonts/ttf/FrankRuhlLibre-Regular.ttf) | 98,288 | Bundle, weight 400 |
| [fonts/ttf/FrankRuhlLibre-Medium.ttf](https://github.com/fontef/frankruhllibre/blob/2372d1998e51dc011f86554c0d23f1ccf44afddf/fonts/ttf/FrankRuhlLibre-Medium.ttf) | 98,792 | Bundle, weight 500 |
| [fonts/variable/FrankRuhlLibre[wght].ttf](https://github.com/fontef/frankruhllibre/blob/2372d1998e51dc011f86554c0d23f1ccf44afddf/fonts/variable/FrankRuhlLibre%5Bwght%5D.ttf) | 178,468 | Alternative only |
| [OFL.txt](https://github.com/fontef/frankruhllibre/blob/2372d1998e51dc011f86554c0d23f1ccf44afddf/OFL.txt) | 4,502 | Bundle licence |

The two static faces total **197,080 bytes** (192.46 KiB), or 201,582 bytes including the licence. The variable font saves 18,612 bytes (18.18 KiB, 9.44% of the two-font total). That is a small enough difference to prefer explicit static weight declarations for this two-weight use case. This is a simplicity tradeoff, not a claim that Flutter cannot render variable fonts: Flutter exposes variable axes through `TextStyle.fontVariations`, including `FontVariation.weight`. [Flutter variable-font API](https://api.flutter.dev/flutter/dart-ui/FontVariation-class.html).

SHA-256 values from the downloaded binaries:

```text
Regular  20d7b981d876c9ddb0f9109c409b4e495b84f486457f6f220307de3afcf70e04
Medium   73b01157af9e1ff5d4a2690a23a7c14cb746fa71d8b0b72d07d980df6a60d0ea
Variable f9bf26966681037aae894b031bd0dcf2c1bfdfa128dd0640cf276fe62a338a43
```

Use the linked pinned files' raw download, preserving their names. No runtime font download or `google_fonts` dependency is necessary.

## Licence handling

The font uses SIL Open Font License 1.1. Bundling with an app is permitted, including commercial distribution. Every distributed copy must retain the font copyright notice and licence in a user-viewable form. The font itself stays under OFL, cannot be sold by itself, and the authors' names cannot imply endorsement. This does not require licensing the application under OFL. Ship the upstream `OFL.txt` unchanged, including its copyright notice. [Bundled OFL text and conditions](https://raw.githubusercontent.com/google/fonts/main/ofl/frankruhllibre/OFL.txt).

Implementation recommendation: add the licence as an asset, register its contents through `LicenseRegistry.addLicense`, and expose Flutter's licences page from Settings. This provides a readable notice without placing attribution on the practice screen. Registering the custom asset is explicit; do not assume the font declaration automatically discovers its adjacent licence. [LicenseRegistry.addLicense](https://api.flutter.dev/flutter/foundation/LicenseRegistry/addLicense.html).

## Verified glyph coverage

I parsed the Unicode format-4 `cmap` mappings and font metrics in all three pinned binaries above. Each yielded the same 520 mapped code points. Both selected static faces have:

- All ASCII English uppercase and lowercase letters, and all Hebrew letters U+05D0–U+05EA, including final forms.
- Vowel points U+05B0–U+05BD, rafe U+05BF, shin/sin dots U+05C1/U+05C2, and qamats qatan U+05C7.
- No mapping for U+05C4 or U+05C5 (Hebrew upper/lower dots). Therefore “supports niqqud” must not be read as “contains every character in the Hebrew Unicode block.”
- `GDEF`, `GPOS` and `GSUB` tables, with weight metadata 400 and 500 respectively. Both have units-per-em 1000 and horizontal ascender/descender/line-gap values 957/−334/0.

These are direct observations of the linked binaries, not deductions from the family name. The matching metrics avoid a different line box merely from switching between the two faces. Ordinary vowel-marked pasted text is supported; normalization for answer comparison must remain separate from display. Coverage does not prove perfect positioning of every possible combining-mark sequence.

No explicit `fontFamilyFallback` is needed to switch between English and Hebrew: both are already in the chosen face. For missing symbols or other scripts, Flutter searches platform fallback fonts after the requested family. Unsupported characters can still become boxes if no installed font has them. Leave fallback unspecified initially; add a bundled fallback only if supported input and real-device testing demonstrate a need. Do not promise identical emoji or rare-mark rendering across Android and iOS. [Flutter fallback order](https://api.flutter.dev/flutter/painting/TextStyle/fontFamilyFallback.html).

## Flutter declaration and use

```yaml
flutter:
  assets:
    - assets/fonts/OFL.txt
  fonts:
    - family: FrankRuhlLibre
      fonts:
        - asset: assets/fonts/FrankRuhlLibre-Regular.ttf
          weight: 400
        - asset: assets/fonts/FrankRuhlLibre-Medium.ttf
          weight: 500
```

Use `fontFamily: 'FrankRuhlLibre'` and `FontWeight.w400` or `FontWeight.w500` on the relevant text style. The family string matches the YAML declaration. Flutter uses the declared weight to select the face; the filename alone is insufficient. Do not request italic or 700 for this family when only these faces are bundled. TTF is supported on the target platforms. [Flutter custom-font declaration](https://docs.flutter.dev/cookbook/design/fonts).

Example practiced-word style:

```dart
const TextStyle(
  fontFamily: 'FrankRuhlLibre',
  fontWeight: FontWeight.w500,
  fontSize: 48,
  letterSpacing: 0,
)
```

Keep natural font line height initially instead of forcing a tight `height` or strut. In particular, vowel marks extend above and below the letter body. Do not globally replace the application theme's font.

## Direction and optical fit

Flutter handles bidirectional text within one `Text` paragraph. `textDirection` selects its base direction and disambiguates the relative position of English and Hebrew runs; it does not reverse strings. Keep the application LTR, use explicit RTL for Hebrew prompt/translation fields, and LTR for English fields. Set the typing field's direction from the expected answer language. [Flutter Text.textDirection](https://api.flutter.dev/flutter/widgets/Text/textDirection.html).

For a combined English/Hebrew label, choose a deliberate base direction. Prefer separate text widgets for separate fields. If a single composed sentence must contain an arbitrary embedded opposite-direction value, isolate that value using Unicode LRI/RLI/FSI and PDI as appropriate; keep those display controls out of stored answers. Digits, brackets and punctuation make this relevant even when glyphs render correctly. Do not manually reverse Hebrew strings or pre-reorder runs. [Unicode Bidirectional Algorithm](https://www.unicode.org/reports/tr9/).

The font was designed for Hebrew text with and without vowel marks, but equal numerical font size does not guarantee identical perceived Latin x-height and Hebrew body height. The shared face and baseline metrics are a sound starting point. Default to equal sizes and zero extra tracking; do not invent per-script baseline shifts from metadata. Optical balance, kerning and mark placement still require a rendered check. [Upstream design description](https://github.com/fontef/frankruhllibre).

## Type scale and overflow policy

The following are implementation defaults, not external typographic standards:

| Context | Default size | Weight |
| --- | ---: | --- |
| Main prompt, one term | 48 logical pixels | 500 |
| Main prompt, phrase or several Hebrew translations | 36 logical pixels | 500 |
| Revealed answer in the display treatment | 36 logical pixels | 400 |
| Part of speech, definition, buttons and other UI | Existing system text theme | Existing theme |

Choose the prompt variant from its content role (single term versus phrase/list), never by reducing the user's requested accessibility scale. A long single term may wrap. Let the prompt use the available width and unlimited lines; put the speaker on its own row when width is constrained. The practice content needs vertical scrolling, no fixed-height card, no `maxLines: 1`, no ellipsis, and no `FittedBox` that shrinks text. Primary actions may stay in a bottom safe area only while the remaining content can scroll and the controls themselves wrap/grow.

Ordinary `Text` inherits OS scaling. Preserve it. When using `RichText` or manually measuring through `TextPainter`, pass `MediaQuery.textScalerOf(context)` and the same direction/style as the rendered paragraph. Use `TextScaler.scale(fontSize)` for measurement rather than multiplying by the deprecated `textScaleFactor`; Android can use nonlinear scaling. [Flutter text-scaler migration](https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor).

The practical guarantee comes from reflow and scrolling, not a particular font number. At a linear 2× scale, 48 becomes 96 and 36 becomes 72 logical pixels; Android's nonlinear scaling can produce different values. Verify Android at its maximum font setting and iOS at its largest accessibility setting, including a narrow phone. Flutter explicitly recommends testing the largest settings because text scaling alone does not ensure sufficient layout space. [Flutter large-font guidance](https://docs.flutter.dev/ui/accessibility/ui-design-and-styling), [Android nonlinear scaling guidance](https://docs.flutter.dev/release/breaking-changes/android-14-nonlinear-text-scaling-migration).

## Implementation acceptance checks

The research resolves asset selection, coverage, licence handling, wiring and an explicit scalable layout policy. No Flutter UI or device render was built during this research. Carry these checks into the visual-polish implementation ticket:

1. Load the actual bundled faces in rendering tests; confirm a visible difference between 400 and 500, with no synthetic bold/italic.
2. Render `persistent`, `give up`, `מתמיד`, `שָׁלוֹם`, and mixed `persistent — מתמיד (2)` in both base directions. Check punctuation, vowel placement, baseline and spacing.
3. Try a very long English word, a long phrase, three Hebrew translations and pasted rare marks; verify wrapping, fallback and readable full content.
4. Check default scale, a linear 2× test, maximum Android/iOS settings, landscape and keyboard-open typing. All answers and actions remain reachable without overflow or clipping.
5. Confirm the installed app works offline with these assets and exposes the complete font licence in Settings.
