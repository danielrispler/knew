import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/words_repository.dart';
import 'entry.dart';
import 'gemini_lookup_result.dart';
import 'meaning_enrichment.dart';
import 'meaning_enrichment_service.dart';

typedef EnrichEntry = Future<List<MeaningEnrichment>> Function(Entry entry);

class LibraryEnrichmentController extends ChangeNotifier {
  LibraryEnrichmentController({
    required this._repository,
    required this.enrich,
    this.pacing = const Duration(seconds: 1),
    Future<void> Function(Duration duration)? wait,
  }) : _wait = wait ?? Future<void>.delayed;

  final WordsRepository _repository;
  final EnrichEntry enrich;
  final Duration pacing;
  final Future<void> Function(Duration duration) _wait;
  bool _stopRequested = false;
  bool isRunning = false;
  int remaining = 0;
  int completed = 0;
  int total = 0;
  String? currentTerm;
  String? error;

  Future<void> refresh() async {
    if (isRunning) return;
    final entries = await _repository.getAllEntries();
    remaining = entries
        .where(
          (entry) =>
              entry.meanings.any((meaning) => meaning.enrichedAt == null),
        )
        .length;
    notifyListeners();
  }

  Future<void> start() async {
    if (isRunning) return;
    _stopRequested = false;
    isRunning = true;
    error = null;
    final entries = await _repository.getAllEntries();
    final pending = entries
        .where(
          (entry) =>
              entry.meanings.any((meaning) => meaning.enrichedAt == null),
        )
        .toList();
    remaining = pending.length;
    total = pending.length;
    completed = 0;
    notifyListeners();
    final saver = MeaningEnrichmentService(_repository);
    var stopRun = false;
    for (final entry in pending) {
      if (_stopRequested) break;
      currentTerm = entry.english;
      notifyListeners();
      var attempts = 0;
      var saved = false;
      while (!_stopRequested && attempts < 3) {
        try {
          final results = await enrich(entry);
          final expected = entry.meanings
              .where((meaning) => meaning.enrichedAt == null)
              .map(MeaningEnrichmentService.keyFor)
              .toSet();
          saved =
              results.isNotEmpty &&
              expected.every(
                (key) => results.any((result) => result.correlationKey == key),
              ) &&
              await saver.save(entry, results);
          if (!saved) error = 'Could not save enrichment for ${entry.english}.';
          break;
        } on GeminiException catch (exception) {
          error = exception.message;
          if (exception.retryAfter != null && attempts++ < 2) {
            final retryAfter = exception.retryAfter!;
            await _wait(
              retryAfter > const Duration(minutes: 1)
                  ? const Duration(minutes: 1)
                  : retryAfter,
            );
            continue;
          }
          if (_terminal(exception.errorType)) stopRun = true;
          break;
        } catch (_) {
          error = 'Could not enrich $currentTerm.';
          break;
        }
      }
      if (saved) {
        completed++;
        remaining--;
      }
      notifyListeners();
      if (_stopRequested || stopRun) break;
      if (pacing > Duration.zero) await _wait(pacing);
    }
    currentTerm = null;
    isRunning = false;
    notifyListeners();
  }

  void stop() => _stopRequested = true;

  bool _terminal(GeminiErrorType type) => switch (type) {
    GeminiErrorType.missingKey ||
    GeminiErrorType.invalidKey ||
    GeminiErrorType.unauthenticated ||
    GeminiErrorType.permissionDenied ||
    GeminiErrorType.quotaExhausted ||
    GeminiErrorType.configurationError ||
    GeminiErrorType.modelUnavailable => true,
    _ => false,
  };
}
