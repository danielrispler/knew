import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/gemini_lookup_result.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/domain/pending_entry_controller.dart';

class _Repository extends Fake implements WordsRepository {
  final entries = <Entry>[];

  @override
  Future<void> insertEntry(Entry entry) async => entries.add(entry);

  @override
  Future<void> updateEntry(Entry entry) async {
    entries[entries.indexWhere((candidate) => candidate.id == entry.id)] =
        entry;
  }

  @override
  Future<Entry?> getEntryById(String id) async {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  @override
  Future<List<Entry>> getAllEntries() async => List.of(entries);
}

void main() {
  test('processes entries captured while a lookup is running', () async {
    final repository = _Repository();
    final firstLookup = Completer<GeminiLookupResult>();
    var calls = 0;
    final controller = PendingEntryController(
      repository: repository,
      lookup: (term) {
        calls++;
        if (calls == 1) return firstLookup.future;
        return Future.value(_success(term));
      },
    );

    await controller.capture('first');
    await Future<void>.delayed(Duration.zero);
    await controller.capture('second');
    firstLookup.complete(_success('first'));
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(
      repository.entries.map((entry) => entry.status),
      everyElement(EntryStatus.ready),
    );
    expect(calls, 2);
  });
}

GeminiSuccessResult _success(String term) => GeminiSuccessResult(
  english: term,
  englishAlternatives: const [],
  meanings: const [
    Meaning(
      partOfSpeech: 'noun',
      hebrewTranslations: ['מונח'],
      definition: 'a term',
    ),
  ],
  originalInput: term,
  inputLanguage: 'en',
);
