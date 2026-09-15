# Export and import v1

Resolution for [Decide: export format v1 and import merge semantics](https://github.com/danielrispler/knew/issues/10). The user approved full vocabulary/progress backup, newer whole-entry wins, local wins ties, and all-or-nothing validation on 2026-09-15.

## File contract

UTF-8 JSON, independent of SQL column names. Export all entries and their progress, including UUIDs; omit settings, Gemini key, and unfinished sessions. Timestamps are UTC ISO 8601 instants with a Z suffix; dueDate is a real Gregorian YYYY-MM-DD calendar date. Optional text fields and lastReviewedAt are present as null when absent. Meanings are a JSON array, not a JSON-encoded string.

```json
{
  "version": 1,
  "exportedAt": "2026-09-15T09:00:00.000Z",
  "words": [
    {
      "id": "46e2cf36-d1b9-49b0-b481-8d85f8b6d0a1",
      "english": "persistent",
      "meanings": [
        {
          "partOfSpeech": "adjective",
          "hebrew": ["מתמיד", "עיקש"],
          "definition": "continuing to try even when something is hard"
        }
      ],
      "source": "A book",
      "context": null,
      "level": 2,
      "dueDate": "2026-09-17",
      "lastReviewedAt": "2026-09-15T08:00:00.000Z",
      "timesCorrect": 2,
      "timesWrong": 0,
      "createdAt": "2026-09-13T08:00:00.000Z",
      "updatedAt": "2026-09-15T08:00:00.000Z"
    }
  ]
}
```

The example's scheduling fields describe an entry just promoted to level 2. exportedAt describes the file, never conflict precedence. Every locally persisted content or progress mutation updates updatedAt; importing preserves the winning record's timestamp to make repeated imports idempotent.

## Validation

Before writes, read at most 10 MiB of file bytes and accept at most 10,000 entries. These are explicit v1 personal-library limits; export applies the same bounds so the app never creates a file its importer rejects. Explain the limit if exceeded; do not emit a truncated backup. Enforce the byte limit during reading where the picker offers a path/stream, and before decoding when bytes are returned directly.

Require an object, integer version exactly 1, valid exportedAt, and words array. Validate every required field and reject wrong types, missing fields, invalid UUIDs, invalid dates/timestamps, levels outside 0–6, negative/non-integer counters, empty terms, or meanings outside 1–3. Each meaning needs a nonempty partOfSpeech, at least one nonempty Hebrew translation, and a nonempty definition. Level 0 requires null lastReviewedAt and zero counters; reviewed entries require lastReviewedAt and at least one recorded answer. Require updatedAt >= createdAt and lastReviewedAt <= updatedAt when present. Validate calendar dates by round-trip components rather than accepting a parser's date overflow normalization.

Use the same trim/space-collapse/lowercase term key as normal saves. Preserve punctuation: “can't” and “cant” are distinct terms. Reject duplicate term keys or duplicate UUIDs inside the file. Unknown additional fields are ignored for forward-compatible optional metadata, but never passed directly to SQL. Reject unknown file versions with “This backup needs a newer version of knew. Update the app and try again.” Reject any bad entry with its position and reason; no partial import.

## Merge

Validate the whole file, then execute the complete merge in one transaction using the transaction's current rows:

1. Match by normalized English term, as promised by the brief.
2. If absent, insert the incoming entry. Preserve its UUID unless it is already used by a different local term; in that case assign a new UUID. This handles an entry renamed on one copy without overwriting an unrelated term.
3. If present and incoming updatedAt is strictly later, replace all vocabulary/progress fields, preserving the existing local UUID. Preserve incoming createdAt and updatedAt.
4. Otherwise keep the local record, including timestamp ties.

Renames are distinct terms for merge purposes; importing an old name can add it alongside a renamed entry. Deletions are not propagated by a vocabulary backup: importing a file can restore previously deleted terms. This is backup merging, not device synchronization.

Added = previously absent term inserted. Updated = matched term replaced because its incoming timestamp was later. Skipped = matched term kept because incoming timestamp was equal or older. Counts sum to file entry count, and are shown only after commit. A rolled-back failure reports that nothing was imported. System clock inaccuracies may affect newer-wins ordering; there is no server clock or field-by-field merge in this personal app.

## Mechanics and evolution

Export opens the share sheet with JSON bytes via share_plus XFile.fromData and fileNameOverrides; use knew-export-YYYY-MM-DD-HHmmss.json. Set sharePositionOrigin for iPad. Sharing completion does not prove the user saved the backup; report Shared only if the platform confirms sharing, and do not report a backup as saved after cancellation. Use the plugin's cache-backed temporary file; no automatic scheduled-export feature or additional path package. Cached exports can remain until OS cleanup; never delete a file while a share target may still read it.

Import selects a single JSON file with file_picker. Extension/MIME filtering is a convenience; validate content even if the picker allowed the selection. Cancellation changes nothing. Future readers must retain v1 support through an explicit conversion to their current internal model. A v1 reader rejects v2 rather than guessing. SQL schema versions and export versions evolve independently.

## Verification during implementation

Require export→import round trip, repeated import idempotence, UTC timestamp comparison, tie handling, progress replacement, duplicate term/UUID rejection, UUID collision on a new term, unknown version rejection, over-limit input, invalid calendar dates, and rollback after a write failure. See the package research ticket for platform APIs; verify installed signatures when building.
