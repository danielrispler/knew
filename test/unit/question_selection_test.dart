import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/practice/domain/due_queue_selector.dart';

void main() {
  final testMeaning = Meaning(
    partOfSpeech: 'noun',
    definition: 'def',
    hebrewTranslations: ['תרגום'],
  );

  Entry createEntry({
    required String id,
    required String english,
    required int level,
    required String dueDate,
    required DateTime createdAt,
  }) {
    return Entry.create(
      id: id,
      english: english,
      meanings: [testMeaning],
      level: level,
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }

  group('DueQueueSelector - Scheduled Practice Queue Selection', () {
    final today = '2026-09-15';

    test('Filters due entries (dueDate <= today) and sorts by (dueDate asc, createdAt asc, id asc)', () {
      final entries = [
        createEntry(id: '3', english: 'c', level: 1, dueDate: '2026-09-14', createdAt: DateTime(2026, 1, 3)),
        createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-10', createdAt: DateTime(2026, 1, 1)),
        createEntry(id: '2', english: 'b', level: 1, dueDate: '2026-09-14', createdAt: DateTime(2026, 1, 2)),
        createEntry(id: '4', english: 'd', level: 1, dueDate: '2026-09-20', createdAt: DateTime(2026, 1, 4)), // Future/Not due
      ];

      final result = DueQueueSelector.selectQueue(
        library: entries,
        todayDueDate: today,
        requestedSessionSize: 20,
      );

      expect(result.isExtraPractice, isFalse);
      expect(result.entries.length, equals(3));
      expect(result.entries.map((e) => e.id).toList(), equals(['1', '2', '3']));
    });

    test('Caps Level 0 (new) items at 10 and fills remaining slots with reviewed items', () {
      final entries = <Entry>[];

      // Create 15 Level 0 items due today
      for (int i = 1; i <= 15; i++) {
        entries.add(createEntry(
          id: 'new_$i',
          english: 'new_$i',
          level: 0,
          dueDate: '2026-09-10',
          createdAt: DateTime(2026, 1, i),
        ));
      }

      // Create 10 Level 1+ items due today
      for (int i = 1; i <= 10; i++) {
        entries.add(createEntry(
          id: 'rev_$i',
          english: 'rev_$i',
          level: 1,
          dueDate: '2026-09-12',
          createdAt: DateTime(2026, 1, i),
        ));
      }

      final result = DueQueueSelector.selectQueue(
        library: entries,
        todayDueDate: today,
        requestedSessionSize: 20,
      );

      expect(result.isExtraPractice, isFalse);
      expect(result.entries.length, equals(20));

      final level0Count = result.entries.where((e) => e.level == 0).length;
      final reviewedCount = result.entries.where((e) => e.level > 0).length;

      expect(level0Count, equals(10));
      expect(reviewedCount, equals(10));
    });

    test('30 new entries with zero reviewed entries produces 10 questions', () {
      final entries = <Entry>[];
      for (int i = 1; i <= 30; i++) {
        entries.add(createEntry(
          id: 'new_$i',
          english: 'new_$i',
          level: 0,
          dueDate: '2026-09-15',
          createdAt: DateTime(2026, 1, i),
        ));
      }

      final result = DueQueueSelector.selectQueue(
        library: entries,
        todayDueDate: today,
        requestedSessionSize: 20,
      );

      expect(result.isExtraPractice, isFalse);
      expect(result.entries.length, equals(10));
      expect(result.entries.every((e) => e.level == 0), isTrue);
    });

    test('Clamps requested session size to 1..100 range', () {
      final entries = [
        createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-15', createdAt: DateTime(2026, 1, 1)),
      ];

      final resultZero = DueQueueSelector.selectQueue(
        library: entries,
        todayDueDate: today,
        requestedSessionSize: 0,
      );
      expect(resultZero.entries.length, equals(1));

      final resultNegative = DueQueueSelector.selectQueue(
        library: entries,
        todayDueDate: today,
        requestedSessionSize: -5,
      );
      expect(resultNegative.entries.length, equals(1));
    });
  });

  group('DueQueueSelector - Extra Practice Queue Selection', () {
    final today = '2026-09-15';

    test('Selects future entries when zero entries are due today', () {
      final entries = [
        createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-20', createdAt: DateTime(2026, 1, 1)),
        createEntry(id: '2', english: 'b', level: 2, dueDate: '2026-09-18', createdAt: DateTime(2026, 1, 2)),
      ];

      final result = DueQueueSelector.selectQueue(
        library: entries,
        todayDueDate: today,
        requestedSessionSize: 20,
      );

      expect(result.isExtraPractice, isTrue);
      expect(result.entries.length, equals(2));
      expect(result.entries.map((e) => e.id).toList(), equals(['2', '1']));
    });

    test('Returns empty queue if library is completely empty', () {
      final result = DueQueueSelector.selectQueue(
        library: [],
        todayDueDate: today,
        requestedSessionSize: 20,
      );

      expect(result.entries, isEmpty);
      expect(result.isExtraPractice, isFalse);
    });
  });

  group('DueQueueSelector - Early Review Queue Selection & Helpers', () {
    final today = '2026-09-15';

    test('hasDueEntries detects whether any entry is due today or earlier', () {
      final notDue = [
        createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-16', createdAt: DateTime(2026, 1, 1)),
      ];
      final due = [
        createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-15', createdAt: DateTime(2026, 1, 1)),
      ];

      expect(DueQueueSelector.hasDueEntries(library: notDue, todayDueDate: today), isFalse);
      expect(DueQueueSelector.hasDueEntries(library: due, todayDueDate: today), isTrue);
      expect(DueQueueSelector.hasDueEntries(library: [], todayDueDate: today), isFalse);
    });

    test('getReviewedToday returns entries whose lastReviewedAt is on local today', () {
      final reviewedTodayIso = DateTime(2026, 9, 15, 14, 30).toUtc().toIso8601String();
      final reviewedYesterdayIso = DateTime(2026, 9, 14, 10, 0).toUtc().toIso8601String();

      final e1 = createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-16', createdAt: DateTime(2026, 1, 1))
          .copyWith(lastReviewedAt: reviewedTodayIso);
      final e2 = createEntry(id: '2', english: 'b', level: 1, dueDate: '2026-09-16', createdAt: DateTime(2026, 1, 1))
          .copyWith(lastReviewedAt: reviewedYesterdayIso);
      final e3 = createEntry(id: '3', english: 'c', level: 0, dueDate: '2026-09-15', createdAt: DateTime(2026, 1, 1));

      final result = DueQueueSelector.getReviewedToday(library: [e1, e2, e3], todayDueDate: today);
      expect(result.length, equals(1));
      expect(result.first.id, equals('1'));
    });

    test('selectQueue with isEarlyReview: true prioritizes today-reviewed entries with isExtraPractice: false', () {
      final reviewedTodayIso = DateTime(2026, 9, 15, 14, 30).toUtc().toIso8601String();
      final e1 = createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-16', createdAt: DateTime(2026, 1, 1))
          .copyWith(lastReviewedAt: reviewedTodayIso);
      final e2 = createEntry(id: '2', english: 'b', level: 1, dueDate: '2026-09-20', createdAt: DateTime(2026, 1, 2));

      final result = DueQueueSelector.selectQueue(
        library: [e1, e2],
        todayDueDate: today,
        requestedSessionSize: 20,
        isEarlyReview: true,
      );

      expect(result.isExtraPractice, isFalse);
      expect(result.entries.length, equals(1));
      expect(result.entries.first.id, equals('1'));
    });

    test('selectQueue with isEarlyReview: true falls back to future entries if none reviewed today', () {
      final e1 = createEntry(id: '1', english: 'a', level: 1, dueDate: '2026-09-20', createdAt: DateTime(2026, 1, 1));
      final e2 = createEntry(id: '2', english: 'b', level: 2, dueDate: '2026-09-18', createdAt: DateTime(2026, 1, 2));

      final result = DueQueueSelector.selectQueue(
        library: [e1, e2],
        todayDueDate: today,
        requestedSessionSize: 20,
        isEarlyReview: true,
      );

      expect(result.isExtraPractice, isFalse);
      expect(result.entries.length, equals(2));
      expect(result.entries.map((e) => e.id).toList(), equals(['2', '1']));
    });
  });
}
