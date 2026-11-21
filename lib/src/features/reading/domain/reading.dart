class ReadingBook {
  final int number;
  final String title;

  /// Title used by other editions, sent to Claude so either is recognized.
  final String? alternateTitle;
  final int numberedChapters;
  final bool hasEpilogue;

  const ReadingBook(
    this.number,
    this.title,
    this.numberedChapters, {
    this.alternateTitle,
    this.hasEpilogue = false,
  });

  /// The epilogue, when present, is the step after the last numbered chapter.
  int get chapterCount => numberedChapters + (hasEpilogue ? 1 : 0);

  bool isEpilogue(int chapter) => hasEpilogue && chapter == chapterCount;

  String get label => 'Harry Potter $number · $title';
}

const readingBooks = <ReadingBook>[
  ReadingBook(1, "Philosopher's Stone", 17, alternateTitle: "Sorcerer's Stone"),
  ReadingBook(2, 'Chamber of Secrets', 18),
  ReadingBook(3, 'Prisoner of Azkaban', 22),
  ReadingBook(4, 'Goblet of Fire', 37),
  ReadingBook(5, 'Order of the Phoenix', 38),
  ReadingBook(6, 'Half-Blood Prince', 30),
  ReadingBook(7, 'Deathly Hallows', 36, hasEpilogue: true),
];

/// The book and chapter the learner is currently on.
class Reading {
  final ReadingBook book;
  final int chapter;

  const Reading(this.book, this.chapter);

  bool get isEpilogue => book.isEpilogue(chapter);

  /// Saved as the `source` of Entries added from this Reading.
  String get source => isEpilogue
      ? 'Harry Potter ${book.number} · epilogue'
      : 'Harry Potter ${book.number} · ch. $chapter';
}

/// A word Claude suggests for a Reading. Not an Entry until learned.
class ChapterWord {
  final String key;
  final String term;
  final String hebrew;
  final String definition;
  final bool revealed;

  const ChapterWord({
    required this.key,
    required this.term,
    required this.hebrew,
    required this.definition,
    this.revealed = false,
  });

  String get meaning => '$hebrew; $definition';
}
