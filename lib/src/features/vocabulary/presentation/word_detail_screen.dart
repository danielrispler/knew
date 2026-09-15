import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../domain/entry.dart';
import 'entry_form_screen.dart';
import 'vocabulary_providers.dart';

class WordDetailScreen extends ConsumerStatefulWidget {
  final Entry initialEntry;

  const WordDetailScreen({super.key, required this.initialEntry});

  @override
  ConsumerState<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends ConsumerState<WordDetailScreen> {
  late Entry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.initialEntry;
  }

  Color _stageColor(Stage stage) {
    switch (stage) {
      case Stage.newStage:
        return AppTheme.stageNew;
      case Stage.familiar:
        return AppTheme.stageFamiliar;
      case Stage.learned:
        return AppTheme.stageLearned;
    }
  }

  String _stageLabel(Stage stage) {
    switch (stage) {
      case Stage.newStage:
        return 'New (Level ${_entry.level})';
      case Stage.familiar:
        return 'Familiar (Level ${_entry.level})';
      case Stage.learned:
        return 'Learned (Level ${_entry.level})';
    }
  }

  Future<void> _refreshEntry() async {
    final repo = ref.read(wordsRepositoryProvider);
    final updated = await repo.getEntryById(_entry.id);
    if (updated != null && mounted) {
      setState(() {
        _entry = updated;
      });
    }
  }

  Future<void> _confirmResetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: Text(
          'Are you sure you want to reset learning progress for "${_entry.english}"?\n\n'
          'This will set its level back to Level 0 (New) and clear review statistics.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Reset Progress'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(vocabularyListProvider.notifier).resetProgress(_entry.id);
      await _refreshEntry();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset progress for "${_entry.english}"')),
        );
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry?'),
        content: Text('Are you sure you want to delete "${_entry.english}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(vocabularyListProvider.notifier).deleteEntry(_entry.id);
      if (mounted) {
        Navigator.of(context).pop(); // Return to list after deletion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = _stageColor(_entry.stage);

    return Scaffold(
      appBar: AppBar(
        title: Text(_entry.english),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Entry',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => EntryFormScreen(initialEntry: _entry),
                ),
              );
              await _refreshEntry();
              ref.read(vocabularyListProvider.notifier).refreshList();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete Entry',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600.0),
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // Term Header Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  _entry.english,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        fontFamily: 'FrankRuhlLibre',
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: stageColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: stageColor, width: 1.5),
                                ),
                                child: Text(
                                  _stageLabel(_entry.stage),
                                  style: TextStyle(
                                    color: stageColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_entry.source != null && _entry.source!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(Icons.bookmark_outline, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Source: ${_entry.source}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                          if (_entry.context != null && _entry.context!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '"${_entry.context}"',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Meanings Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Meanings',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(height: 24),
                          ..._entry.meanings.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final meaning = entry.value;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          meaning.partOfSpeech,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    meaning.definition,
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                  const SizedBox(height: 6),
                                  Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(
                                      meaning.hebrewTranslations.join(', '),
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (idx < _entry.meanings.length - 1)
                                    const Divider(height: 24),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Learning Progress & Stats Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learning Progress',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Level:'),
                              Text(
                                '${_entry.level} / 6',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Next Due Date:'),
                              Text(
                                _entry.dueDate,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Last Reviewed:'),
                              Text(
                                _entry.lastReviewedAt != null
                                    ? _entry.lastReviewedAt!.substring(0, 10)
                                    : 'Never',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Times Correct:'),
                              Text(
                                '${_entry.timesCorrect}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Times Incorrect:'),
                              Text(
                                '${_entry.timesWrong}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _confirmResetProgress,
                          icon: const Icon(Icons.refresh, color: Colors.orange),
                          label: const Text('Reset Progress'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    EntryFormScreen(initialEntry: _entry),
                              ),
                            );
                            await _refreshEntry();
                            ref.read(vocabularyListProvider.notifier).refreshList();
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit Entry'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                        ),
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
