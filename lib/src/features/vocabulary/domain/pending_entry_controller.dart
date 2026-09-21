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

  Future<void> capture(String term) async {
    final entry = Entry.create(
      english: term,
      meanings: const [],
      status: EntryStatus.pending,
    );
    await _repository.insertEntry(entry);
    unawaited(start());
  }

  Future<void> retry(Entry entry) async {
    await _repository.updateEntry(entry.copyWith(status: EntryStatus.pending));
    unawaited(start());
  }

  Future<void> start() async {
    if (isRunning) return;
    isRunning = true;
    notifyListeners();
    try {
      final pending =
          (await _repository.getAllEntries())
              .where((entry) => entry.status == EntryStatus.pending)
              .toList()
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      for (final entry in pending) {
        try {
          final result = await _lookup(entry.english);
          if (result is GeminiSuccessResult) {
            await _repository.updateEntry(
              entry.copyWith(
                meanings: result.meanings,
                status: EntryStatus.ready,
              ),
            );
          } else {
            await _repository.updateEntry(
              entry.copyWith(status: EntryStatus.failed),
            );
          }
        } catch (_) {
          await _repository.updateEntry(
            entry.copyWith(status: EntryStatus.failed),
          );
        }
        notifyListeners();
      }
    } finally {
      isRunning = false;
      notifyListeners();
    }
  }
}
