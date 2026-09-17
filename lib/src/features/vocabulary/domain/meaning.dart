class Meaning {
  final String partOfSpeech;
  final String definition;
  final List<String> hebrewTranslations;
  final List<String> examples;
  final List<String> collocations;
  final List<String> validInflections;
  final String? enrichedAt;

  const Meaning({
    required this.partOfSpeech,
    required this.definition,
    required this.hebrewTranslations,
    this.examples = const [],
    this.collocations = const [],
    this.validInflections = const [],
    this.enrichedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'partOfSpeech': partOfSpeech,
      'definition': definition,
      'hebrewTranslations': hebrewTranslations,
      'examples': examples,
      'collocations': collocations,
      'validInflections': validInflections,
      'enrichedAt': enrichedAt,
    };
  }

  factory Meaning.fromJson(Map<String, dynamic> json) {
    final rawTranslations = json['hebrewTranslations'];
    final List<String> translations;
    if (rawTranslations is List) {
      translations = rawTranslations.map((e) => e.toString()).toList();
    } else {
      translations = [];
    }

    List<String> strings(String key) {
      final value = json[key];
      return value is List
          ? value
                .whereType<String>()
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
          : const [];
    }

    return Meaning(
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      hebrewTranslations: translations,
      examples: strings('examples'),
      collocations: strings('collocations'),
      validInflections: strings('validInflections'),
      enrichedAt: json['enrichedAt'] as String?,
    );
  }

  Meaning copyWith({
    String? partOfSpeech,
    String? definition,
    List<String>? hebrewTranslations,
    List<String>? examples,
    List<String>? collocations,
    List<String>? validInflections,
    String? enrichedAt,
    bool clearEnrichedAt = false,
  }) {
    return Meaning(
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
      hebrewTranslations:
          hebrewTranslations ?? List.from(this.hebrewTranslations),
      examples: examples ?? List.from(this.examples),
      collocations: collocations ?? List.from(this.collocations),
      validInflections: validInflections ?? List.from(this.validInflections),
      enrichedAt: clearEnrichedAt ? null : (enrichedAt ?? this.enrichedAt),
    );
  }
}
