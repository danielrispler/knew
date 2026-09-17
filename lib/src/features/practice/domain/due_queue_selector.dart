import '../../vocabulary/domain/entry.dart';

class QueueSelectionResult {
  final List<Entry> entries;
  final bool isExtraPractice;

  const QueueSelectionResult({
    required this.entries,
    required this.isExtraPractice,
  });
}

abstract class DueQueueSelector {
  static bool hasDueEntries({
    required List<Entry> library,
    required String todayDueDate,
  }) {
    return library.any((e) => e.dueDate.compareTo(todayDueDate) <= 0);
  }

  static List<Entry> getReviewedToday({
    required List<Entry> library,
    required String todayDueDate,
  }) {
    return library.where((e) {
      if (e.lastReviewedAt == null) return false;
      try {
        final parsed = DateTime.parse(e.lastReviewedAt!).toLocal();
        final year = parsed.year.toString().padLeft(4, '0');
        final month = parsed.month.toString().padLeft(2, '0');
        final day = parsed.day.toString().padLeft(2, '0');
        return '$year-$month-$day' == todayDueDate;
      } catch (_) {
        return false;
      }
    }).toList();
  }

  static QueueSelectionResult selectQueue({
    required List<Entry> library,
    required String todayDueDate,
    int requestedSessionSize = 20,
    bool isEarlyReview = false,
  }) {
    if (library.isEmpty) {
      return const QueueSelectionResult(entries: [], isExtraPractice: false);
    }

    final sessionSize = requestedSessionSize.clamp(1, 100);

    final dueEntries = library
        .where((e) => e.dueDate.compareTo(todayDueDate) <= 0)
        .toList();

    bool isExtraPractice = false;
    List<Entry> candidates;

    if (isEarlyReview) {
      final reviewedToday = getReviewedToday(
        library: library,
        todayDueDate: todayDueDate,
      );
      if (reviewedToday.isNotEmpty) {
        candidates = reviewedToday;
      } else {
        final futureEntries = library
            .where((e) => e.dueDate.compareTo(todayDueDate) > 0)
            .toList();
        if (futureEntries.isEmpty) {
          return const QueueSelectionResult(entries: [], isExtraPractice: false);
        }
        candidates = futureEntries;
      }
      isExtraPractice = false;
    } else if (dueEntries.isNotEmpty) {
      candidates = dueEntries;
    } else {
      final futureEntries = library
          .where((e) => e.dueDate.compareTo(todayDueDate) > 0)
          .toList();

      if (futureEntries.isEmpty) {
        return const QueueSelectionResult(entries: [], isExtraPractice: false);
      }
      isExtraPractice = true;
      candidates = futureEntries;
    }

    candidates.sort((a, b) {
      int cmp = a.dueDate.compareTo(b.dueDate);
      if (cmp != 0) return cmp;
      cmp = a.createdAt.compareTo(b.createdAt);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    final selected = <Entry>[];
    int level0Count = 0;

    for (final entry in candidates) {
      if (selected.length >= sessionSize) break;

      if (entry.level == 0) {
        if (level0Count < 10) {
          selected.add(entry);
          level0Count++;
        }
      } else {
        selected.add(entry);
      }
    }

    return QueueSelectionResult(
      entries: selected,
      isExtraPractice: isExtraPractice,
    );
  }
}
