import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';

import '../../settings/presentation/settings_providers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../vocabulary/presentation/entry_form_screen.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../data/chapter_words_repository.dart';
import '../data/claude_client.dart';
import '../domain/reading.dart';
import 'reading_providers.dart';

class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({super.key});
  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  ChapterWordsRepository? _repository;
  Reading? _reading;
  List<ChapterWord> _words = const [];
  bool _hasWords = false;
  bool _fetching = false;
  ClaudeErrorType? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repository =
        _repository ??
        ChapterWordsRepository(await ref.read(databaseProvider.future));
    final reading = await repository.reading();
    final words = await repository.words(reading);
    final hasWords = await repository.hasWords(reading);
    if (!mounted) return;
    setState(() {
      _repository = repository;
      _reading = reading;
      _words = words;
      _hasWords = hasWords;
    });
  }

  Future<void> _setReading(Reading reading) async {
    await _repository!.setReading(reading);
    _error = null;
    await _load();
  }

  Future<void> _act(Future<void> Function() action) async {
    await action();
    await _load();
  }

  Future<void> _fetch() async {
    final repository = _repository!;
    final reading = _reading!;
    setState(() {
      _fetching = true;
      _error = null;
    });
    ClaudeErrorType? error;
    try {
      final settings = await ref.read(settingsProvider.future);
      final words = await ref
          .read(claudeClientProvider)
          .chapterWords(
            reading: reading,
            apiKey: settings.claudeApiKey,
            alreadySuggested: await repository.alreadySuggested(reading),
            tooEasy: await repository.recentTerms('known'),
            rightLevel: await repository.recentTerms('learned'),
          );
      await repository.save(reading, words);
    } on ClaudeException catch (e) {
      error = e.type;
    }
    if (!mounted) return;
    setState(() {
      _fetching = false;
      _error = error;
    });
    await _load();
  }

  Future<void> _capture({ChapterWord? word}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryFormScreen(
          initialTerm: word?.term,
          initialSource: _reading!.source,
        ),
      ),
    );
    await _load();
  }

  void _openSettings() => Navigator.of(
    context,
  ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final reading = _reading;
    final hasKey =
        (ref.watch(settingsProvider).value?.claudeApiKey ?? '').isNotEmpty;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.readingTitle)),
      body: reading == null
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      _header(l10n, reading),
                      Expanded(child: _content(l10n, hasKey)),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            if (_hasWords)
                              OutlinedButton(
                                key: const Key('reading_more_words'),
                                onPressed: _fetching || !hasKey ? null : _fetch,
                                child: Text(l10n.readingMoreWords),
                              ),
                            OutlinedButton(
                              key: const Key('reading_add_word'),
                              onPressed: _capture,
                              child: Text(l10n.readingAddWord),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _header(AppLocalizations l10n, Reading reading) {
    final book = reading.book;
    final step = _fetching
        ? null
        : (int chapter) => _setReading(Reading(book, chapter));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          DropdownButton<int>(
            key: const Key('reading_book'),
            isExpanded: true,
            value: book.number,
            items: [
              for (final option in readingBooks)
                DropdownMenuItem(
                  value: option.number,
                  child: Text(option.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _fetching
                ? null
                : (number) => _setReading(
                    Reading(
                      readingBooks.firstWhere((b) => b.number == number),
                      1,
                    ),
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  reading.isEpilogue
                      ? l10n.readingEpilogue
                      : l10n.readingChapterOf(
                          reading.chapter,
                          book.numberedChapters,
                        ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                key: const Key('reading_previous_chapter'),
                tooltip: l10n.readingPreviousChapter,
                icon: const Icon(Icons.remove),
                onPressed: step == null || reading.chapter <= 1
                    ? null
                    : () => step(reading.chapter - 1),
              ),
              IconButton(
                key: const Key('reading_next_chapter'),
                tooltip: l10n.readingNextChapter,
                icon: const Icon(Icons.add),
                onPressed: step == null || reading.chapter >= book.chapterCount
                    ? null
                    : () => step(reading.chapter + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _content(AppLocalizations l10n, bool hasKey) {
    if (_fetching) return const Center(child: CircularProgressIndicator());
    if (_words.isNotEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(claudeErrorMessage(l10n, _error!)),
            ),
          for (final word in _words) _card(l10n, word),
        ],
      );
    }
    final needsKey = !hasKey || _error == ClaudeErrorType.missingKey;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (needsKey && !_hasWords) ...[
              Text(l10n.readingNoKey, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _openSettings,
                child: Text(l10n.openSettings),
              ),
            ] else if (_error != null) ...[
              Text(
                claudeErrorMessage(l10n, _error!),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: _fetch, child: Text(l10n.retry)),
            ] else if (_hasWords)
              Text(l10n.readingNothingWaiting, textAlign: TextAlign.center)
            else
              FilledButton(
                key: const Key('reading_get_words'),
                onPressed: _fetch,
                child: Text(l10n.readingGetWords),
              ),
          ],
        ),
      ),
    );
  }

  Widget _card(AppLocalizations l10n, ChapterWord word) {
    final repository = _repository!;
    final reading = _reading!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(word.term, style: Theme.of(context).textTheme.headlineSmall),
            if (word.revealed) ...[
              const SizedBox(height: 8),
              Text(word.meaning, textDirection: TextDirection.rtl),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (!word.revealed)
                  OutlinedButton(
                    onPressed: () =>
                        _act(() => repository.reveal(reading, word.key)),
                    child: Text(l10n.discoverRevealMeaning),
                  ),
                OutlinedButton(
                  onPressed: () => _act(() => repository.known(word)),
                  child: Text(l10n.discoverKnown),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _act(() => repository.skip(reading, word.key)),
                  child: Text(l10n.discoverSkip),
                ),
                FilledButton(
                  onPressed: () => _capture(word: word),
                  child: Text(l10n.discoverLearn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
