# Reading: Claude-suggested Chapter Words

Design, 2026-11-21. Status: approved by the owner and built.

## Intent

The owner is reading the Harry Potter books in English and wants to learn each
chapter's hard words before reading it, capture the ones met while reading, and
keep practicing them afterwards. Gemini's free quota often drops the app to its
weakest model, so the owner wants Claude, which they already pay for, to do this
new job.

## Goals

- The owner sets a **Reading** (book and chapter) and gets about 10 hard words
  for that chapter, suggested by Claude.
- Each word can be marked Learn, Known, or Skip, as on Discover.
- Words added from the Reading screen carry the book and chapter as their
  Entry `source`.
- A Claude API key is stored and tested in Settings, next to the Gemini key.

## Non-goals

- Replacing Gemini. Lookup, Enrichment, sentence feedback, and Discover stay on
  Gemini. Moving them to Claude is a possible later step.
- Books other than the seven Harry Potter novels.
- Tracking reading position automatically. The owner changes the chapter by hand.
- Any change to Levels, Due dates, or Practice sessions.
- A model picker for Claude.
- Exporting the chapter cache in backups.

## Anti-goals

- Spoilers. Claude returns words and glosses, never plot.
- Book text. No quotes or sentences from the books are requested, stored, or shown.
- Paying twice for a chapter. A fetched chapter is cached and never refetched
  unless the owner asks for more words.
- A Claude outage breaking anything outside the Reading screen.

## Constraints

- Feature layout stays `domain` / `data` / `presentation`, in a new
  `lib/src/features/reading/`.
- User-facing strings go in `app_en.arb` and `app_he.arb`.
- Dart has no official Anthropic SDK. The client uses the `http` package against
  `POST https://api.anthropic.com/v1/messages`, as `GeminiClient` does for Gemini.
- ADR 0003 says Discover never blocks on AI. Reading is a separate screen and
  does wait for Claude on a chapter's first load. This does not contradict the
  ADR but is a deliberate difference, to be recorded in a new ADR.
- Chapter accuracy comes from the model's memory of the books. A suggested word
  may belong to a nearby chapter. The feature accepts this.

## Approaches

| | What changes | Trade-off |
|---|---|---|
| **A. Claude for Chapter Words only** (chosen) | New Claude key and the Reading feature. Gemini untouched. | Smallest and safest. Gemini's weak-model answers are not fixed yet. |
| B. Claude replaces Gemini everywhere | Every AI job moves to Claude; Gemini removed. | Best answers, one key. Largest rewrite, every lookup costs money, no free backup. |
| C. Claude first, Gemini as backup | Both stay; the app prefers Claude. | Best availability. Two providers to maintain for a personal app. |

The owner chose A. It is the first half of B, so nothing is wasted if B follows.

## Design

### Glossary additions (`CONTEXT.md`)

- **Reading**: The book and chapter the learner is currently on.
- **Chapter Word**: A word Claude suggests for a Reading. It is not an Entry
  until the learner chooses to learn it. _Avoid_: "Suggested Word", which
  belongs to Discover.

### The screen

Opened from an app-bar icon on the library screen, next to Discover
(`vocabulary_list_screen.dart:216`).

```
Reading                                   
Harry Potter 1 · Philosopher's Stone   [v]
Chapter 5 of 17                     [-] [+]

  vault
  [Reveal meaning] [Known] [Skip] [Learn]

  dodge
  כספת; a locked room for valuables        <- after reveal
  [Known] [Skip] [Learn]
  ...
[More words]        [Add a word from this chapter]
```

- The book picker lists the seven novels. The chapter stepper is bounded by the
  book's chapter count.
- Cards reuse Discover's pattern: term first, meaning hidden until revealed.
- **Learn** opens `EntryFormScreen` with the term and the source prefilled, for
  example `Harry Potter 1 · ch. 5`. The Gemini lookup runs as it does today.
  Tapping Learn writes nothing. The Chapter Word becomes `learned` only when the
  form saves an Entry with the same key, as Discover's `markLearnedIfSaved`
  does. Backing out leaves it `suggested`.
- **Known** hides the word and adds it to the shared Known list, so Discover
  stops suggesting it too. A word Known anywhere, in Discover or in another
  chapter, is filtered out of every chapter's list.
- **Skip** hides the word for this chapter only. No resurfacing timer. It stays
  in the chapter's "already suggested" list, so "More words" never brings it
  back. The same word may still appear for a different chapter.
- **More words** fetches another set for the same chapter.
- **Add a word from this chapter** opens quick capture with the same source.
  Quick capture elsewhere in the app is unchanged.
