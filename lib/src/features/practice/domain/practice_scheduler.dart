import '../../vocabulary/domain/entry.dart';

abstract class PracticeScheduler {
  static const List<int> intervalsInDays = [0, 1, 2, 4, 7, 14, 30];

  static String formatLocalDate(DateTime dt) {
    final year = dt.year.toString().padLeft(4, '0');
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String addDaysToLocalDate(DateTime now, int days) {
    final localNow = now.toLocal();
    final target = DateTime(localNow.year, localNow.month, localNow.day + days);
    return formatLocalDate(target);
  }

  static Entry gradeCorrect(Entry entry, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final newLevel = (entry.level + 1).clamp(1, 6);
    final interval = intervalsInDays[newLevel];
    final newDueDate = addDaysToLocalDate(currentTime, interval);
    final nowIso = currentTime.toUtc().toIso8601String();

    return entry.copyWith(
      level: newLevel,
      dueDate: newDueDate,
      lastReviewedAt: nowIso,
      timesCorrect: entry.timesCorrect + 1,
      updatedAt: nowIso,
    );
  }

  static Entry gradeIncorrect(Entry entry, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final newLevel = (entry.level - 1).clamp(1, 6);
    final newDueDate = addDaysToLocalDate(currentTime, 1);
    final nowIso = currentTime.toUtc().toIso8601String();

    return entry.copyWith(
      level: newLevel,
      dueDate: newDueDate,
      lastReviewedAt: nowIso,
      timesWrong: entry.timesWrong + 1,
      updatedAt: nowIso,
    );
  }

  static Entry gradeSentenceIncorrect(Entry entry, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final nowIso = currentTime.toUtc().toIso8601String();
    return entry.copyWith(
      dueDate: addDaysToLocalDate(currentTime, 1),
      lastReviewedAt: nowIso,
      timesWrong: entry.timesWrong + 1,
      updatedAt: nowIso,
    );
  }

  static Entry gradeAssistedCorrect(Entry entry, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final nowIso = currentTime.toUtc().toIso8601String();
    return entry.copyWith(
      dueDate: addDaysToLocalDate(currentTime, intervalsInDays[entry.level]),
      lastReviewedAt: nowIso,
      timesCorrect: entry.timesCorrect + 1,
      updatedAt: nowIso,
    );
  }

  static Entry overrideWrongWithCorrect(Entry originalEntry, {DateTime? now}) {
    // Replaces previous wrong grade using original pre-answer snapshot
    return gradeCorrect(originalEntry, now: now);
  }
}
