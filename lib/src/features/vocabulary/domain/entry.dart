import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'meaning.dart';

enum Stage { newStage, familiar, learned }

enum EntryStatus { pending, ready, failed }

class Entry {
  final String id;
  final String english;
  final String englishKey;
  final List<Meaning> meanings;
  final EntryStatus status;
  final String? source;
  final String? context;
  final int level;
  final String dueDate;
  final String? lastReviewedAt;
  final int timesCorrect;
  final int timesWrong;
  final String createdAt;
  final String updatedAt;

  Entry({
    required this.id,
    required this.english,
    required this.englishKey,
    required this.meanings,
    this.status = EntryStatus.ready,
    this.source,
    this.context,
    required this.level,
    required this.dueDate,
    this.lastReviewedAt,
    required this.timesCorrect,
    required this.timesWrong,
    required this.createdAt,
    required this.updatedAt,
  });

  static String normalizeTerm(String raw) {
    return raw.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  static String generateKey(String englishTerm) {
    return normalizeTerm(englishTerm).toLowerCase();
  }

  static String todayDueDate([DateTime? now]) {
    final localNow = (now ?? DateTime.now()).toLocal();
    final year = localNow.year.toString().padLeft(4, '0');
    final month = localNow.month.toString().padLeft(2, '0');
    final day = localNow.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  factory Entry.create({
    String? id,
    required String english,
    required List<Meaning> meanings,
    EntryStatus status = EntryStatus.ready,
    String? source,
    String? context,
    int level = 0,
    String? dueDate,
    String? lastReviewedAt,
    int timesCorrect = 0,
    int timesWrong = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final createdAtValue = createdAt ?? DateTime.now();
    final nowIso = createdAtValue.toUtc().toIso8601String();
    final normalizedEnglish = normalizeTerm(english);
    final key = generateKey(normalizedEnglish);

    return Entry(
      id: id ?? const Uuid().v4(),
      english: normalizedEnglish,
      englishKey: key,
      meanings: meanings,
      status: status,
      source: (source != null && source.trim().isNotEmpty)
          ? source.trim()
          : null,
      context: (context != null && context.trim().isNotEmpty)
          ? context.trim()
          : null,
      level: level,
      dueDate: dueDate ?? todayDueDate(createdAtValue),
      lastReviewedAt: lastReviewedAt,
      timesCorrect: timesCorrect,
      timesWrong: timesWrong,
      createdAt: nowIso,
      updatedAt: updatedAt?.toUtc().toIso8601String() ?? nowIso,
    );
  }

  Stage get stage {
    if (level <= 2) return Stage.newStage;
    if (level <= 4) return Stage.familiar;
    return Stage.learned;
  }

  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'english': english,
      'english_key': englishKey,
      'meanings': jsonEncode(meanings.map((m) => m.toJson()).toList()),
      'status': status.name,
      'source': source,
      'context': context,
      'level': level,
      'due_date': dueDate,
      'last_reviewed_at': lastReviewedAt,
      'times_correct': timesCorrect,
      'times_wrong': timesWrong,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  factory Entry.fromDatabaseMap(Map<String, dynamic> map) {
    final meaningsJson = map['meanings'] as String;
    final List decoded = jsonDecode(meaningsJson) as List;
    final meaningsList = decoded
        .map((e) => Meaning.fromJson(e as Map<String, dynamic>))
        .toList();

    return Entry(
      id: map['id'] as String,
      english: map['english'] as String,
      englishKey: map['english_key'] as String,
      meanings: meaningsList,
      status: EntryStatus.values.byName(map['status'] as String? ?? 'ready'),
      source: map['source'] as String?,
      context: map['context'] as String?,
      level: map['level'] as int,
      dueDate: map['due_date'] as String,
      lastReviewedAt: map['last_reviewed_at'] as String?,
      timesCorrect: map['times_correct'] as int,
      timesWrong: map['times_wrong'] as int,
      createdAt: map['created_at'] as String,
      updatedAt: map['updated_at'] as String,
    );
  }

  Entry copyWith({
    String? id,
    String? english,
    List<Meaning>? meanings,
    EntryStatus? status,
    String? source,
    bool clearSource = false,
    String? context,
    bool clearContext = false,
    int? level,
    String? dueDate,
    String? lastReviewedAt,
    bool clearLastReviewedAt = false,
    int? timesCorrect,
    int? timesWrong,
    String? createdAt,
    String? updatedAt,
  }) {
    final newEnglish = english != null ? normalizeTerm(english) : this.english;
    final newKey = english != null ? generateKey(newEnglish) : englishKey;

    return Entry(
      id: id ?? this.id,
      english: newEnglish,
      englishKey: newKey,
      meanings: meanings ?? this.meanings,
      status: status ?? this.status,
      source: clearSource ? null : (source ?? this.source),
      context: clearContext ? null : (context ?? this.context),
      level: level ?? this.level,
      dueDate: dueDate ?? this.dueDate,
      lastReviewedAt: clearLastReviewedAt
          ? null
          : (lastReviewedAt ?? this.lastReviewedAt),
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesWrong: timesWrong ?? this.timesWrong,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isPracticeReady =>
      status == EntryStatus.ready && meanings.isNotEmpty;
}
