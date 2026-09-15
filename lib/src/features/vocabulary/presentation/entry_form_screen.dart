import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/words_repository.dart';
import '../domain/entry.dart';
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
  final List<MeaningFormData> _meaningsData = [];

  String? _duplicateError;
  String? _duplicateEntryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;
    _termController = TextEditingController(text: entry?.english ?? '');
    _sourceController = TextEditingController(text: entry?.source ?? '');
    _contextController = TextEditingController(text: entry?.context ?? '');

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
    for (var m in _meaningsData) {
      m.dispose();
    }
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _isSaving ? null : _saveEntry,
          ),
        ],
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _termController,
                      decoration: InputDecoration(
                        labelText: 'English Term *',
                        hintText: 'e.g. persistent, put up with',
                        border: const OutlineInputBorder(),
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
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contextController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Context (Optional)',
                        hintText: 'Sentence or example usage',
                        border: OutlineInputBorder(),
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
                    const SizedBox(height: 8),
                    ..._meaningsData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final mData = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Meaning #${index + 1}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (_meaningsData.length > 1)
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          _meaningsData.removeAt(index).dispose();
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: mData.posController,
                                decoration: const InputDecoration(
                                  labelText: 'Part of Speech *',
                                  hintText: 'e.g. noun, verb, adjective',
                                  border: OutlineInputBorder(),
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
                                  border: OutlineInputBorder(),
                                ),
                                validator: (val) =>
                                    (val == null || val.trim().isEmpty) ? 'Required' : null,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Hebrew Translations (RTL)',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              const SizedBox(height: 4),
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
                                            decoration: InputDecoration(
                                              hintText: 'תרגום בעברית',
                                              border: const OutlineInputBorder(),
                                              contentPadding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
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
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveEntry,
                        child: Text(isEditing ? 'Save Changes' : 'Create Entry'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
