# *knew* Build-Ready Plan

Source of truth: Original brief ([#1](https://github.com/danielrispler/knew/issues/1)) synthesized with resolved research ([#3](https://github.com/danielrispler/knew/issues/3)–[#6](https://github.com/danielrispler/knew/issues/6)) and decisions ([#7](https://github.com/danielrispler/knew/issues/7)–[#13](https://github.com/danielrispler/knew/issues/13)).

---

## 1. Product Overview & Core Requirements

*knew* is a personal, single-user mobile vocabulary trainer designed for a native Hebrew speaker learning English. The English term is always the target concept being learned.

### Key Guiding Principles
- **Quiet, calm notebook feel**: Uses a plain notebook page design without boxy card borders (Variant A accepted in [#11](https://github.com/danielrispler/knew/issues/11)).
- **Quick one-handed practice**: High-frequency thumb actions (Show answer, Didn't know, Knew it) placed within reach at the bottom of the screen.
- **Single-device local storage**: SQLite database stored locally on device ([ADR 0001](../adr/0001-local-storage.md)). No cloud sync, accounts, or remote auth required.
- **Assisted lookup via Gemini**: Auto-populates parts of speech, Hebrew translations, and simple English definitions using Gemini API (`gemini-2.5-flash`).
- **Mixed-script typography**: Distinct layout rules combining large Frank Ruhl Libre serif type for English terms and clean, aligned Hebrew rendering.

---

## 2. System Architecture & Technical Baseline

### Platform & Framework
- **Framework**: Flutter (Material 3 enabled, `useMaterial3: true`).
- **State Management**: `flutter_riverpod` (manual state providers, no code generation).
- **Target OS**: Android-primary, iOS-compatible. LTR root shell with explicit `TextDirection.rtl` for Hebrew content.

### Database & Persistence
- **Engine**: `sqflite` (SQLite on device).
- **Tables**:
  - `words`: `id` (UUID PK), `english` (trimmed text), `english_key` (lowercased unique constraint), `meanings` (JSON text array), `source` (nullable text), `context` (nullable text), `level` (INTEGER 0–6), `due_date` (TEXT YYYY-MM-DD), `last_reviewed_at` (ISO 8601 UTC string), `times_correct`, `times_wrong`, `created_at`, `updated_at`.
  - `settings`: `name` (PK), `value` (JSON text).
- **Secure Storage**: `flutter_secure_storage` for storing the Gemini API key securely.

### Gemini API Integration
- **Model**: `gemini-2.5-flash` via standard HTTP REST API `generateContent`.
- **Response Format**: `responseJsonSchema` returning structured JSON containing 1–3 meanings with partOfSpeech, Hebrew translations (1–4 per meaning), and a simple definition (max 15 words).
- **Timeout & Error Policy**: 15-second request deadline. Explicit error handling for missing key, quota exhaustion (HTTP 429), network timeout, and invalid JSON format. Manual retry enabled on lookup screen.

### Spaced Repetition & Lifecycle
- **Levels & Intervals**:
  - Level 0: Unreviewed (New)
  - Level 1: 1 day interval
  - Level 2: 2 days interval
  - Level 3: 4 days interval (Familiar)
  - Level 4: 7 days interval
  - Level 5: 14 days interval (Learned)
  - Level 6: 30 days interval
- **Grading Rules**: Correct increases level by +1 (max 6). Incorrect decreases level by -1 (min 1, scheduled for tomorrow).
- **Session Lifecycle**: Session queue exists purely in memory. First-pass reviews persist instantly to SQLite upon grading. Incorrect typing answers offer a single-tap "Count as correct" override before proceeding to Next. Failed first-pass items receive exactly 1 repeat at session end (repeats do not write progress).

### Typography & Visual Design (Variant A)
- **Serif Font**: Frank Ruhl Libre (Medium 500 & Regular 400 static assets).
- **Type Scale**:
  - Main practiced term: Frank Ruhl Libre Medium 500 @ 48 logical px.
  - Multi-word / list prompt: Medium 500 @ 36 logical px.
  - Revealed translation: Regular 400 @ 36 logical px.
  - System UI / Headings / Buttons: Platform default system font.
- **Palette**:
  - Light mode: Page `#F6F7F9`, Surface `#FFFFFF`, Main text `#1C2230`, Muted `#667085`, Primary action `#2F5D9E`.
  - Dark mode: Page `#11151C`, Surface `#1A202B`, Main text `#E6E9EF`, Muted `#98A2B3`, Primary action `#8DB0E6`.
  - Stage Colors: New `#98A2B3`, Familiar `#D39B2E`, Learned `#3F9A6B`.

---

## 3. Build Slices & Implementation Sequence

The implementation is broken down into 6 independent vertical slices:

### Slice 1: Local Vocabulary Store & Settings Baseline
- **Focus**: Core SQLite database, settings management, manual word creation/editing/deletion, duplicate detection, and restart persistence.
- **Deliverables**: Database helper, `WordsRepository`, `SettingsRepository`, Manual Add/Edit forms, Vocabulary list view.

### Slice 2: Gemini-Assisted Lookup
- **Focus**: Secure API key storage, Gemini API client, JSON Schema parsing, assisted word entry screen, manual review/edit of fetched meanings, duplicate handling.
- **Deliverables**: `GeminiClient`, `SecureStorage`, Assisted Entry UI with auto-populated fields, fallback to manual entry on network failure.

### Slice 3: Scheduled Practice & Session Lifecycle
- **Focus**: Spaced repetition scheduler, due queue selection algorithm, in-memory practice session state, flashcard reveal animation (300ms shallow Y turn), per-answer persistence, one-tap "Count as correct" override, session summary.
- **Deliverables**: `PracticeScheduler`, `SessionController`, Flashcard UI (Variant A notebook layout), Summary view.

### Slice 4: Question Variety & Answer Checking
- **Focus**: Multiple-choice format generator (distractor selection algorithm), typing question format with normalization (trimming, niqqud stripping, typo tolerance ≤1/≤2), English TTS audio playback via native speech engine.
- **Deliverables**: `DistractorGenerator`, `AnswerChecker`, Typing & Multiple Choice practice components, Audio button integration.

### Slice 5: Library Search & Backup Export/Import v1
- **Focus**: Full-library search (Hebrew niqqud-insensitive), sorting/filtering, atomic JSON export/import via system share sheet and file picker, conflict resolution (newer `updatedAt` wins, local wins ties).
- **Deliverables**: Library Search & Filter screen, `ExportImportService`, Share/Pick file integration.

### Slice 6: Visual Polish, Accessibility & Device Release
- **Focus**: Notebook page styling refit, theme switching (Light/Dark), accessibility contracts (large font scaling, reduced motion handling, minimum touch targets), build verification, APK generation, and installation on user's Android phone.
- **Deliverables**: Final theme & layout polish, clean analysis, passing test suites, release APK installed on phone.

---

## 4. Definition of Done (DoD)

The build phase for *knew* is complete when all of the following criteria are met:

1. **Static Analysis**: `flutter analyze` passes with zero errors and zero warnings across the entire codebase.
2. **Automated Unit & Integration Test Suites**:
   - `test/unit/scheduler_test.dart`: Spaced-repetition math, level boundaries (0–6), and calendar date interval additions.
   - `test/unit/answer_checker_test.dart`: Typo distance calculations, diacritic/niqqud normalization, and exact string matching.
   - `test/unit/question_selection_test.dart`: Session queue creation, 10-new item caps, distractor selection rules, and format switching limits.
   - `test/unit/gemini_parser_test.dart`: JSON Schema response parsing, error mapping, and timeout handling.
   - `test/integration/sqlite_repository_test.dart`: Real SQLite CRUD, duplicate key rejection, timestamp integrity, and import rollback transactions.
3. **Widget & Accessibility Validation**:
   - High text scale (200%) reflow verified without overflow or truncated text.
   - Reduced motion setting disables 300ms flip animation.
   - RTL text direction applied correctly on all Hebrew translations and inputs.
   - Minimum 48px touch targets enforced on all interactive buttons.
4. **On-Device Physical Verification**:
   - APK built and installed on the user's personal Android phone.
   - Assisted lookup with real Gemini API key tested successfully.
   - At least 1 full practice session completed on device with real audio playback.
