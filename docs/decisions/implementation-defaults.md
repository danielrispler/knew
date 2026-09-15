# Remaining implementation defaults

These reversible choices complete the nonvisual gaps in [Map: knew build-ready plan](https://github.com/danielrispler/knew/issues/2), using its instruction to choose the simplest reasonable behavior. They are inputs to Assemble the build-ready plan, not implementation work.

## Lookup and pronunciation

Adopt the current model, responseJsonSchema configuration, parser, and specific error messages in [Gemini research](../research/gemini-api.md). Keep one 15-second request deadline, manual retry, and the editable model setting. Settings Test key performs a small real lookup through the same request/parser path and reports configuration errors; it consumes quota. Public documentation cannot determine this owner's quota or prove that their key works.

Hebrew lookup alternatives name different English terms; selecting another alternative triggers a fresh English lookup so its meanings actually describe it. Keep the current draft until that succeeds, and permit manual editing if it fails. Discard stale responses after the input changes or the user leaves. Confirm before replacing any manually edited lookup fields. Never send Source or Context to Gemini. Changes to the selected English term use the ordinary duplicate check before save.

Use the installed en-US voice selection and unavailable-state recipe in [RTL/accessibility research](../research/rtl-accessibility.md). Keep practice usable when speech fails; a missing voice never blocks a review. No other speech API is added. The user's acceptance of online-only operation does not require adding network synthesis; the existing local voice policy suffices.

## Verification scope

Keep the four original pure-Dart suites: scheduler, answer checker, queue/question selection, and Gemini parsing. Add focused HTTP fake-transport tests for error classification and timeout; no real key in automated tests. Add repository integration tests using real SQLite for uniqueness, import rollback, round trips, and migrations. Add practice-controller tests for per-answer persistence, correcting a grade, repeats, and extra-practice non-mutation.

Use widget tests for RTL direction, hidden flashcard-answer semantics, reduced motion, large text, keyboard-safe actions, and error states that preserve drafts. Include Flutter's built-in accessibility guideline checks. No golden-image suite in v1: it would create image-maintenance work before a stable UI exists. Do a manual phone pass with actual bundled fonts, Hebrew keyboard, TalkBack, maximum text size, and TTS availability. iOS must build and receives equivalent keyboard/VoiceOver checks where a device is available; an unavailable device is a recorded validation gap, never a claimed pass.

## Proposed build slices

The later spec/ticket step should use these independently demonstrable vertical slices, with native blocker links:

1. Local vocabulary: Flutter shell, real SQLite, settings defaults, manual add/details, duplicate handling, and persistence across restart.
2. Assisted add: secure key/model settings, Gemini lookup, editable review, alternatives, manual fallback, and duplicate link.
3. Scheduled flashcard practice: scheduler, due queue, per-answer persistence/correction, repeats, extra practice, and summary.
4. Varied practice: random eligible formats/directions, unique multiple-choice distractors, typing normalization/typos, and pronunciation.
5. Library and backup: search/filter/sort, edit/delete/reset, theme/session settings, versioned export/import.
6. Visual acceptance and delivery: agreed typography/layout, both themes, accessibility/RTL cases, platform configuration, setup README, clean analysis/tests, release build, and real Android usage.

Slice 1 blocks 2, 3, and 5; 3 blocks 4; 2, 4, and 5 block 6. Each slice must carry its own relevant tests and accessible baseline; the last slice is verification/polish, not permission to defer correctness. The final tickets must embed concrete acceptance criteria and link the authoritative decision comments.

## Visual decision

The user selected A, the plain notebook page, in [Prototype: practice card and home screen](https://github.com/danielrispler/knew/issues/11). [Visual design](visual-design.md) records the accepted layout, type scale, motion, and palette mappings. Its HTML preview is a discussion artifact, not proof of Flutter/device behavior. No product decision remains open before spec assembly.
