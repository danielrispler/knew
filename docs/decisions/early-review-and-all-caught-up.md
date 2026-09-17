# Early review and "All caught up" interstitial

Resolution for user request on 2026-09-17: handling practice when all due entries for the day have already been reviewed.

## Context and Problem

Under the original Spaced Repetition (SRS) design ([practice-lifecycle.md](file:///Users/danielrispler/work/knew/docs/decisions/practice-lifecycle.md)), entries promoted to Level 1 are scheduled for review tomorrow (1-day interval). If the user starts practice again on the same day, no entries are due. The system previously fell back silently to non-durable Extra Practice without UI indication. In Extra Practice, progress is never committed. Consequently, words practiced repeatedly on the same day remained stuck at Level 1 ("1/6"), creating the perception of an infinite cycle bug.

## Resolution

### 1. "All Caught Up" Interstitial Screen
When tapping the Practice action from the library:
- If `dueEntries.isNotEmpty`: proceed directly to standard Scheduled Practice.
- If `dueEntries.isEmpty` and `library.isNotEmpty`: display the **All Caught Up** screen.
  - Heading: "All caught up for today!" (Hebrew: "סיימת את כל התרגולים להיום!")
  - Subtitle: Explains all scheduled reviews for today are completed.
  - Status info: Displays count of terms reviewed today (if any) and upcoming scheduled reviews.
  - Action 1: **Advance (Early Review)** — allows the user to practice terms before their scheduled date and advance their Level.
  - Action 2: **Repractice (Extra Practice)** — allows drill without modifying levels or schedules.
  - Exit: "Done" button returns to the vocabulary library.

### 2. Early Review Mode
- **Durable changes**: Early review is a fully graded, durable practice session.
- **Grading rules**:
  - Correct answers increase the entry's Level by 1 (clamped to 6), increment `timesCorrect`, update `lastReviewedAt`, and compute a new `dueDate` from today + the new level's interval (`intervalsInDays[newLevel]`).
  - Incorrect answers follow standard grading: decrease Level by 1 (clamped to minimum 1), increment `timesWrong`, update `lastReviewedAt`, and schedule for tomorrow (`today + 1`).
- **Candidate selection**:
  - Primary: Entries reviewed today (`lastReviewedAt` matching local today's date), sorted by `(dueDate, createdAt, id)`.
  - Fallback (if no entries were reviewed today, e.g. imported future entries): Future-scheduled entries in ascending `dueDate` order.
  - Subject to session size cap (default 20) and max 10 level-0 entries.

### 3. Extra Practice (Repractice) Mode
- Strictly non-durable drill. Writes no changes to level, counters, timestamps, or due dates.
- Practice screen and summary screen clearly display an "Extra Practice" badge/label so the user is never misled about progress persistence.

### 4. Domain Glossary Additions
- Added **Early review** to `CONTEXT.md`: Opt-in practice of entries before their scheduled due date that updates learning progress and advances levels.
