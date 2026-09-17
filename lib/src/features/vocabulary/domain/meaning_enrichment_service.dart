import '../data/words_repository.dart';
import 'entry.dart';
import 'example_usage.dart';
import 'meaning_enrichment.dart';
import 'meaning.dart';

class MeaningEnrichmentService {
  final WordsRepository repository;

  const MeaningEnrichmentService(this.repository);

  Future<bool> save(
    Entry entry,
    Iterable<MeaningEnrichment> results, {
    DateTime? now,
  }) {
    final byKey = {for (final result in results) result.correlationKey: result};
    final enrichedAt = (now ?? DateTime.now()).toUtc().toIso8601String();
    final meanings = entry.meanings.map((meaning) {
      final result = byKey[_key(meaning)];
      if (result == null) return meaning;
      final forms = [entry.english, ...result.validInflections];
      return result
          .applyTo(meaning, enrichedAt: enrichedAt)
          .copyWith(
            examples: result.examples
                .where((example) => ExampleUsage.parse(example, forms) != null)
                .toList(),
          );
    }).toList();
    return repository.applyEnrichment(entry, meanings);
  }

  static String _key(Meaning meaning) =>
      '${meaning.partOfSpeech}\u0000${meaning.definition}\u0000${meaning.hebrewTranslations.join('\u0000')}';
}
