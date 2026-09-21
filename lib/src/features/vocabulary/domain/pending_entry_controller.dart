import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/words_repository.dart';
import 'entry.dart';
import 'gemini_lookup_result.dart';

typedef LookupTerm = Future<GeminiLookupResult> Function(String term);

class PendingEntryController extends ChangeNotifier {
  PendingEntryController({
    required WordsRepository repository,
    required LookupTerm lookup,
  }) : _repository = repository,
       _lookup = lookup;
  final WordsRepository _repository;
  final LookupTerm _lookup;
  bool isRunning = false;
  bool _restartRequested = false;

  Future<Entry> capture(String term) async {
    final entry = Entry.create(
      english: term,
      meanings: const [],
      status: EntryStatus.pending,
    );
    await _repository.insertEntry(entry);
    unawaited(start());
    return entry;
  }

  Future<void> retry(Entry entry) async {
    await _repository.updateEntry(entry.copyWith(status: EntryStatus.pending));
    unawaited(start());
  }

  Future<void> start() async {
    if (isRunning) {
      _restartRequested = true;
      return;
    }
    isRunning = true;
    notifyListeners();
    try {
      do {
        _restartRequested = false;
        final pending =
            (await _repository.getAllEntries())
                .where((entry) => entry.status == EntryStatus.pending)
                .toList()
              ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
        for (final entry in pending) {
          try {
            final result = await _lookup(entry.english);
            final current = await _repository.getEntryById(entry.id);
            if (current?.status != EntryStatus.pending) continue;
            if (result is GeminiSuccessResult) {
              await _repository.updateEntry(
                current!.copyWith(
                  meanings: result.meanings,
                  status: EntryStatus.ready,
                ),
              );
            } else {
              await _repository.updateEntry(
                current!.copyWith(status: EntryStatus.failed),
              );
            }
          } catch (_) {
            final current = await _repository.getEntryById(entry.id);
            if (current?.status == EntryStatus.pending) {
              await _repository.updateEntry(
                current!.copyWith(status: EntryStatus.failed),
              );
            }
          }
          notifyListeners();
        }
      } while (_restartRequested);
    } finally {
      isRunning = false;
      notifyListeners();
    }
  }
}