- Passing the source needs two small additions to shared vocabulary code: an
  optional initial source on `EntryFormScreen`, and an optional source on quick
  capture and `PendingEntryController.capture`. The Pending Entry carries the
  source from the start. The queue already preserves it, because a finished
  lookup only replaces meanings and status
  (`pending_entry_controller.dart:62-66`).
- States: no Claude key (message pointing to Settings), loading, error with
  retry, and an empty list after everything is acted on.
- Changing the chapter never calls Claude by itself. A chapter with no cached
  words shows a "Get words for this chapter" button, so stepping through
  chapters costs nothing. Decided during the build.

### Before, during, after

- Before: the Chapter Word list.
- During: "Add a word from this chapter".
- After: the existing Scheduled practice. No new mechanism.

### Claude request

- Model `claude-opus-5-5`, `output_config.effort: "low"`, structured JSON output.
  One request per chapter load or "More words". If the API rejects this model
  or setting at build time, use `claude-sonnet-5-5` and tell the owner.
- Input: book title (both titles for book 1), chapter number, terms already
  suggested for this chapter, and for calibration up to 30 recent Known terms
  ("too easy") and up to 30 recent learned terms ("right level"). Calibration
  comes from `chapter_words` rows with status `known` or `learned`, newest
  first, across all books and chapters. Skipped words are not used.
- Output: 12 items of `term`, `hebrew`, `definition`. The gloss matches the sense
  used in the book. Definitions follow the lookup rule of simple English, at
  most 15 words.
- The app drops items already in the library, already Known, or already
  suggested for the chapter, and shows every item that remains. Nothing paid
  for is discarded, and there is no hidden queue.
- The system prompt forbids plot details and quoted text, and limits terms to
  ordinary English words or short phrases. Invented wizarding words and names
  are excluded.
- Errors cover the same cases as Gemini's: missing key, rejected key, limit or
  credit reached, network, timeout, unusable or refused answer. They use a
  separate Claude error type and their own copy, because the Gemini type's
  messages name Gemini and Google AI Studio.
- The request shape, refusal handling, and fallback setting follow the
  `claude-api` skill and live Anthropic docs at build time.

### Storage

- Claude key: a second slot in `SecureStorageRepository`
  (`claude_api_key`). Not included in exports, as with the Gemini key.
- Reading position: two rows in the `settings` table (book, chapter).
- New table `chapter_words`, schema version 4, added by a non-destructive
  migration: book, chapter, `english_key`, term, hebrew, definition, status
  (`suggested`, `learned`, `known`, `skipped`), revealed flag, timestamps.
  Unique on book + chapter + `english_key`.
- Known also writes a `known` row to `suggested_words` with no frequency rank.
  That keeps one Known list, leaves the Discovery Band untouched
  (`known()` adjusts the band only when a rank exists), and is already covered
  by backup export. The existing `_setStatus` only updates a row that exists
  (`suggested_words_repository.dart:443`), so this needs one new method on
  `SuggestedWordsRepository` that inserts the row or updates it. Discover's
  behavior does not change; its repository gains that one method.
- A Chapter Word whose key is later found in the library is shown as learned.

### Settings

A Claude section under the Gemini one: key field, save, and a test button that
makes one free call to `GET /v1/models`.

### Documents

- New ADR 0005: Claude is used alongside Gemini, for Chapter Words only, and
  the Reading screen may wait on AI.
- `CONTEXT.md` gets the two glossary terms above.

## Calls made by the designer, not the owner

- Reading is its own screen and table, not part of Discover's batch.
- Opus 5.5 at low effort, fixed. The owner said Opus on low or Sonnet are both fine.
- 12 words requested per fetch, and all that survive filtering are shown.
- Learn marks a Chapter Word learned only after the Entry is saved.
- Skip is permanent for that chapter.
- Book 7's epilogue is offered as a final step after chapter 36.
- The same reveal-then-decide card as Discover.
- Only words added from the Reading screen get the book source.
- Book labels use the number and the UK title.
- Reading position and the chapter cache are not exported.

## Left to the builder

- Widget structure, provider wiring, and whether Discover's card is extracted
  for reuse.
- Exact prompt wording and JSON schema.
- Timeout value. Start at 60 seconds.
- Exact error copy in both languages.
- Chapter counts per book, to be verified before hardcoding. From memory:
  17, 18, 22, 37, 38, 30, 36 plus an epilogue.
- Tests: unit tests for the client's parsing and error mapping with a fake
  `http.Client`, for the filtering rules, and for the migration; a widget test
  for the screen states.

## Cost

Unverified estimate: under $0.10 per chapter load, so the whole series, about
200 chapters, costs under $20.
