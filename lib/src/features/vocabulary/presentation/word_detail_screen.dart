import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../practice/data/tts_service.dart';
import '../domain/entry.dart';
import 'entry_form_screen.dart';
import 'vocabulary_providers.dart';

Future<void> showWordDetailBottomSheet(BuildContext context, Entry entry) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => WordDetailBottomSheet(initialEntry: entry),
  );
}

class WordDetailBottomSheet extends StatelessWidget {
  final Entry initialEntry;

  const WordDetailBottomSheet({super.key, required this.initialEntry});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: WordDetailContent(initialEntry: initialEntry, isBottomSheet: true),
            ),
          ],
        ),
      ),
    );
  }
}

class WordDetailScreen extends StatelessWidget {
  final Entry initialEntry;

  const WordDetailScreen({super.key, required this.initialEntry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(initialEntry.english),
      ),
      body: WordDetailContent(initialEntry: initialEntry, isBottomSheet: false),
    );
  }
}

class WordDetailContent extends ConsumerStatefulWidget {
  final Entry initialEntry;
  final bool isBottomSheet;

  const WordDetailContent({
    super.key,
    required this.initialEntry,
    this.isBottomSheet = false,
  });

  @override
  ConsumerState<WordDetailContent> createState() => _WordDetailContentState();
}

class _WordDetailContentState extends ConsumerState<WordDetailContent> {
  late Entry _entry;
  late TtsService _ttsService;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _entry = widget.initialEntry;
    _ttsService = TtsService();
    _ttsService.init();
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

  String _stageLabel(Stage stage, AppLocalizations l10n) {
    final stageName = switch (stage) {
      Stage.newStage => l10n.stageNew,
      Stage.familiar => l10n.stageFamiliar,
      Stage.learned => l10n.stageLearned,
    };
    return '$stageName (${l10n.level(_entry.level)})';
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

  Future<void> _speakTerm() async {
    setState(() => _isPlayingAudio = true);
    await _ttsService.speak(_entry.english);
    if (mounted) {
      setState(() => _isPlayingAudio = false);
    }
  }

  Future<void> _confirmResetProgress() async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.resetProgress),
        content: Text(l10n.resetProgressConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: Text(l10n.resetProgress),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(vocabularyListProvider.notifier).resetProgress(_entry.id);
      await _refreshEntry();
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
    final l10n = context.l10n;
    final stageColor = _stageColor(_entry.stage);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600.0),
            child: ListView(
              shrinkWrap: widget.isBottomSheet,
              padding: const EdgeInsets.all(20.0),
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
                              child: Row(
                                children: [
                                  Flexible(
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
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      _isPlayingAudio
                                          ? Icons.volume_up
                                          : Icons.volume_up_outlined,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                    tooltip: 'Listen to pronunciation',
                                    onPressed: _speakTerm,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: stageColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: stageColor, width: 1.5),
                              ),
                              child: Text(
                                _stageLabel(_entry.stage, l10n),
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
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        meaning.partOfSpeech,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  meaning.definition,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                const SizedBox(height: 8),
                                Directionality(
                                  textDirection: TextDirection.rtl,
                                  child: Text(
                                    meaning.hebrewTranslations.join(', '),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onSurface,
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
                        // Progress Bar Indicator
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: _entry.level / 6.0,
                            minHeight: 10,
                            backgroundColor:
                                Theme.of(context).colorScheme.outlineVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(stageColor),
                          ),
                        ),
                        const SizedBox(height: 16),
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
                          minimumSize: const Size.fromHeight(52),
                          foregroundColor: Colors.orange,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
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
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: _confirmDelete,
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    label: const Text(
                      'Delete Entry',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
