# knew

A personal vocabulary trainer for a Hebrew speaker learning English.

## Language & Domain Terms

**Term**: The English word or short phrase being learned (e.g., "persistent", "put up with").
_Avoid_: "Word" when excluding phrases would change the meaning.

**Entry**: A saved term together with its meanings, source, context, and learning progress.
_Avoid_: "Translation" when referring to the whole saved record.

**Pending Entry**: A captured English Term waiting for Gemini to provide Meanings. It is visible in the library but cannot be practiced.

**Meaning**: One sense of a term, with its part of speech, Hebrew translations, and a simple English definition.

**Example Usage**: A Meaning-owned English sentence with one marked target form, used for Flashcard context and Cloze.

**Cloze**: A Meaning-scoped fill-in-the-blank question using Example Usage.

**Collocation**: A saved word combination displayed as usage context on Flashcards.

**Inflection Match**: A valid saved form other than the example's exact target; it is editable rather than graded correct.

**Enrichment**: Best-effort generated usage fields attached to a Meaning after save.

**Translation**: A Hebrew expression conveying a meaning of the English term.

**Definition**: A short explanation of a meaning in simple English.

**Level**: An entry's learning progress from 0 through 6; level 0 means it has never been reviewed.
_Avoid_: "Stage" for an individual numbered level.

**Stage**: The grouping of levels into New (0–2), Familiar (3–4), or Learned (5–6).
_Avoid_: "Level" for the named grouping.

**Due**: Ready for scheduled review because the entry's review date is today or earlier.

**Scheduled**: Standard spaced-repetition practice of due entries that updates learning progress.

**Review**: A graded encounter with a due entry that updates its learning progress.

**Practice session**: A bounded sequence of questions about selected entries.

**Repeat**: The additional practice question offered after an incorrect review in the same session.

**Extra practice**: Practice offered when nothing is due, without changing review schedules.

**Early review**: Opt-in practice of entries before their scheduled due date that updates learning progress and advances levels.

## Discover

**Discover**: An opt-in feature that suggests unfamiliar English words for the user to consider adding to their library.
_Avoid_: "Recommend", "Explore".

**Suggested Word**: A word offered to the user on the Discover screen that they have not yet acted on; it is not an Entry until the user chooses to learn it.
_Avoid_: "Suggestion", "Recommendation".

**Candidate Pool**: The frequency-ranked set of English words eligible to become Suggested Words, primarily sourced from a bundled word list with a small portion contributed by Gemini.

**Discovery Band**: The current target frequency/rank range used to select Suggested Words from the Candidate Pool, inferred from the user's Learn and Known interactions over time.
_Avoid_: Using this to represent the user's general English level or CEFR level.

**Known**: A Suggested Word the user has explicitly marked as already familiar; permanently excluded from future suggestions.
_Avoid_: "Dismissed", "Ignored".

**Skipped**: A Suggested Word the user has deferred without indicating familiarity; it may resurface in a future batch.
_Avoid_: "Hidden", "Snoozed".
