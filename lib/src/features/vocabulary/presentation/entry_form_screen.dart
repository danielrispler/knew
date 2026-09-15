import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../settings/presentation/settings_providers.dart';
import '../../settings/presentation/settings_screen.dart';
import '../data/words_repository.dart';
import '../domain/entry.dart';
import '../domain/gemini_lookup_result.dart';
import '../domain/meaning.dart';
import 'vocabulary_providers.dart';

class MeaningFormData {
  final TextEditingController posController;
  final TextEditingController definitionController;
  final List<TextEditingController> translationControllers;

  MeaningFormData({
    required String partOfSpeech,
    required String definition,
    required List<String> translations,
  })  : posController = TextEditingController(text: partOfSpeech),
        definitionController = TextEditingController(text: definition),
        translationControllers = translations
            .map((t) => TextEditingController(text: t))
            .toList() {
    if (translationControllers.isEmpty) {
      translationControllers.add(TextEditingController());
    }
  }

  void dispose() {
    posController.dispose();
    definitionController.dispose();
    for (var c in translationControllers) {
      c.dispose();
    }
  }

  Meaning? toMeaning() {
    final pos = posController.text.trim();
    final def = definitionController.text.trim();
    final transList = translationControllers
        .map((c) => c.text.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    if (pos.isEmpty || def.isEmpty || transList.isEmpty) return null;
    return Meaning(
      partOfSpeech: pos,
      definition: def,
      hebrewTranslations: transList,
    );
  }
}

class EntryFormScreen extends ConsumerStatefulWidget {
  final Entry? initialEntry;

  const EntryFormScreen({super.key, this.initialEntry});

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _termController;
  late final TextEditingController _sourceController;
  late final TextEditingController _contextController;
  late final TextEditingController _lookupController;
  final List<MeaningFormData> _meaningsData = [];

  String? _duplicateError;
  String? _duplicateEntryId;
  bool _isSaving = false;

  bool _isLookingUp = false;
  String? _lookupError;
  String? _lookupSuggestion;
  List<String> _englishAlternatives = [];
  String? _selectedAlternative;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _termController = TextEditingController(text: entry?.english ?? '');
    _sourceController = TextEditingController(text: entry?.source ?? '');
    _contextController = TextEditingController(text: entry?.context ?? '');
    _lookupController = TextEditingController();

    if (entry != null && entry.meanings.isNotEmpty) {
      for (var m in entry.meanings) {
        _meaningsData.add(MeaningFormData(
          partOfSpeech: m.partOfSpeech,
          definition: m.definition,
          translations: m.hebrewTranslations,
        ));
      }
    } else {
      _meaningsData.add(MeaningFormData(
        partOfSpeech: '',
        definition: '',
        translations: [''],
      ));
    }
  }

  @override
  void dispose() {
    _termController.dispose();
    _sourceController.dispose();
    _contextController.dispose();
    _lookupController.dispose();
    for (var m in _meaningsData) {
      m.dispose();
    }
    super.dispose();
  }

  Future<void> _performLookup({String? inputOverride}) async {
    final rawInput = inputOverride ?? _lookupController.text;
    final input = rawInput.trim();
    if (input.isEmpty) {
      setState(() {
        _lookupError = 'Please enter an English term or Hebrew word to look up.';
      });
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
      _lookupSuggestion = null;
      _englishAlternatives = [];
      _selectedAlternative = null;
    });

    final settings = await ref.read(settingsProvider.future);
    final apiKey = settings.apiKey;
    final model = settings.model;
    final client = ref.read(geminiClientProvider);

