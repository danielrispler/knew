# Question selection

Resolution for [Decide: question selection algorithm](https://github.com/danielrispler/knew/issues/9). These are the smallest deterministic resolutions of the original brief's ambiguous constraints, under the map's authorization to decide reversible details.

## Queue

Validate session size as an integer from 1 through 100; default 20. For scheduled practice, select entries with dueDate <= local today and sort by (dueDate ascending, createdAt ascending, id ascending). Scan that order, accepting at most ten level-0 entries and continuing past excess new entries to fill remaining slots with previously reviewed entries. Stop at session size or exhaustion. Thirty new entries produce ten questions, not twenty.

When no entries are due, Extra practice selects future entries in the same order up to session size, with the same ten-new cap and no saved progress changes. An empty library instead offers Add word. Home's due count is all due entries, not the capped session length. State the number selected when starting a shorter session.

## Direction and formats

Pick English→Hebrew or Hebrew→English uniformly. Validation requires every saved meaning to have at least one nonempty Hebrew translation, and every entry a nonempty English term; neither direction is unaskable.

For each question, compute legal formats before choosing:

1. Flashcard is always legal.
2. Typing is legal only if the entry was above level 0 at session start. This also applies to its repeat.
3. Multiple choice is legal only if three distinct, unambiguous distractors are available for this direction.
4. After three questions of the same format, remove that format if another legal format exists.
5. Pick uniformly from the remaining formats.

Eligibility and answer ambiguity are hard rules. The three-in-a-row preference yields when flashcard is the only legal choice. Never retry random choices until one happens to fit. The consecutive-format counter spans the whole session, including repeats, and resets between sessions. Repeat direction and format are selected again under these rules.

Inject a Dart Random into the queue/question functions (seed it in tests); also pass today's date and the entry snapshot explicitly. Use a stable candidate order before shuffling so a seed gives reproducible choices.

## Multiple choice

English→Hebrew shows the first meaning's Hebrew translations, joined with a comma inside one RTL text run. Hebrew→English shows the English term. The correct option and distractors have the same rendering convention. Each option in a single question uses the expected answer language; separate questions exercise both languages.

Exclude the current entry. Prefer entries whose first meaning has the same part of speech; shuffle that group, then the remaining group. Walk those candidates until three valid distractors are collected, then shuffle all four options.

Reject distractors that render identically after trim/lowercase/space collapse/niqqud normalization. For Hebrew options, also reject a candidate if any of its first-meaning translations equals any accepted translation of the target, or overlaps an already selected option. Thus two entries sharing a correct Hebrew translation cannot produce an ambiguous question. Candidate entries may appear elsewhere in this session. If fewer than three survive, multiple choice is unavailable even if the library has four entries.

## Answer checking and manual overrides

Typing accepts every translation across all stored meanings in English→Hebrew, or the term in Hebrew→English. Normalize by trimming, lowercasing, removing Unicode punctuation and Hebrew niqqud, then collapsing whitespace. Compare exact normalized answers first; use code points rather than UTF-16 units for edit distance. The brief's tolerance remains <=1 for expected answers up to five code points and <=2 for longer expected answers. Empty normalized input is never correct. A small typo shows the accepted spelling; another valid synonym can be accepted with Count as correct. Synonym overrides do not automatically edit the vocabulary entry.

## Required examples

- Three new entries: three flashcards; repeated flashcards remain legal.
- Four entries but duplicate Hebrew translations: multiple choice may be unavailable.
- Thirty new entries: ten selected; ten repeats at most if all are missed.
- Excess new entries followed by overdue reviewed entries: skip excess new entries and keep filling.
- Equal due dates: createdAt then id resolves ties.
- Wrong first-pass answer then correct repeat: saved progress still reflects the original wrong answer.

Tests should assert these invariants, both directions, and all legal outputs across controlled random inputs; avoid fixing tests to an implementation-specific random sequence alone.
