class SuggestedWord {
  final String key;
  final String term;
  final int? rank;
  final String meaning;
  final int order;
  final bool revealed;

  const SuggestedWord({
    required this.key,
    required this.term,
    required this.rank,
    required this.meaning,
    required this.order,
    this.revealed = false,
  });

  SuggestedWord copyWith({bool? revealed}) => SuggestedWord(
    key: key,
    term: term,
    rank: rank,
    meaning: meaning,
    order: order,
    revealed: revealed ?? this.revealed,
  );
}
