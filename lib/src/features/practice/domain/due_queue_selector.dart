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
  static QueueSelectionResult selectQueue({
    required List<Entry> library,
    required String todayDueDate,
    int requestedSessionSize = 20,
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

    if (dueEntries.isNotEmpty) {
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
