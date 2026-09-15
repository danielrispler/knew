# Visual design: plain notebook

Accepted 2026-09-15 for [#11](https://github.com/danielrispler/knew/issues/11), within [map #2](https://github.com/danielrispler/knew/issues/2).

The user inspected the preview and selected **A: plain notebook page**. The practiced term sits directly on the page background, with English aligned left and Hebrew aligned right. Surrounding screens use quiet lists and whitespace. This records the chosen direction; the Flutter role mapping below makes that choice implementable.

Primary source: [local practice prototype](../prototypes/practice.html), variant `?variant=A`. The file is currently local and uncommitted; there is no hosted link or prototype branch. No branch or commit was authorized. Preserve this source when the user authorizes publishing; the decision does not depend on pretending it is already hosted.

## Layout and interaction

- Practice: compact header with Done, thin progress rule, question count and English Listen control, then the term. Use 24 logical pixels of horizontal page padding and about 32 above the content; leave about 42 before the main term. Spacing can reflow on constrained screens.
- Single term: Frank Ruhl Libre Medium 500 at 48 logical pixels. Phrase/list prompt: Medium 500 at 36. Revealed translation: Regular 400 at 36. Zero added tracking; keep natural font metrics in Flutter (the HTML uses line-height 1.3 as an approximation). Fonts, licence and coverage are settled in [typography research](../research/typography.md).
- Front: term or Hebrew prompt, part of speech, question instruction and Show answer. Reveal retains the prompt and adds the translation and definition below a light rule; production reveals all meanings required by the practice specification.
- Reveal motion: one user-triggered 300ms ease-out transition, a shallow Y-axis turn from −14° to 0° and opacity 0.45 to 1. It is a restrained reveal, not a full 180° spinning card. No idle animation.
- Bottom actions: Show answer is filled accent. After reveal, Didn't know is the neutral outlined action on the left; Knew it is the filled accent action on the right. Use equal widths, a 12-pixel gap and a minimum 52-pixel height. At large text sizes stack them in the same reading order, with Knew it below.
- Multiple choice: four full-width outlined rows, 10-pixel gaps, wrapping text with direction set per answer. Feedback includes Correct/Incorrect text plus check/cross and a colored outline; color alone never conveys the outcome. Reveal the answer, then show Next as the bottom filled action. The prototype intentionally mixes scripts to test alignment; real options follow the expected answer language.
- Home: a small heading and due count, three plain stage-count rows with small colored dots, and a Words link. Bottom actions are Practice with its due count, followed by the quieter Add word. Keep the stage counts in the system font.
- Listen appears beside English text and speaks English only. The browser voice in the preview is illustrative; the app uses its specified native text-to-speech integration.

## Material 3 color mapping

Use `ThemeData(useMaterial3: true)` with an explicit light/dark brightness. Begin with `ColorScheme.fromSeed` using the accent, then override the roles below so generated colors do not replace the agreed palette. Set scaffold and app-bar backgrounds explicitly; use transparent surface tint on flat surfaces. Remaining component roles can use the seeded scheme until a screen needs an explicit treatment. This is a project mapping of Flutter's [color roles](https://api.flutter.dev/flutter/material/ColorScheme-class.html), not a claim that the original brief supplied every Material token.

| Use / Flutter role | Light | Dark |
| --- | --- | --- |
| Page / `ThemeData.scaffoldBackgroundColor`, app-bar background | `#F6F7F9` | `#11151C` |
| Controls and sheets / `ColorScheme.surface`, `surfaceContainerLow`, `surfaceContainer` | `#FFFFFF` | `#1A202B` |
| Main text / `onSurface` | `#1C2230` | `#E6E9EF` |
| Muted text / `onSurfaceVariant` | `#667085` | `#98A2B3` |
| Main action / `primary` | `#2F5D9E` | `#8DB0E6` |
| Main action text / `onPrimary` | `#FFFFFF` | `#11151C` |
| Quiet divider / `outlineVariant` | `#D9DEE7` | `#333C4B` |
| Strong control/focus outline / `outline` | `#667085` | `#98A2B3` |

Use the stronger outline when a border is needed to identify an interactive control; the preview's quiet separator color is not evidence that every thin control boundary passes non-text contrast requirements. Filled primary actions take `onPrimary`; neutral actions take `onSurface`. Do not use deprecated `ColorScheme.background` to represent the page: [scaffoldBackgroundColor](https://api.flutter.dev/flutter/material/ThemeData/scaffoldBackgroundColor.html) handles it directly.

Stage tokens remain separate from `primary`, `secondary` and `tertiary`: New `#98A2B3`, Familiar `#D39B2E`, Learned `#3F9A6B`, in both themes. Use them only on small stage indicators, always beside a readable stage label/count. They are not body-text colors or dashboard-sized fills. Correct/incorrect feedback uses semantic success/error styling, independently of an entry's stage; the prototype's green success outline happens to share the Learned hex. Keep feedback labels in normal text color.

## TextTheme mapping

Keep the platform family for the ordinary [Material TextTheme](https://api.flutter.dev/flutter/material/TextTheme-class.html). Apply `onSurface` to normal text and `onSurfaceVariant` explicitly to muted labels; do not install Frank Ruhl Libre as the theme-wide family.

| Context | Flutter starting role and override |
| --- | --- |
| Main practiced term | Local copy of `displayMedium`: Frank Ruhl Libre, 48, w500, zero tracking |
| Phrase/list prompt | Same local display style, 36, w500 |
| Revealed translation | Local copy of `displaySmall`: Frank Ruhl Libre, 36, w400 |
| Home heading | `headlineSmall`: system family, 24, w500 |
| Main content, stage rows, definitions | `bodyLarge`: system family, 16 |
| Part of speech, progress count, muted labels | `bodyMedium`: system family, 14 |
| Main action labels | Local copy of `labelLarge`: system family, 16, zero tracking |

## Accessibility and validation

Preserve inherited OS text scaling, including nonlinear Android scaling. Allow unlimited prompt lines, vertical scrolling and flexible controls; no ellipsis, fixed-height practice card or shrinking text to fit. Move Listen to its own row when needed. A bottom action area must let the remaining content scroll and must itself grow or join the scrollable content if space is insufficient. See [typography research](../research/typography.md) for the concrete maximum-scale checks.

When the OS requests reduced motion, reveal immediately without the turn or opacity animation. Preserve the same information, feedback and focus order. Controls remain keyboard/screen-reader reachable, with at least a 48-pixel touch target in the app.

Computed sRGB muted-text contrast: light text on page **4.64:1**, light text on white surface **4.97:1**, dark text on page **7.10:1**, dark text on surface **6.34:1**. All exceed 4.5:1 for normal text. This checks those four pairs only; verify other component states during implementation.

Validated so far: embedded font binaries, JavaScript syntax, one headless Chrome render of the preview, and the user's selection of A. The preview offers default/200% text, short/long/phrase/Hebrew samples, both themes, reduced motion, flashcard and multiple-choice controls. It does not prove Flutter glyph positioning, nonlinear scaling, platform semantics, native speech, haptics or all interaction states on Android/iOS. Carry the rendering and accessibility acceptance checks from the research into implementation; no additional taste decision is outstanding.
