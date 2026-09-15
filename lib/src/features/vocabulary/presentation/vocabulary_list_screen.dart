import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../settings/presentation/settings_screen.dart';
import '../domain/entry.dart';
import '../../practice/presentation/flashcard_practice_screen.dart';
import 'entry_form_screen.dart';
import 'vocabulary_providers.dart';

class VocabularyListScreen extends ConsumerStatefulWidget {
  const VocabularyListScreen({super.key});

  @override
  ConsumerState<VocabularyListScreen> createState() => _VocabularyListScreenState();
}

class _VocabularyListScreenState extends ConsumerState<VocabularyListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  String _stageLabel(Stage stage) {
    switch (stage) {
      case Stage.newStage:
        return 'New';
      case Stage.familiar:
        return 'Familiar';
      case Stage.learned:
        return 'Learned';
    }
  }

  List<Entry> _filterEntries(List<Entry> entries) {
    if (_searchQuery.trim().isEmpty) return entries;
    final query = _searchQuery.trim().toLowerCase();

    return entries.where((entry) {
      if (entry.englishKey.contains(query)) return true;
      for (var meaning in entry.meanings) {
        if (meaning.partOfSpeech.toLowerCase().contains(query)) return true;
        if (meaning.definition.toLowerCase().contains(query)) return true;
        for (var trans in meaning.hebrewTranslations) {
          if (trans.contains(query)) return true;
        }
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final vocabularyAsync = ref.watch(vocabularyListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'knew',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.school_outlined),
            tooltip: 'Practice',
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
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const EntryFormScreen()),
          );
        },
        tooltip: 'Add Entry',
        child: const Icon(Icons.add),
      ),
      body: vocabularyAsync.when(
        data: (entries) {
          final filtered = _filterEntries(entries);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search term, translation, definition...',
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
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.book_outlined,
                              size: 64,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching entries found.'
                                  : 'No vocabulary entries saved yet.\nTap + to add your first term.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final entry = filtered[index];
                          final primaryMeaning =
                              entry.meanings.isNotEmpty ? entry.meanings.first : null;
                          final hebrewSummary = primaryMeaning != null
                              ? primaryMeaning.hebrewTranslations.join(', ')
                              : '';

                          return Dismissible(
                            key: Key(entry.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            confirmDismiss: (direction) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Entry?'),
                                  content: Text('Are you sure you want to delete "${entry.english}"?'),
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
                            },
                            onDismissed: (_) {
                              ref.read(vocabularyListProvider.notifier).deleteEntry(entry.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Deleted "${entry.english}"')),
                              );
                            },
                            child: Card(
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        entry.english,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _stageColor(entry.stage).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _stageColor(entry.stage),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _stageLabel(entry.stage),
                                        style: TextStyle(
                                          color: _stageColor(entry.stage),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    if (primaryMeaning != null) ...[
                                      Text(
                                        '[${primaryMeaning.partOfSpeech}] ${primaryMeaning.definition}',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    Directionality(
                                      textDirection: TextDirection.rtl,
                                      child: Text(
                                        hebrewSummary,
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EntryFormScreen(initialEntry: entry),
                                    ),
                                  );
                                },
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
    );
  }
}
