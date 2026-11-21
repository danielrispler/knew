import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/entry.dart';
import '../domain/niqqud_helper.dart';
import '../../practice/presentation/flashcard_practice_screen.dart';
import 'entry_form_screen.dart';
import 'word_detail_screen.dart';
import 'vocabulary_providers.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../reading/presentation/reading_screen.dart';

enum _StageFilterChoice { all, newStage, familiar, learned }

class VocabularyListScreen extends ConsumerStatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  ConsumerState<VocabularyListScreen> createState() =>
      _VocabularyListScreenState();
}

class _VocabularyListScreenState extends ConsumerState<VocabularyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Stage? _selectedStageFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
    switch (stage) {
      case Stage.newStage:
        return l10n.stageNew;
      case Stage.familiar:
        return l10n.stageFamiliar;
      case Stage.learned:
        return l10n.stageLearned;
    }
  }

  List<Entry> _filterEntries(List<Entry> entries) {
    var result = entries;

    if (_selectedStageFilter != null) {
      result = result.where((e) => e.stage == _selectedStageFilter).toList();
    }

    final normalizedQuery = normalizeForSearch(_searchQuery);
    if (normalizedQuery.isEmpty) return result;

    return result.where((entry) {
      if (normalizeForSearch(entry.english).contains(normalizedQuery))
        return true;
      if (normalizeForSearch(entry.englishKey).contains(normalizedQuery))
        return true;

      for (var meaning in entry.meanings) {
        if (normalizeForSearch(meaning.partOfSpeech).contains(normalizedQuery))
          return true;
        if (normalizeForSearch(meaning.definition).contains(normalizedQuery))
          return true;

        for (var trans in meaning.hebrewTranslations) {
          if (normalizeForSearch(trans).contains(normalizedQuery)) return true;
        }
      }
      return false;
    }).toList();
  }

  void _selectStageFilter(_StageFilterChoice choice) {
    setState(() {
      _selectedStageFilter = switch (choice) {
        _StageFilterChoice.all => null,
        _StageFilterChoice.newStage => Stage.newStage,
        _StageFilterChoice.familiar => Stage.familiar,
        _StageFilterChoice.learned => Stage.learned,
      };
    });
  }

  List<Widget> _stageFilterChips(AppLocalizations l10n) => [
    FilterChip(
      label: Text(l10n.filterAll),
      selected: _selectedStageFilter == null,
      onSelected: (_) => _selectStageFilter(_StageFilterChoice.all),
    ),
    const SizedBox(width: 8),
    for (final stage in Stage.values) ...[
      FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: _stageColor(stage),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(_filterLabel(stage, l10n)),
          ],
        ),
        selected: _selectedStageFilter == stage,
        onSelected: (selected) => _selectStageFilter(
          selected ? _choiceFor(stage) : _StageFilterChoice.all,
        ),
      ),
      const SizedBox(width: 8),
    ],
  ];

  _StageFilterChoice _choiceFor(Stage stage) => switch (stage) {
    Stage.newStage => _StageFilterChoice.newStage,
    Stage.familiar => _StageFilterChoice.familiar,
    Stage.learned => _StageFilterChoice.learned,
  };

  String _filterLabel(Stage stage, AppLocalizations l10n) => switch (stage) {
    Stage.newStage => l10n.filterNew,
    Stage.familiar => l10n.filterFamiliar,
    Stage.learned => l10n.filterLearned,
  };

  String _selectedFilterLabel(AppLocalizations l10n) =>
      _selectedStageFilter == null
      ? l10n.filterAll
      : _filterLabel(_selectedStageFilter!, l10n);

  void _openScheduledPractice(List<Entry> entries) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FlashcardPracticeScreen(
          initialLibrary: entries,
          onExit: () {
            Navigator.of(context).pop();
            ref.read(vocabularyListProvider.notifier).refreshList();
          },
        ),
      ),
    );
  }

  bool _hasDueEntries(List<Entry> entries) {
    final today = Entry.todayDueDate();
    return entries.any(
      (entry) => entry.isPracticeReady && entry.dueDate.compareTo(today) <= 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final vocabularyAsync = ref.watch(vocabularyListProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Text(
              l10n.appTitle,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 26,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 10),
            vocabularyAsync.when(
              data: (entries) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entries.length}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            tooltip: l10n.readingTitle,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ReadingScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: l10n.discoverTitle,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const DiscoverScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EntryFormScreen()),
          );
        },
        tooltip: l10n.addTermTitle,
        icon: const Icon(Icons.add),
        label: Text(
          l10n.addTermTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showInlineFilters = constraints.maxWidth >= 600;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800.0),
              child: vocabularyAsync.when(
                data: (entries) {
                  final filtered = _filterEntries(entries);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (entries.isNotEmpty)
                        _ReviewStatusCard(
                          entries: entries,
                          onStartPractice: _hasDueEntries(entries)
                              ? () => _openScheduledPractice(entries)
                              : null,
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: l10n.searchPlaceholder,
                                  prefixIcon: const Icon(Icons.search),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear),
                                          onPressed: () {
                                            setState(() {
                                              _searchController.clear();
                                              _searchQuery = '';
                                            });
                                          },
                                        )
                                      : null,
                                ),
                                onChanged: (val) =>
                                    setState(() => _searchQuery = val),
                              ),
                            ),
                            if (!showInlineFilters) ...[
                              const SizedBox(width: 8),
                              PopupMenuButton<_StageFilterChoice>(
                                tooltip: l10n.filter,
                                onSelected: _selectStageFilter,
                                itemBuilder: (context) => [
                                  for (final choice
                                      in _StageFilterChoice.values)
                                    PopupMenuItem(
                                      value: choice,
                                      child: Text(switch (choice) {
                                        _StageFilterChoice.all =>
                                          l10n.filterAll,
                                        _StageFilterChoice.newStage =>
                                          l10n.filterNew,
                                        _StageFilterChoice.familiar =>
                                          l10n.filterFamiliar,
                                        _StageFilterChoice.learned =>
                                          l10n.filterLearned,
                                      }),
                                    ),
                                ],
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.tune),
                                      const SizedBox(width: 6),
                                      Text(_selectedFilterLabel(l10n)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (showInlineFilters)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 4.0,
                          ),
                          child: Row(children: _stageFilterChips(l10n)),
                        ),
                      const SizedBox(height: 8),

                      // Vocabulary Cards List
                      Expanded(
                        child: filtered.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      _searchQuery.isNotEmpty ||
                                              _selectedStageFilter != null
                                          ? Icons.search_off
                                          : Icons.book_outlined,
                                      size: 64,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outline,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty ||
                                              _selectedStageFilter != null
                                          ? l10n.noTermsFound
                                          : l10n.noTermsYet,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outline,
                                          ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filtered.length,
                                padding: const EdgeInsets.only(bottom: 80),
                                itemBuilder: (context, index) {
                                  final entry = filtered[index];
                                  final primaryMeaning =
                                      entry.meanings.isNotEmpty
                                      ? entry.meanings.first
                                      : null;
                                  final hebrewSummary = primaryMeaning != null
                                      ? primaryMeaning.hebrewTranslations.join(
                                          ', ',
                                        )
                                      : '';

                                  return Dismissible(
                                    key: Key(entry.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(
                                          0.9,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                      ),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(l10n.deleteTermConfirm),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(false),
                                              child: Text(l10n.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () => Navigator.of(
                                                context,
                                              ).pop(true),
                                              style: TextButton.styleFrom(
                                                foregroundColor: Colors.red,
                                              ),
                                              child: Text(l10n.delete),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                    onDismissed: (_) {
                                      ref
                                          .read(vocabularyListProvider.notifier)
                                          .deleteEntry(entry.id);
                                    },
                                    child: Card(
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(18),
                                        onTap: () {
                                          if (entry.status ==
                                              EntryStatus.failed) {
                                            ref
                                                .read(pendingEntryProvider)
                                                .retry(entry);
                                            ref
                                                .read(
                                                  vocabularyListProvider
                                                      .notifier,
                                                )
                                                .refreshList();
                                            return;
                                          }
                                          if (entry.status ==
                                              EntryStatus.pending)
                                            return;
                                          showWordDetailBottomSheet(
                                            context,
                                            entry,
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      entry.english,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'FrankRuhlLibre',
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 20,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 10,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: _stageColor(
                                                        entry.stage,
                                                      ).withOpacity(0.15),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                      border: Border.all(
                                                        color: _stageColor(
                                                          entry.stage,
                                                        ),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      entry.status ==
                                                              EntryStatus
                                                                  .pending
                                                          ? l10n.pendingEntryProcessing
                                                          : entry.status ==
                                                                EntryStatus
                                                                    .failed
                                                          ? l10n.pendingEntryRetry
                                                          : _stageLabel(
                                                              entry.stage,
                                                              l10n,
                                                            ),
                                                      style: TextStyle(
                                                        color: _stageColor(
                                                          entry.stage,
                                                        ),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              if (primaryMeaning != null) ...[
                                                Text(
                                                  '[${primaryMeaning.partOfSpeech}] ${primaryMeaning.definition}',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                ),
                                                const SizedBox(height: 6),
                                              ],
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Directionality(
                                                    textDirection:
                                                        TextDirection.rtl,
                                                    child: Text(
                                                      hebrewSummary,
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.outline,
                                                    size: 20,
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text(context.l10n.libraryLoadError('$err'))),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ReviewStatusCard extends StatelessWidget {
  const _ReviewStatusCard({required this.entries, this.onStartPractice});

  final List<Entry> entries;
  final VoidCallback? onStartPractice;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = Entry.todayDueDate();
    final ready = entries.where((entry) => entry.isPracticeReady).toList();
    final dueCount = ready
        .where((entry) => entry.dueDate.compareTo(today) <= 0)
        .length;
    final upcoming = ready
        .where((entry) => entry.dueDate.compareTo(today) > 0)
        .map((entry) => entry.dueDate)
        .fold<String?>(
          null,
          (next, date) =>
              next == null || date.compareTo(next) < 0 ? date : next,
        );
    final newCount = ready
        .where((entry) => entry.stage == Stage.newStage)
        .length;
    final familiarCount = ready
        .where((entry) => entry.stage == Stage.familiar)
        .length;
    final learnedCount = ready
        .where((entry) => entry.stage == Stage.learned)
        .length;
    final processingCount = entries
        .where((entry) => entry.status == EntryStatus.pending)
        .length;
    final failedCount = entries
        .where((entry) => entry.status == EntryStatus.failed)
        .length;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onStartPractice,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: onStartPractice == null
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.reviewDueCount(dueCount)} · ${upcoming == null ? l10n.reviewNoneUpcoming : l10n.reviewNext(upcoming)}',
                    ),
                    Text(
                      l10n.reviewProgress(
                        newCount,
                        familiarCount,
                        learnedCount,
                      ),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (processingCount > 0)
                      Text(l10n.reviewProcessingCount(processingCount)),
                    if (failedCount > 0)
                      Text(l10n.reviewFailedCount(failedCount)),
                  ],
                ),
              ),
              if (onStartPractice != null) const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
