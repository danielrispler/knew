class Meaning {
  final String partOfSpeech;
  final String definition;
  final List<String> hebrewTranslations;

  const Meaning({
    required this.partOfSpeech,
    required this.definition,
    required this.hebrewTranslations,
  });

  Map<String, dynamic> toJson() {
    return {
      'partOfSpeech': partOfSpeech,
      'definition': definition,
      'hebrewTranslations': hebrewTranslations,
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

    return Meaning(
      partOfSpeech: json['partOfSpeech'] as String? ?? '',
      definition: json['definition'] as String? ?? '',
      hebrewTranslations: translations,
    );
  }

  Meaning copyWith({
    String? partOfSpeech,
    String? definition,
    List<String>? hebrewTranslations,
  }) {
    return Meaning(
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      definition: definition ?? this.definition,
      hebrewTranslations: hebrewTranslations ?? List.from(this.hebrewTranslations),
    );
  }
}
