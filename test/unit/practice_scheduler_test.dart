import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/domain/entry.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';
import 'package:knew/src/features/practice/domain/practice_scheduler.dart';

void main() {
  final testMeaning = Meaning(
    partOfSpeech: 'noun',
    hebrewTranslations: ['מבחן'],
    definition: 'A test definition',
  );

  Entry createTestEntry({
    required String id,
    required int level,
    required String dueDate,
    int timesCorrect = 0,
    int timesWrong = 0,
  }) {
    return Entry.create(
      id: id,
      english: 'test',
      meanings: [testMeaning],
      level: level,
      dueDate: dueDate,
      timesCorrect: timesCorrect,
      timesWrong: timesWrong,
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('schedules from the local day at a UTC-midnight boundary', () {
    final instant = DateTime.utc(2026, 9, 15, 23, 30);
    final local = instant.toLocal();
    final entry = createTestEntry(id: '1', level: 0, dueDate: '2026-09-15');

    final updated = PracticeScheduler.gradeCorrect(entry, now: instant);
    final tomorrow = DateTime(local.year, local.month, local.day + 1);

    expect(updated.dueDate, PracticeScheduler.formatLocalDate(tomorrow));
    expect(updated.lastReviewedAt, instant.toIso8601String());
  });

  group('PracticeScheduler - Correct Grade Level & Interval Transitions', () {
    final now = DateTime(2026, 9, 15, 10, 0); // 2026-09-15

    test('Level 0 -> Level 1 (1 day interval)', () {
      final entry = createTestEntry(id: '1', level: 0, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(1));
      expect(updated.dueDate, equals('2026-09-16'));
      expect(updated.timesCorrect, equals(1));
      expect(updated.timesWrong, equals(0));
      expect(updated.lastReviewedAt, isNotNull);
    });

    test('Level 1 -> Level 2 (2 days interval)', () {
      final entry = createTestEntry(id: '1', level: 1, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(2));
      expect(updated.dueDate, equals('2026-09-17'));
    });

    test('Level 2 -> Level 3 (4 days interval)', () {
      final entry = createTestEntry(id: '1', level: 2, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(3));
      expect(updated.dueDate, equals('2026-09-19'));
    });

    test('Level 3 -> Level 4 (7 days interval)', () {
      final entry = createTestEntry(id: '1', level: 3, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(4));
      expect(updated.dueDate, equals('2026-09-22'));
    });

    test('Level 4 -> Level 5 (14 days interval)', () {
      final entry = createTestEntry(id: '1', level: 4, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(5));
      expect(updated.dueDate, equals('2026-09-29'));
    });

    test('Level 5 -> Level 6 (30 days interval)', () {
      final entry = createTestEntry(id: '1', level: 5, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(6));
      expect(updated.dueDate, equals('2026-10-15'));
    });

    test('Level 6 capped at Level 6 (30 days interval)', () {
      final entry = createTestEntry(id: '1', level: 6, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeCorrect(entry, now: now);

      expect(updated.level, equals(6));
      expect(updated.dueDate, equals('2026-10-15'));
    });
  });

  group('PracticeScheduler - Incorrect Grade Level & Interval Transitions', () {
    final now = DateTime(2026, 9, 15, 10, 0);

    test('Level 0 -> Level 1 (min 1, due tomorrow)', () {
      final entry = createTestEntry(id: '1', level: 0, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeIncorrect(entry, now: now);

      expect(updated.level, equals(1));
      expect(updated.dueDate, equals('2026-09-16'));
      expect(updated.timesCorrect, equals(0));
      expect(updated.timesWrong, equals(1));
    });

    test('Level 1 -> Level 1 (min 1, due tomorrow)', () {
      final entry = createTestEntry(id: '1', level: 1, dueDate: '2026-09-15');
      final updated = PracticeScheduler.gradeIncorrect(entry, now: now);

      expect(updated.level, equals(1));
      expect(updated.dueDate, equals('2026-09-16'));
      expect(updated.timesWrong, equals(1));
    });

    test('Level 4 -> Level 3 (due tomorrow)', () {
      final entry = createTestEntry(
        id: '1',
        level: 4,
        dueDate: '2026-09-15',
        timesWrong: 1,
      );
      final updated = PracticeScheduler.gradeIncorrect(entry, now: now);

      expect(updated.level, equals(3));
      expect(updated.dueDate, equals('2026-09-16'));
      expect(updated.timesWrong, equals(2));
    });
  });

  group('PracticeScheduler - DST and Calendar Month Math', () {
    test(
      'Calculates local calendar dates correctly across month boundaries and leap year',
      () {
        final febEnd = DateTime(2028, 2, 28, 23, 30); // Leap year 2028
        final entry = createTestEntry(id: '1', level: 0, dueDate: '2028-02-28');
        final updated = PracticeScheduler.gradeCorrect(entry, now: febEnd);

        expect(updated.dueDate, equals('2028-02-29'));
      },
    );

    test('Calculates local calendar dates across DST spring forward', () {
      // In many timezones, March 29 has DST change (e.g. 23 hour day).
      // Calendar math must add integer days, not 24*3600*1000 milliseconds.
      final march28 = DateTime(2026, 3, 28, 12, 0);
      final entry = createTestEntry(
        id: '1',
        level: 3,
        dueDate: '2026-03-28',
      ); // level 3 -> 4 (7 days)
      final updated = PracticeScheduler.gradeCorrect(entry, now: march28);

      expect(updated.dueDate, equals('2026-04-04'));
    });
  });

  group('PracticeScheduler - Grade Override (Count as Correct)', () {
    final now = DateTime(2026, 9, 15, 10, 0);

    test(
      'Replaces wrong grade with correct grade from original pre-answer snapshot',
      () {
        final original = createTestEntry(
          id: '1',
          level: 2,
          dueDate: '2026-09-15',
          timesCorrect: 3,
          timesWrong: 1,
        );

        final overridden = PracticeScheduler.overrideWrongWithCorrect(
          original,
          now: now,
        );

        // Original was level 2, +1 correct -> level 3 (4 days interval)
        expect(overridden.level, equals(3));
        expect(overridden.dueDate, equals('2026-09-19'));
        expect(overridden.timesCorrect, equals(4));
        expect(
          overridden.timesWrong,
          equals(1),
        ); // wrong count restored from original, not incremented
        expect(
          overridden.lastReviewedAt,
          equals(now.toUtc().toIso8601String()),
        );
      },
    );
  });
}
