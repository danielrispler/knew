import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/data/words_repository.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/library_enrichment_controller.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/vocabulary/domain/meaning_enrichment.dart';

class MemoryWordsRepository implements WordsRepository {
  MemoryWordsRepository(this.entries);
  final List<Entry> entries;
  int saves = 0;

  @override
  Future<List<Entry>> getAllEntries() async => entries;

  @override
  Future<bool> applyEnrichment(Entry original, List<Meaning> meanings) async {
    saves++;
    final index = entries.indexWhere((entry) => entry.id == original.id);
    entries[index] = original.copyWith(meanings: meanings);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Entry entry(String id, String word) => Entry.create(
  id: id,
  english: word,
  meanings: const [
    Meaning(
      partOfSpeech: 'noun',
      definition: 'thing',
      hebrewTranslations: ['דבר'],
    ),
  ],
);

void main() {
  test('persists each entry and resumes from unfinished meanings', () async {
    final repository = MemoryWordsRepository([
      entry('1', 'apple'),
      entry('2', 'pear'),
    ]);
    late final LibraryEnrichmentController controller;
    controller = LibraryEnrichmentController(
      repository: repository,
      pacing: Duration.zero,
      enrich: (current) async => [
        const MeaningEnrichment(
          correlationKey: 'noun\u0000thing\u0000דבר',
          examples: ['An [[apple]] is red.'],
          collocations: ['red apple'],
          validInflections: [],
        ),
      ],
    );

    await controller.start();
    expect(repository.saves, 2);
    expect(controller.remaining, 0);

    await controller.start();
    expect(repository.saves, 2);
  });

  test('stop waits for the in-flight entry before stopping', () async {
    final repository = MemoryWordsRepository([
      entry('1', 'apple'),
      entry('2', 'pear'),
    ]);
    late final LibraryEnrichmentController controller;
    controller = LibraryEnrichmentController(
      repository: repository,
      pacing: Duration.zero,
      enrich: (current) async {
        controller.stop();
        return const [];
      },
    );

    await controller.start();
    expect(controller.isRunning, isFalse);
    expect(controller.remaining, 2);
  });
}
