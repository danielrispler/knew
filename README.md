# knew

A personal vocabulary trainer for Hebrew speakers learning English.

Save English terms and phrases, review them with spaced repetition, and build
your library at your own pace. `knew` is single-user and keeps vocabulary and
progress on the device.

## Features

- Add and edit English terms or short phrases with Hebrew translations and
  simple English definitions.
- Look up terms with Gemini to prefill meanings; review and edit everything
  before saving.
- Practise due entries with flashcards, multiple choice, typing, cloze, and
  sentence-production questions.
- Use spaced repetition with six learning levels and scheduled reviews.
- Hear English terms with text-to-speech.
- Search the library, discover suggested words, and export or import a JSON
  backup of vocabulary and progress.
- Switch between light, dark, and system themes, and English or Hebrew UI.

## Run locally

Install the [Flutter SDK](https://docs.flutter.dev/get-started/install), then:

```bash
flutter pub get
flutter run
```

To run the checks:

```bash
flutter analyze
flutter test
```

## Gemini lookup

Gemini lookup is optional. Add your Gemini API key in **Settings** and use the
connection test there before looking up a term. The key is stored in the
platform secure store; it is not included in exports or device backups.

## Your data

Vocabulary, meanings, and review progress are stored locally in SQLite. Use
**Settings → Export Backup** to create a portable JSON backup; importing merges
entries by their most recently updated version. See
[the backup guide](docs/backup-and-updates.md) for update and recovery details.

## Development notes

- Flutter with Material 3 and Riverpod
- SQLite for local persistence
- Android-primary, with iOS compatibility

Product terminology and decisions live in [CONTEXT.md](CONTEXT.md) and
[docs/adr](docs/adr/).

## License

The bundled Frank Ruhl Libre font is licensed under the
[SIL Open Font License](assets/fonts/OFL.txt).
