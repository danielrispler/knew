# Flutter RTL, accessibility, and offline pronunciation

Research for [#6](https://github.com/danielrispler/knew/issues/6), based on [the original brief](https://github.com/danielrispler/knew/issues/1). Checked 2026-09-15 against primary documentation and plugin source; `hintLocales`, `textScalerOf`, and `disableAnimationsOf` also exist in the locally installed Flutter SDK. Recipes below are implementation recommendations, not executed app tests. No application exists yet.

## Recommended decisions

- Keep the English app shell LTR. Set Hebrew content direction explicitly, at the smallest useful boundary.
- Keep list controls in consistent columns; direction applies to text, not the entire list row.
- Disable the three custom motion effects when the OS requests reduced motion, while preserving their information immediately.
- Respect the platform text scaler without a global or content-specific upper clamp. Use wrapping, growing controls, and scrolling.
- Pronounce only the English term with an installed en-US voice. If unavailable, provide recovery guidance and let practice continue silently. Do not silently substitute the system language or an online voice.

## 1. Individual strings and the app shell

`Text.textDirection` inherits ambient `Directionality` when omitted. It does not select a new paragraph base direction by detecting Hebrew. Unicode still orders Hebrew character runs; a pure word may look fine while mixed punctuation or numbers reveal the wrong paragraph direction. `textAlign` controls alignment, not character ordering; `start` resolves through the selected text direction. [Text API](https://api.flutter.dev/flutter/widgets/Text/textDirection.html)

Use an English `MaterialApp` locale for the app shell. Set both direction and alignment on Hebrew text:

```dart
Text(
  hebrew,
  textDirection: TextDirection.rtl,
  textAlign: TextAlign.start,
)
```

For a whole Hebrew-only content subtree, use the following instead of repeating properties:

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: hebrewContent,
)
```

Keep the subtree narrow: `Directionality` also changes how directional padding and direction-sensitive layout resolve. Wrapping the whole screen would change more than its text. [Directionality API](https://api.flutter.dev/flutter/widgets/Directionality-class.html)

## 2. Mixed lists

Recommended visual policy: retain LTR row geometry and the same trailing control position for every row. English starts at the left of a shared text column; Hebrew starts at its right. Give both the same available width. Do not mirror the icons per item. For word entries, English title and Hebrew subtitle can occupy separate lines in that column.

```dart
Row(
  children: [
    Expanded(
      child: Text(
        label,
        textDirection: isHebrew ? TextDirection.rtl : TextDirection.ltr,
        textAlign: TextAlign.start,
      ),
    ),
    IconButton(
      tooltip: 'Open word',
      onPressed: openWord,
      icon: const Icon(Icons.chevron_right),
    ),
  ],
)
```

Here the row inherits the LTR shell; only its text changes direction. This is a product layout choice built on Flutter's [text-direction contract](https://api.flutter.dev/flutter/widgets/Text/textDirection.html), rather than an automatic list behavior. Multiple-choice questions already have a known expected answer language; use it consistently for every option.

## 3. Expected-answer typing field

```dart
final answerDirection = expectsHebrew ? TextDirection.rtl : TextDirection.ltr;

TextField(
  textDirection: answerDirection,
  textAlign: TextAlign.start,
  keyboardType: TextInputType.text,
  hintLocales: [expectsHebrew ? const Locale('he') : const Locale('en', 'US')],
  autocorrect: false,
  enableSuggestions: false,
  textCapitalization: TextCapitalization.none,
  decoration: InputDecoration(
    labelText: expectsHebrew ? 'Answer in Hebrew' : 'Answer in English',
    hintText: expectsHebrew ? 'הקלד תשובה' : 'Type an answer',
    hintTextDirection: answerDirection,
  ),
)
```

The editable paragraph gets the expected direction; `start` puts an empty Hebrew field's insertion area at the right. Keep English labels in the LTR decoration context; specify hint direction independently. Do not reverse the controller string, insert direction controls into editable values, or reposition selection on every change. Let Flutter manage visual caret/selection geometry and the IME's composing range. Mixed-direction selections can have endpoints meeting in the middle; the renderer even documents an unresolved boundary case, so correct properties are not proof that every platform interaction is bug-free. [TextField direction](https://api.flutter.dev/flutter/material/TextField/textDirection.html), [hint direction](https://api.flutter.dev/flutter/material/InputDecoration/hintTextDirection.html), [selection endpoints](https://api.flutter.dev/flutter/rendering/RenderEditable/getEndpointsForSelection.html)

`TextInputType.text` requests the normal textual keyboard, not a Hebrew-specific keyboard. `hintLocales` is an advisory language preference supported only on Android API 24+; it cannot ensure Hebrew is installed or selected and is not honored on iOS. The user must be able to switch keyboards themselves. Disabling suggestions/autocorrection is the proposed practice policy, to reduce answer assistance. [Keyboard type](https://api.flutter.dev/flutter/services/TextInputType/text-constant.html), [hintLocales](https://api.flutter.dev/flutter/material/TextField/hintLocales.html)

## 4. Bidi isolation in English sentences

Prefer separate text blocks for translation content. When interpolation into an English sentence is necessary, isolate the inserted value so its directional characters do not alter surrounding punctuation or adjacent values. Use FSI U+2068 and PDI U+2069 for unknown-language values; RLI U+2067 also works when the fragment is known RTL. Plain `TextSpan` styling is not a separate paragraph direction boundary. Unicode defines isolation and the behavior of these controls. [Unicode Bidirectional Algorithm, explicit directional isolates](https://www.unicode.org/reports/tr9/#Explicit_Directional_Isolates)

```dart
Text(
  'Translation: \u2068$hebrew\u2069.',
  textDirection: TextDirection.ltr,
)
```

Those escapes belong only in the presentation string, never the saved translation, duplicate key, answer checker input, or export. For Hebrew containing digits, Latin abbreviations, parentheses, or final punctuation, preserve the logical text and let the Unicode algorithm render runs; never reverse characters manually. [Unicode Bidirectional Algorithm](https://www.unicode.org/reports/tr9/)

## 5. Reduced motion

Read `MediaQuery.disableAnimationsOf(context)` in widgets so an OS preference change rebuilds the relevant widget. Its underlying `AccessibilityFeatures.disableAnimations` means the platform requests disabled or simplified animation. Avoid polling the low-level platform dispatcher or caching the preference at startup. [MediaQuery API](https://api.flutter.dev/flutter/widgets/MediaQuery/disableAnimationsOf.html), [AccessibilityFeatures API](https://api.flutter.dev/flutter/dart-ui/AccessibilityFeatures/disableAnimations.html)

```dart
final reduceMotion = MediaQuery.disableAnimationsOf(context);
final duration = reduceMotion ? Duration.zero : const Duration(milliseconds: 180);
```

Apply that duration to custom transitions, or branch directly to the final state for a card transform. The information must appear even when no animation completion callback occurs.

| Effect | Reduced-motion behavior |
| --- | --- |
| Card flip | Replace front with answer immediately; no rotation, slide, or fade. |
| Answer feedback | Immediately show result text and icon plus static color; no shake, bounce, or animated fill. |
| Summary stage changes | Immediately render old/new stage text and final indicator; no count-up or travel effect. |

These are proposed product policies. Reduced motion does not itself specify a haptic preference; do not infer one from this flag. Result information must remain understandable without color, sound, motion, or haptics.

## 6. Large text

Use Flutter's inherited scaler for ordinary `Text` widgets. When measuring text, use `MediaQuery.textScalerOf(context).scale(fontSize)`; when creating `RichText` directly, pass that scaler. `textScaleFactor` was deprecated because a single multiplier cannot represent Android's nonlinear scaling. Avoid manually scaling a font size and then letting `Text` scale it again. [Migration guide](https://docs.flutter.dev/release/breaking-changes/deprecate-textscalefactor), [textScalerOf](https://api.flutter.dev/flutter/widgets/MediaQuery/textScalerOf.html)

```dart
RichText(
  textScaler: MediaQuery.textScalerOf(context),
  textDirection: TextDirection.ltr,
  text: TextSpan(text: definition, style: Theme.of(context).textTheme.bodyLarge),
)
```

**Clamping policy: none for v1.** A small app can reflow instead of overriding a user's font preference. `MediaQuery.withClampedTextScaling` exists, but using it is a product restriction, not a requirement of Flutter. No essential practiced word, answer, or action should shrink to fit or be ellipsized to conceal an overflow. [Clamping API](https://api.flutter.dev/flutter/widgets/MediaQuery/withClampedTextScaling.html)

| At-risk area | Layout policy |
| --- | --- |
| Large practiced word / revealed meanings | Natural text height, wrapping, scrollable practice content; no fixed-height flashcard. |
| Multiple-choice buttons | Full-width growing buttons in a vertical list; multiline labels; no four-option grid or fixed text height. |
| Home stage counts | Wrap or stack the three labeled counts when space is insufficient. |
| Bottom actions and typing field | Preserve safe area and keyboard insets; allow scrolling to focused input and wrap/stack action labels. |

## 7. Offline TTS follow-up to package research #4

[Package research #4](https://github.com/danielrispler/knew/issues/4#issuecomment-5634237557) establishes plugin support and configuration, but does **not** specify a voice fallback or establish offline availability. A working plugin and successful `setLanguage('en-US')` do not prove a usable offline en-US voice exists.

Android voices explicitly distinguish network-required synthesis. The plugin exposes `network_required` as the **string** `'0'` or `'1'`, and exposes tab-separated `features`; exclude voices marked `notInstalled`. `setLanguage` checks general language availability, while `setVoice` selects a name/locale pair. Select the verified offline voice explicitly. [Android Voice API](https://developer.android.com/reference/android/speech/tts/Voice), [plugin Android source](https://raw.githubusercontent.com/dlutton/flutter_tts/master/android/src/main/kotlin/com/eyedeadevelopment/fluttertts/FlutterTtsPlugin.kt)

On iOS the plugin enumerates OS speech voices and accepts an identifier, or name plus locale. Its map does not expose Android's network/install flags. A failed language/voice selection returns `0`; iOS retains its previous configuration on a failed selection, so unconditionally calling `speak` afterwards can use the wrong language. [Plugin iOS source](https://raw.githubusercontent.com/dlutton/flutter_tts/master/ios/Classes/SwiftFlutterTtsPlugin.swift)

Recommended sequence: enumerate available voices, select installed en-US, check selection success, then speak only `english`. If no suitable voice exists, show “English pronunciation unavailable. Install an English (US) voice in your device's speech settings.” Keep all study actions available. Catch initialization, selection, and synthesis failures; bound initialization waits and allow a retry after returning from settings. Refresh voice availability rather than permanently remembering a missing voice.

Do not silently fall back to another English accent: that relaxes the original en-US requirement and needs a deliberate product decision. Never fall back to the default system language, Hebrew, network synthesis, or an extra speech service. Offline speech requires a provisioned OS voice; it is not bundled by `flutter_tts`. iOS offline readiness still requires airplane-mode device validation because the plugin offers no Android-equivalent offline metadata. This report does not claim such device validation has run.

## Verification to include in implementation tickets

1. Widget tests under an LTR shell: Hebrew text properties, English/Hebrew option rows sharing icon positions, expected-answer direction and hint direction. Include `שלום (test) 123!`, Hebrew-only phrases, niqqud, parentheses, and long translations. Verify display isolation does not change saved/compared data.
2. Reduced-motion widget test: inject `MediaQueryData(disableAnimations: true)`, tap each action, and assert the final content appears immediately without depending on elapsed animation or completion callbacks.
3. Small-viewport large-text tests at normal, 2x, and 3x linear scales; assert no overflow and all actions remain reachable. Test real Android nonlinear scaling and iOS largest accessibility text setting separately; linear widget tests do not reproduce those OS behaviors.
4. Run Flutter accessibility guidelines for target size, labels, and contrast. Inspect with TalkBack and VoiceOver: English controls stay readable, Hebrew content is available, speaker buttons have labels, and the hidden flashcard answer is absent from semantics until revealed. [Flutter accessibility testing](https://docs.flutter.dev/ui/accessibility/accessibility-testing)
5. Real Android/iOS typing checks: switch between Hebrew and English keyboards; empty-field caret, long-press selection handles, mixed-script selection, punctuation, copy/paste, composition, and keyboard-obscured bottom actions. Avoid claiming framework APIs guarantee every IME's behavior.
6. TTS selection unit tests: offline en-US, network-only en-US, missing voice data, another-English-only, Hebrew-default, failed selection, and plugin failure. Device checks: airplane mode with a provisioned voice, no voice data, and return from voice installation. Confirm only the English term is ever passed to speech.

The research question is resolved by these recipes and policies. Visual, IME, screen-reader, and offline-device checks are implementation acceptance work, not evidence already obtained.
