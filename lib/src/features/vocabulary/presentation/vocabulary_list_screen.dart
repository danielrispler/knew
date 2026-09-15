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

class VocabularyListScreen extends ConsumerStatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  ConsumerState<VocabularyListScreen> createState() => _VocabularyListScreenState();
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
      if (normalizeForSearch(entry.english).contains(normalizedQuery)) return true;
      if (normalizeForSearch(entry.englishKey).contains(normalizedQuery)) return true;

      for (var meaning in entry.meanings) {
        if (normalizeForSearch(meaning.partOfSpeech).contains(normalizedQuery)) return true;
        if (normalizeForSearch(meaning.definition).contains(normalizedQuery)) return true;

        for (var trans in meaning.hebrewTranslations) {
          if (normalizeForSearch(trans).contains(normalizedQuery)) return true;
        }
      }
      return false;
    }).toList();
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
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
            icon: const Icon(Icons.school_outlined),
            tooltip: l10n.practiceTitle,
            onPressed: () {
              final entries = vocabularyAsync.value ?? [];
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
            },
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
        label: Text(l10n.addTermTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600.0),
              child: vocabularyAsync.when(
                data: (entries) {
                  final filtered = _filterEntries(entries);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                          onChanged: (val) {
                            setState(() {
                              _searchQuery = val;
                            });
                          },
                        ),
                      ),

                      // Stage Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: Row(
                          children: [
                            FilterChip(
                              label: Text(l10n.filterAll),
                              selected: _selectedStageFilter == null,
                              onSelected: (_) {
                                setState(() => _selectedStageFilter = null);
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.stageNew,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(l10n.filterNew),
                                ],
                              ),
                              selected: _selectedStageFilter == Stage.newStage,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStageFilter = selected ? Stage.newStage : null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.stageFamiliar,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(l10n.filterFamiliar),
                                ],
                              ),
                              selected: _selectedStageFilter == Stage.familiar,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStageFilter = selected ? Stage.familiar : null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            FilterChip(
                              label: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.stageLearned,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(l10n.filterLearned),
                                ],
                              ),
                              selected: _selectedStageFilter == Stage.learned,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedStageFilter = selected ? Stage.learned : null;
                                });
                              },
                            ),
                          ],
                        ),
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
                                      _searchQuery.isNotEmpty || _selectedStageFilter != null
                                          ? Icons.search_off
                                          : Icons.book_outlined,
                                      size: 64,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _searchQuery.isNotEmpty || _selectedStageFilter != null
                                          ? l10n.noTermsFound
                                          : l10n.noTermsYet,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: Theme.of(context).colorScheme.outline,
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
                                  final primaryMeaning = entry.meanings.isNotEmpty
                                      ? entry.meanings.first
                                      : null;
                                  final hebrewSummary = primaryMeaning != null
                                      ? primaryMeaning.hebrewTranslations.join(', ')
                                      : '';

                                  return Dismissible(
                                    key: Key(entry.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent.withOpacity(0.9),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 24),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      return await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: Text(l10n.deleteTermConfirm),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(false),
                                              child: Text(l10n.cancel),
                                            ),
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.of(context).pop(true),
                                              style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red),
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
                                          showWordDetailBottomSheet(context, entry);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.center,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      entry.english,
                                                      style: const TextStyle(
                                                        fontFamily: 'FrankRuhlLibre',
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 20,
                                                        letterSpacing: -0.2,
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(
                                                        horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: _stageColor(entry.stage)
                                                          .withOpacity(0.15),
                                                      borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                                                        color: _stageColor(entry.stage),
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      _stageLabel(entry.stage, l10n),
                                                      style: TextStyle(
                                                        color: _stageColor(entry.stage),
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
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
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Directionality(
                                                    textDirection: TextDirection.rtl,
                                                    child: Text(
                                                      hebrewSummary,
                                                      textDirection: TextDirection.rtl,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.chevron_right,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
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
                error: (err, stack) => Center(child: Text('Error loading library: $err')),
              ),
            ),
          );
        },
      ),
    );
  }
}