    try {
      final result = await client.lookupWithFallback(
        input: input,
        apiKey: apiKey,
        primaryModel: model,
      );

      if (!mounted) return;

      if (result is GeminiSuccessResult) {
        setState(() {
          _termController.text = result.english;
          if (result.englishAlternatives.isNotEmpty) {
            _englishAlternatives = [result.english, ...result.englishAlternatives];
            _selectedAlternative = result.english;
          }

          for (var mData in _meaningsData) {
            mData.dispose();
          }
          _meaningsData.clear();

          for (var m in result.meanings) {
            _meaningsData.add(MeaningFormData(
              partOfSpeech: m.partOfSpeech,
              definition: m.definition,
              translations: m.hebrewTranslations,
            ));
          }

          _isLookingUp = false;
        });

        await _checkDuplicate();
      } else if (result is GeminiInvalidResult) {
        setState(() {
          _isLookingUp = false;
          _lookupSuggestion = result.suggestion;
          if (result.suggestion != null) {
            _lookupError = 'Word "$input" not recognized. Did you mean "${result.suggestion}"?';
          } else {
            _lookupError = 'No suggestion found for "$input". Try another spelling or enter the word manually.';
          }
        });
      }
    } on GeminiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookupError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookupError = 'Lookup failed: $e. Try again or enter the word manually.';
      });
    }
  }

  Future<void> _checkDuplicate() async {
    final term = _termController.text.trim();
    if (term.isEmpty) {
      setState(() {
        _duplicateError = null;
        _duplicateEntryId = null;
      });
      return;
    }

    final repository = ref.read(wordsRepositoryProvider);
    final existing = await repository.getEntryByEnglishKey(term);

    if (existing != null && existing.id != widget.initialEntry?.id) {
      setState(() {
        _duplicateError = 'Term "${existing.english}" already exists in library.';
        _duplicateEntryId = existing.id;
      });
    } else {
      setState(() {
        _duplicateError = null;
        _duplicateEntryId = null;
      });
    }
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    await _checkDuplicate();
    if (!mounted) return;
    if (_duplicateError != null) return;

    final meanings = <Meaning>[];
    for (var mData in _meaningsData) {
      final meaning = mData.toMeaning();
      if (meaning != null) {
        meanings.add(meaning);
      }
    }

    if (meanings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least one valid meaning with part of speech, definition, and Hebrew translation.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(wordsRepositoryProvider);
      if (widget.initialEntry != null) {
        final updated = widget.initialEntry!.copyWith(
          english: _termController.text,
          meanings: meanings,
          source: _sourceController.text,
          context: _contextController.text,
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        await repository.updateEntry(updated);
      } else {
        final newEntry = Entry.create(
          english: _termController.text,
          meanings: meanings,
          source: _sourceController.text,
          context: _contextController.text,
        );
        await repository.insertEntry(newEntry);
      }

      await ref.read(vocabularyListProvider.notifier).refreshList();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DuplicateEntryException catch (e) {
      setState(() {
        _duplicateError = 'Term already exists in library.';
        _duplicateEntryId = e.existingId;
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving entry: $e')),
        );
      }
    }
  }

  Future<void> _openExistingEntry() async {
    if (_duplicateEntryId == null) return;
    final repository = ref.read(wordsRepositoryProvider);
    final existingEntry = await repository.getEntryById(_duplicateEntryId!);
    if (existingEntry != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EntryFormScreen(initialEntry: existingEntry),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEntry != null;
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? l10n.editTermTitle : l10n.addTermTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: l10n.save,
            onPressed: _isSaving ? null : _saveEntry,
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600.0),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isEditing) ...[
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.auto_awesome,
                                            color: Theme.of(context).colorScheme.primary,
                                            size: 22,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Gemini Assisted Lookup',
                                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: Theme.of(context).colorScheme.primary,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              key: const Key('lookup_field'),
                                              controller: _lookupController,
                                              decoration: InputDecoration(
                                                hintText: 'Lookup English term or Hebrew word...',
                                                isDense: true,
                                                suffixIcon: _lookupController.text.isNotEmpty
                                                    ? IconButton(
                                                        icon: const Icon(Icons.clear, size: 18),
                                                        onPressed: () {
                                                          setState(() {
                                                            _lookupController.clear();
                                                            _lookupError = null;
                                                            _lookupSuggestion = null;
                                                          });
                                                        },
                                                      )
                                                    : null,
                                              ),
                                              onSubmitted: (_) => _performLookup(),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          FilledButton.icon(
                                            key: const Key('lookup_button'),
                                            onPressed: _isLookingUp ? null : () => _performLookup(),
                                            icon: _isLookingUp
                                                ? const SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  )
                                                : const Icon(Icons.search, size: 18),
                                            label: const Text('Look up'),
                                            style: FilledButton.styleFrom(
                                              minimumSize: const Size(100, 52),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_lookupError != null) ...[
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Theme.of(context).colorScheme.error),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error, size: 18),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _lookupError!,
                                                      style: TextStyle(
                                                        color: Theme.of(context).colorScheme.onErrorContainer,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (_lookupSuggestion != null) ...[
                                                const SizedBox(height: 8),
                                                FilledButton.icon(
                                                  onPressed: () {
                                                    _lookupController.text = _lookupSuggestion!;
                                                    _performLookup(inputOverride: _lookupSuggestion);
                                                  },
                                                  icon: const Icon(Icons.check, size: 16),
                                                  label: Text('Use "$_lookupSuggestion"'),
                                                ),
                                              ],
                                              if (_lookupError!.contains('API key')) ...[
                                                const SizedBox(height: 8),
                                                OutlinedButton.icon(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.settings, size: 16),
                                                  label: const Text('Open Settings'),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      ],
                                      if (_englishAlternatives.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          'Select English term:',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: _englishAlternatives.map((alt) {
                                            final isSelected = _selectedAlternative == alt;
                                            return ChoiceChip(
                                              label: Text(alt),
                                              selected: isSelected,
                                              onSelected: (selected) {
                                                if (selected) {
                                                  setState(() {
                                                    _selectedAlternative = alt;
                                                    _termController.text = alt;
                                                  });
                                                  _checkDuplicate();
                                                }
                                              },
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              controller: _termController,
                              decoration: InputDecoration(
                                labelText: 'English Term *',
                                hintText: 'e.g. persistent, put up with',
                                errorText: _duplicateError,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter an English term';
                                }
                                return null;
                              },
                              onChanged: (_) {
                                if (_duplicateError != null) {
                                  _checkDuplicate();
                                }
                              },
                            ),
                            if (_duplicateEntryId != null) ...[
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _openExistingEntry,
                                icon: const Icon(Icons.open_in_new),
                                label: const Text('View / Edit Existing Entry'),
                              ),
                            ],
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _sourceController,
                              decoration: const InputDecoration(
                                labelText: 'Source (Optional)',
                                hintText: 'e.g. Book title, article',
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _contextController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Context (Optional)',
                                hintText: 'Sentence or example usage',
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Meanings (${_meaningsData.length}/3)',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                if (_meaningsData.length < 3)
                                  TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _meaningsData.add(MeaningFormData(
                                          partOfSpeech: '',
                                          definition: '',
                                          translations: [''],
                                        ));
                                      });
                                    },
                                    icon: const Icon(Icons.add),
                                    label: const Text('Add Meaning'),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            ..._meaningsData.asMap().entries.map((entry) {
                              final index = entry.key;
                              final mData = entry.value;

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Meaning #${index + 1}',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          if (_meaningsData.length > 1)
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                              onPressed: () {
                                                setState(() {
                                                  _meaningsData.removeAt(index).dispose();
                                                });
                                              },
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: mData.posController,
                                        decoration: const InputDecoration(
                                          labelText: 'Part of Speech *',
                                          hintText: 'e.g. noun, verb, adjective',
                                        ),
                                        validator: (val) =>
                                            (val == null || val.trim().isEmpty) ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: mData.definitionController,
                                        decoration: const InputDecoration(
                                          labelText: 'English Definition *',
                                          hintText: 'Simple explanation',
                                        ),
                                        validator: (val) =>
                                            (val == null || val.trim().isEmpty) ? 'Required' : null,
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Hebrew Translations (RTL)',
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      ...mData.translationControllers.asMap().entries.map((tEntry) {
                                        final tIndex = tEntry.key;
                                        final tController = tEntry.value;

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 8.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Directionality(
                                                  textDirection: TextDirection.rtl,
                                                  child: TextFormField(
                                                    controller: tController,
                                                    textDirection: TextDirection.rtl,
                                                    decoration: const InputDecoration(
                                                      hintText: 'תרגום בעברית',
                                                    ),
                                                    validator: (val) =>
                                                        (val == null || val.trim().isEmpty)
                                                            ? 'Required'
                                                            : null,
                                                  ),
                                                ),
                                              ),
                                              if (mData.translationControllers.length > 1)
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline),
                                                  onPressed: () {
                                                    setState(() {
                                                      mData.translationControllers.removeAt(tIndex).dispose();
                                                    });
                                                  },
                                                ),
                                            ],
                                          ),
                                        );
                                      }),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () {
                                            setState(() {
                                              mData.translationControllers.add(TextEditingController());
                                            });
                                          },
                                          icon: const Icon(Icons.add, size: 18),
                                          label: const Text('Add Translation'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: _isSaving ? null : _saveEntry,
                                child: Text(isEditing ? 'Save Changes' : 'Create Entry'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
