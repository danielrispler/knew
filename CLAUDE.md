# knew

Flutter vocabulary trainer for Hebrew speakers learning English.

## Before changing product behavior

Read `CONTEXT.md` and the ADRs relevant to the area. Use the glossary's terms
in code, tests, issues, and user-facing explanations. Domain-document routing
and ADR conflict handling: `docs/agents/domain.md`.

## Implementation

- Keep the established feature layout: `domain`, `data`, and `presentation`.
- Put user-facing strings in `lib/src/core/l10n/app_en.arb` and
  `app_he.arb`; regenerate localizations with `flutter gen-l10n`.
- Format changed Dart files with `dart format`, then run the smallest relevant
  test plus `flutter analyze` before handing off.

## GitHub issues

Issues live in `danielrispler/knew` and are managed with `gh`. Issue workflow:
`docs/agents/issue-tracker.md`. Triage-label mapping:
`docs/agents/triage-labels.md`.
