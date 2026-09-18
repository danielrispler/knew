import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../vocabulary/presentation/entry_form_screen.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import '../../settings/presentation/settings_providers.dart';
import '../data/suggested_words_repository.dart';
import '../domain/suggested_word.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});
  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  SuggestedWordsRepository? _repository;
  List<SuggestedWord>? _words;
  Future<void>? _prefetching;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool fresh = false}) async {
    final db = await ref.read(databaseProvider.future);
    final repository = SuggestedWordsRepository(db);
    final words = fresh
        ? await repository.newBatch()
        : await repository.loadOrCreateBatch();
    if (mounted) {
      setState(() {
        _repository = repository;
        _words = words;
      });
    }
    _startPrefetch(repository);
  }

  void _startPrefetch(SuggestedWordsRepository repository) {
    if (_prefetching != null) return;
    final pending = _prefetch(repository);
    _prefetching = pending;
    pending.whenComplete(() {
      if (_prefetching == pending) _prefetching = null;
    });
  }

  Future<void> _prefetch(SuggestedWordsRepository repository) async {
    try {
      final settings = await ref.read(settingsProvider.future);
      final bandCenter = await repository.bandCenter();
      await repository.refillGeminiQueue(
        (excluded) => ref
            .read(geminiClientProvider)
            .suggestedWords(
              excluded: excluded,
              bandCenter: bandCenter,
              apiKey: settings.apiKey,
              model: settings.model,
            ),
      );
    } catch (_) {}
  }

  Future<void> _act(Future<void> Function() action) async {
    await action();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final words = _words;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        actions: [
          TextButton(
            onPressed: _repository == null ? null : () => _load(fresh: true),
            child: const Text('New batch'),
          ),
        ],
      ),
      body: words == null
          ? const Center(child: CircularProgressIndicator())
          : words.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.done_all, size: 56),
                  const SizedBox(height: 12),
                  const Text('All caught up'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _load(fresh: true),
                    child: const Text('More words'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: words.length,
              itemBuilder: (context, index) {
                final word = words[index];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          word.term,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (word.revealed) ...[
                          const SizedBox(height: 8),
                          Text(word.meaning, textDirection: TextDirection.rtl),
                        ],
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (!word.revealed && word.meaning.isNotEmpty)
                              OutlinedButton(
                                onPressed: () =>
                                    _act(() => _repository!.reveal(word.key)),
                                child: const Text('Reveal meaning'),
                              ),
                            OutlinedButton(
                              onPressed: () =>
                                  _act(() => _repository!.known(word)),
                              child: const Text('I know this'),
                            ),
                            OutlinedButton(
                              onPressed: () =>
                                  _act(() => _repository!.skip(word.key)),
                              child: const Text('Skip'),
                            ),
                            FilledButton(
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => EntryFormScreen(
                                      initialTerm: word.term,
                                      onSaved: () =>
                                          _repository!.markLearned(word.key),
                                    ),
                                  ),
                                );
                                await _load();
                              },
                              child: const Text('Learn'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
