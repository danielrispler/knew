# SQLite schema and migrations

Resolution for [Decide: SQLite schema and migration strategy](https://github.com/danielrispler/knew/issues/8). The user approved one vocabulary table, one settings table, calendar dates, and migrations preserving data on 2026-09-15. Storage and session decisions: [local SQLite](../adr/0001-local-storage.md), [session lifecycle](practice-lifecycle.md).

## Schema version 1

```sql
CREATE TABLE words (
  id TEXT NOT NULL PRIMARY KEY,
  english TEXT NOT NULL CHECK (length(trim(english)) > 0),
  english_key TEXT NOT NULL UNIQUE CHECK (length(english_key) > 0),
  meanings TEXT NOT NULL,
  source TEXT,
  context TEXT,
  level INTEGER NOT NULL DEFAULT 0 CHECK (level BETWEEN 0 AND 6),
  due_date TEXT NOT NULL CHECK (length(due_date) = 10),
  last_reviewed_at TEXT,
  times_correct INTEGER NOT NULL DEFAULT 0 CHECK (times_correct >= 0),
  times_wrong INTEGER NOT NULL DEFAULT 0 CHECK (times_wrong >= 0),
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE INDEX words_due_date ON words (due_date);

CREATE TABLE settings (
  name TEXT NOT NULL PRIMARY KEY,
  value TEXT NOT NULL
);
```

The due-date index serves due selection and soonest-due sorting. The UUID primary key serves details/update/delete. The normalized term's unique constraint handles duplicate detection, including edits and import. Stage counts, other sorting, Hebrew search, and distractors operate on the personal library snapshot; no extra indexes, full-text search, or meaning tables are justified for this version.

## Representations and validation

UUIDs are strings. english retains its case but is trimmed and internal whitespace collapsed before saving. english_key uses that same canonical text lowercased with Dart String.toLowerCase. Use the same normalization for saves, edits, lookup duplicate checks, and import. Preserve punctuation and diacritics in identity. This deliberately avoids mixing Dart lowercasing with SQLite's ASCII-only NOCASE behavior. [SQLite collations](https://www.sqlite.org/datatype3.html#collation)

meanings is UTF-8 JSON text representing the entire list, decoded in Dart. All save/import boundaries require 1–3 meanings, each with nonempty partOfSpeech and definition and at least one nonempty Hebrew translation. Manual editing may use a part-of-speech label beyond the API enum. The enum constrains lookup generation; saved entries need a nonempty label. Optional source/context are null when blank. Definitions from Gemini are limited to 15 words by the lookup parser; manual definitions may be longer.

due_date is a validated real Gregorian YYYY-MM-DD date, zero-padded, for lexicographic <= and ordering. Store last_reviewed_at, created_at, and updated_at as fixed-precision UTC ISO 8601 strings with a Z suffix, or null for absent last_reviewed_at. Compare parsed instants during imports, then normalize the stored representation; do not compare arbitrary timestamp strings with differing offsets. SQLite permits TEXT dates, but application validation must enforce these conventions. [SQLite date representations](https://www.sqlite.org/datatype3.html#date_and_time_datatype)

The SQL checks are a last line of defense, not the complete validator: validate types, real dates, UUIDs, meaningful JSON, and progress consistency in Dart before any write. Decode explicitly into known fields. A corrupt stored record yields a recoverable error, never silent database replacement. Stage is derived from level; session state is in memory. The complete export validation and conflict rules live in [Export/import v1](export-import.md).

## Search and settings

Search English terms and every Hebrew translation by normalized substring. For searching only, trim, collapse whitespace, lowercase, and remove Hebrew combining marks U+0591–U+05BD, U+05BF, U+05C1–U+05C2, U+05C4–U+05C5, U+05C7. Normalize both query and candidate text; a blank normalized query shows all entries. Store the original strings. This requires no normalized shadow column or SQLite JSON extension. Accent/cantillation stripping here is a search policy, independent of term uniqueness.

Settings rows: sessionSize (default 20, allowed 1–100), model (default from Gemini research), theme (system/light/dark, default system), lastSource (default empty). Store each value as JSON text, validate by its known key, and use defaults for missing settings. Save lastSource only after successfully saving an entry. The Gemini key alone uses flutter_secure_storage and never appears in SQLite, exports, logs, or research assets.

## Migrations

Open knew.db at sqflite's database path with version 1. onCreate builds the current schema. For future versions, increment the integer version and apply each incremental step in ascending order when oldVersion is lower than that step; include direct-upgrade paths from every supported previous version. onCreate/onUpgrade are already transactional in sqflite; use the provided database handle rather than nesting a transaction. [sqflite opening and migration contract](https://github.com/tekartik/sqflite/blob/master/sqflite/doc/opening_db.md)

Migrations preserve user data. Never drop/recreate the database on upgrade failure or downgrade. Report the failure and retain the file; a newer database opened by older app code must be rejected. Each migration gets a fixture test with vocabulary/progress from the previous schema plus a fresh-install check. A change to derived normalization that can merge distinct existing keys is a real migration requiring an explicit collision policy. Do not store schema versions in export files as a substitute for their independent format version.

## Implementation verification

Check fresh creation, duplicate save/edit rejection, all meaning JSON round trips, date ordering across months/years, Hebrew niqqud-insensitive search, settings defaults, and an import transaction rollback. Test repository behavior against real SQLite on an integration target; mocking SQL cannot establish constraint or migration behavior.
