import 'meaning.dart';

class MeaningEnrichment {
  final String correlationKey;
  final List<String> examples;
  final List<String> collocations;
  final List<String> validInflections;

  const MeaningEnrichment({
    required this.correlationKey,
    required this.examples,
    required this.collocations,
    required this.validInflections,
  });

  Meaning applyTo(Meaning meaning, {required String enrichedAt}) =>
      meaning.copyWith(
        examples: examples,
        collocations: collocations,
        validInflections: validInflections,
        enrichedAt: enrichedAt,
      );
}
