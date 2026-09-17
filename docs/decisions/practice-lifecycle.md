# Practice session lifecycle

Resolution for [Decide: practice session lifecycle and what survives leaving](https://github.com/danielrispler/knew/issues/7), agreed with the user on 2026-09-15.

## Lifetime

A session queue, question state, repeats, and summary exist only in memory. Starting practice snapshots the selected entries. Backgrounding preserves the session while the process and route survive. Explicitly leaving practice or process termination discards it; opening practice again builds a fresh queue. There is no resume prompt or stored session table. A session that remains alive across midnight continues; each graded review uses the local calendar date at grading time.

States: question → feedback → next question → summary. Flashcards add a reveal state before grading. Back from any state ends the session. On a failed save, keep the current question/answer visible, explain that progress was not saved, and offer Retry; do not advance or include it in the summary. Disable duplicate submissions while saving and after a successful grade.

## Durable changes

Each first-pass scheduled answer commits one transaction immediately: level, dueDate, lastReviewedAt, the appropriate correctness counter, and updatedAt. Preserve term, meanings, source, context, and createdAt. Correct increases level by one (maximum 6); intervals for levels 1–6 are 1, 2, 4, 7, 14, 30 calendar days. Incorrect reduces level by one with minimum 1 and schedules tomorrow. Level 0 exists only before the first review.

Use the injected local clock's calendar components to add days, not elapsed 24-hour durations; DST must not shift the intended date. UTC timestamps identify instants; dueDate is a local date independent of timezone conversion.

For a typing answer marked incorrect, Count as correct replaces this question's previous grade using its in-memory pre-answer progress snapshot, in one transaction. Remove the previous wrong-counter increment, apply exactly one correct increment and the correct schedule, refresh updatedAt, and remove this question's pending repeat. Offer the action only before Next; repeated taps cannot apply it twice. Leaving without correcting retains the saved incorrect grade.

Repeats and extra practice write no progress, counters, or timestamps. Each first-pass incorrect entry gets exactly one repeat at the end, in first-error order; an incorrect repeat never adds another. Extra practice may also repeat misses once, with all answers remaining non-durable. For opt-in durable practice of non-due entries, see [Early review and All caught up](early-review-and-all-caught-up.md).

## Cloze (Phase 1)

Cloze uses one valid example and Meaning from the session snapshot. Exact target-form answers grade normally. A valid but wrong inflection stays editable and writes nothing; possible typos require explicit confirmation. Hints, confirmed typos, and Show Answer are assisted outcomes: they never promote the Level. An ordinary incorrect answer follows the normal incorrect and one-repeat lifecycle.

## Sentence Production (Phase 2)

At Levels 5–6, Sentence Production is Meaning-scoped. A local whole-token check requires the Term or a saved valid inflection before requesting AI feedback. Validity requires target use, intended meaning, and grammar; naturalness remains feedback only. An invalid first pass keeps the Level, schedules tomorrow, increments `timesWrong`, and gets one offline repeat. Count as correct replaces that result from the pre-review snapshot. An AI failure writes no progress, disables Sentence Production for the session, and replaces affected questions with Cloze for that Meaning when available, otherwise Typing.

## Summary and changes to the library

Scheduled summary: reviewed count is the number of distinct first-pass entries committed; accuracy is correct first-pass grades divided by that count, after corrections. Repeats are excluded. Stage movements compare each entry's pre-review and final level. Extra practice uses the same first-pass accuracy calculation, is labelled Extra practice, and shows no stage movements. Zero answers never divides by zero.

Editing, deleting, resetting, or importing entries requires leaving practice first. Thus normal navigation cannot mutate its snapshot. If the repository nevertheless reports a selected entry missing, skip it without recreating it or counting a review. Reset progress requires confirmation and sets level 0, dueDate today, counters 0, lastReviewedAt null, and updatedAt now; preserve createdAt and vocabulary fields.

## Verification during implementation

Test immediate persistence on early exit, failed writes retaining the question, one-shot correction replacing a wrong grade, repeat non-recursion, extra-practice non-mutation, and local-calendar scheduling across DST. Process restart must build a new queue from saved progress.
