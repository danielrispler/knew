import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../practice/data/tts_service.dart';
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
  }) : posController = TextEditingController(text: partOfSpeech),
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
  final String? initialTerm;
  final Future<void> Function(Entry savedEntry)? onSaved;
  final TtsService? ttsService;

  const EntryFormScreen({
    super.key,
    this.initialEntry,
    this.initialTerm,
    this.onSaved,
    this.ttsService,
  });

  @override
  ConsumerState<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends ConsumerState<EntryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _termController;
  late final TextEditingController _sourceController;
  late final TextEditingController _contextController;
  final List<MeaningFormData> _meaningsData = [];

  late final TtsService _ttsService;
  bool _isPlayingAudio = false;

  int _lookupRequestId = 0;
  bool _isLookingUp = false;
  GeminiSuccessResult? _lookupResult;
  String? _lookupError;
  String? _lookupSuggestion;
  List<String> _englishAlternatives = [];
  String? _selectedAlternative;
  int _selectedSenseIndex = 0;
  final Map<int, Set<String>> _selectedTranslationsPerSense = {};

  bool _isDrawerExpanded = false;
  String? _duplicateError;
  String? _duplicateEntryId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _ttsService = widget.ttsService ?? TtsService();
    _ttsService.init();

    final entry = widget.initialEntry;
    _termController = TextEditingController(
      text: entry?.english ?? widget.initialTerm ?? '',
    );
    _sourceController = TextEditingController(text: entry?.source ?? '');
    _contextController = TextEditingController(text: entry?.context ?? '');

    if (entry != null && entry.meanings.isNotEmpty) {
      for (var m in entry.meanings) {
        _meaningsData.add(
          MeaningFormData(
            partOfSpeech: m.partOfSpeech,
            definition: m.definition,
            translations: m.hebrewTranslations,
          ),
        );
      }
      final hasCustomMetadata =
          (entry.source != null && entry.source!.trim().isNotEmpty) ||
          (entry.context != null && entry.context!.trim().isNotEmpty) ||
          entry.meanings.length > 1;
      _isDrawerExpanded = hasCustomMetadata;
    } else {
      _meaningsData.add(
        MeaningFormData(partOfSpeech: '', definition: '', translations: ['']),
      );
      _isDrawerExpanded = false;
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

  bool _isHebrew(String text) {
    return RegExp(r'[\u05D0-\u05EA]').hasMatch(text);
  }

  void _onTermChanged(String text) {
    if (_duplicateError != null) {
      _checkDuplicate();
    }
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      setState(() {
        _lookupResult = null;
        _lookupError = null;
        _lookupSuggestion = null;
        _englishAlternatives = [];
        _selectedAlternative = null;
      });
      return;
    }
  }

  void _clearTerm() {
    _termController.clear();
    setState(() {
      _lookupResult = null;
      _lookupError = null;
      _lookupSuggestion = null;
      _englishAlternatives = [];
      _selectedAlternative = null;
      _selectedTranslationsPerSense.clear();
      _selectedSenseIndex = 0;
      _duplicateError = null;
      _duplicateEntryId = null;
      _isLookingUp = false;
      for (var m in _meaningsData) {
        m.dispose();
      }
      _meaningsData.clear();
      _meaningsData.add(
        MeaningFormData(partOfSpeech: '', definition: '', translations: ['']),
      );
    });
  }

  Future<void> _performLookup({String? termOverride}) async {
    final input = (termOverride ?? _termController.text).trim();
    if (input.isEmpty) return;

    final currentRequestId = ++_lookupRequestId;

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

      if (!mounted || currentRequestId != _lookupRequestId) return;

      if (result is GeminiSuccessResult) {
        setState(() {
          _isLookingUp = false;
          _lookupResult = result;
          _selectedSenseIndex = 0;
          _selectedTranslationsPerSense.clear();

          for (var i = 0; i < result.meanings.length; i++) {
            final m = result.meanings[i];
            _selectedTranslationsPerSense[i] = {
              if (m.hebrewTranslations.isNotEmpty) m.hebrewTranslations.first,
            };
          }

          if (result.englishAlternatives.isNotEmpty) {
            _englishAlternatives = [
              result.english,
              ...result.englishAlternatives,
            ];
            _selectedAlternative = result.english;
          }

          if (result.english.isNotEmpty &&
              _termController.text != result.english) {
            _termController.text = result.english;
          }

          for (var mData in _meaningsData) {
            mData.dispose();
          }
          _meaningsData.clear();

          for (var i = 0; i < result.meanings.length; i++) {
            final m = result.meanings[i];
            final selectedForSense = _selectedTranslationsPerSense[i]!.toList();
            _meaningsData.add(
              MeaningFormData(
                partOfSpeech: m.partOfSpeech,
                definition: m.definition,
                translations: selectedForSense.isNotEmpty
                    ? selectedForSense
                    : m.hebrewTranslations,
              ),
            );
          }
        });

        await _checkDuplicate();
      } else if (result is GeminiInvalidResult) {
        setState(() {
          _isLookingUp = false;
          _lookupResult = null;
          _lookupSuggestion = result.suggestion;
          if (result.suggestion == null) {
            _lookupError =
                'No suggestion found for "$input". You can enter meanings manually below.';
            _isDrawerExpanded = true;
          }
        });
      }
    } on GeminiException catch (e) {
      if (!mounted || currentRequestId != _lookupRequestId) return;
      setState(() {
        _isLookingUp = false;
        _lookupResult = null;
        _lookupError = e.message;
        _isDrawerExpanded = true;
      });
    } catch (e) {
      if (!mounted || currentRequestId != _lookupRequestId) return;
      setState(() {
        _isLookingUp = false;
        _lookupResult = null;
        _lookupError =
            'Lookup failed: $e. Try again or enter the word manually.';
        _isDrawerExpanded = true;
      });
    }
  }

  void _toggleTranslationChip(int senseIndex, String translation) {
    setState(() {
      final currentSet =
          _selectedTranslationsPerSense[senseIndex] ?? <String>{};
      if (currentSet.contains(translation)) {
        if (currentSet.length > 1) {
          currentSet.remove(translation);
        }
      } else {
        currentSet.add(translation);
      }
      _selectedTranslationsPerSense[senseIndex] = currentSet;

      if (senseIndex < _meaningsData.length) {
        final mData = _meaningsData[senseIndex];
        for (var c in mData.translationControllers) {
          c.dispose();
        }
        mData.translationControllers.clear();
        for (var t in currentSet) {
          mData.translationControllers.add(TextEditingController(text: t));
        }
      }
    });
  }

  Future<void> _speakTerm(String term) async {
    setState(() => _isPlayingAudio = true);
    await _ttsService.speak(term);
    if (mounted) {
      setState(() => _isPlayingAudio = false);
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
        _duplicateError =
            'Term "${existing.english}" already exists in library.';
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
    final term = _termController.text.trim();
    if (term.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.quickCaptureEnglishRequired)),
      );
      return;
    }

    await _checkDuplicate();
    if (!mounted) return;
    if (_duplicateError != null) return;

    final meanings = <Meaning>[];
    if (_lookupResult != null && !_isDrawerExpanded) {
      for (var mData in _meaningsData) {
        final m = mData.toMeaning();
        if (m != null) meanings.add(m);
      }
    } else {
      if (!_formKey.currentState!.validate()) return;
      for (var mData in _meaningsData) {
        final m = mData.toMeaning();
        if (m != null) meanings.add(m);
      }
    }

    if (meanings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please provide at least one valid meaning with part of speech, definition, and Hebrew translation.',
          ),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(wordsRepositoryProvider);
      if (widget.initialEntry != null) {
        final updated = widget.initialEntry!.copyWith(
          english: term,
          meanings: meanings,
          source: _sourceController.text.trim(),
          context: _contextController.text.trim(),
          updatedAt: DateTime.now().toUtc().toIso8601String(),
        );
        final saved = await repository.updateSemanticEntry(
          widget.initialEntry!,
          updated,
        );
        if (!saved) {
          throw Exception(
            'This entry changed elsewhere. Reload it before saving your edit.',
          );
        }
      } else {
        final newEntry = Entry.create(
          english: term,
          meanings: meanings,
          source: _sourceController.text.trim(),
          context: _contextController.text.trim(),
        );
        await repository.insertEntry(newEntry);
        await widget.onSaved?.call(newEntry);
      }

      await ref.read(vocabularyListProvider.notifier).refreshList();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.entrySaved(term))));
        Navigator.of(context).pop();
      }
    } on DuplicateEntryException catch (e) {
      setState(() {
        _duplicateError = 'Term already exists in library.';
        _duplicateEntryId = e.existingId;
        _isSaving = false;
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.entrySaveError('$e'))),
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

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEntry != null;
    if (!isEditing) {
      return _QuickCaptureScreen(
        initialTerm: widget.initialTerm,
        onSaved: widget.onSaved,
      );
    }
    final l10n = context.l10n;
    final isTermRtl = _isHebrew(_termController.text);

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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 16.0,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Hero Term Field
                            Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                key: const Key('hero_term_field'),
                                controller: _termController,
                                textDirection: isTermRtl
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                style: const TextStyle(
                                  fontFamily: 'FrankRuhlLibre',
                                  fontSize: 22,
                                  fontWeight: FontWeight.w600,
                                ),
                                textInputAction: TextInputAction.done,
                                decoration: InputDecoration(
                                  hintText:
                                      'Enter English term or Hebrew word...',
                                  hintStyle: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.normal,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                  ),
                                  filled: true,
                                  fillColor: Theme.of(
                                    context,
                                  ).colorScheme.surface,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.outlineVariant,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                  suffixIcon: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isLookingUp)
                                        const Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      else if (_termController.text.isNotEmpty)
                                        IconButton(
                                          key: const Key(
                                            'clear_hero_term_button',
                                          ),
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          tooltip: context.l10n.clearInput,
                                          onPressed: _clearTerm,
                                        ),
                                    ],
                                  ),
                                ),
                                onChanged: _onTermChanged,
                                onSubmitted: (_) {},
                              ),
                            ),

                            // Duplicate error banner
                            if (_duplicateError != null) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _duplicateError!,
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onErrorContainer,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    if (_duplicateEntryId != null)
                                      TextButton(
                                        onPressed: _openExistingEntry,
                                        child: Text(context.l10n.viewEntry),
                                      ),
                                  ],
                                ),
                              ),
                            ],

                            // Spelling Suggestion Chip
                            if (_lookupSuggestion != null) ...[
                              const SizedBox(height: 12),
                              ActionChip(
                                key: const Key('spelling_suggestion_chip'),
                                avatar: Icon(
                                  Icons.auto_fix_high,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                label: Text(
                                  'Did you mean "$_lookupSuggestion"?',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer
                                    .withValues(alpha: 0.4),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.3),
                                ),
                                onPressed: () {
                                  _termController.text = _lookupSuggestion!;
                                  _performLookup(
                                    termOverride: _lookupSuggestion,
                                  );
                                },
                              ),
                            ],

                            // Lookup Error Banner
                            if (_lookupError != null) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .errorContainer
                                      .withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.error.withValues(alpha: 0.6),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.error,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _lookupError!,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onErrorContainer,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (_lookupError!.contains('API key')) ...[
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          Navigator.of(context).push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  const SettingsScreen(),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.settings,
                                          size: 16,
                                        ),
                                        label: Text(context.l10n.openSettings),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],

                            // English Alternatives (for Hebrew inputs)
                            if (_englishAlternatives.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Select English term:',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: _englishAlternatives.map((alt) {
                                  final isSelected =
                                      _selectedAlternative == alt;
                                  return ChoiceChip(
                                    label: Text(alt),
                                    selected: isSelected,
                                    onSelected: (selected) {
                                      if (selected) {
                                        setState(() {
                                          _selectedAlternative = alt;
                                          _termController.text = alt;
                                        });
                                        _performLookup(termOverride: alt);
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ],

                            // 2. Instant AI Review Card
                            if (_lookupResult != null) ...[
                              const SizedBox(height: 16),
                              Card(
                                key: const Key('instant_ai_card'),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outlineVariant,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Card Header: Term, Pronunciation Speaker, POS badge
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    _lookupResult!.english,
                                                    style: const TextStyle(
                                                      fontFamily:
                                                          'FrankRuhlLibre',
                                                      fontSize: 22,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  icon: Icon(
                                                    _isPlayingAudio
                                                        ? Icons.volume_up
                                                        : Icons
                                                              .volume_up_outlined,
                                                    color: Theme.of(
                                                      context,
                                                    ).colorScheme.primary,
                                                    size: 22,
                                                  ),
                                                  tooltip:
                                                      'Listen to pronunciation',
                                                  onPressed: () => _speakTerm(
                                                    _lookupResult!.english,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (_lookupResult!
                                              .meanings
                                              .isNotEmpty)
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primaryContainer,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _lookupResult!
                                                    .meanings[_selectedSenseIndex]
                                                    .partOfSpeech
                                                    .toUpperCase(),
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),

                                      // Multi-sense switcher if >1 meaning
                                      if (_lookupResult!.meanings.length >
                                          1) ...[
                                        const SizedBox(height: 14),
                                        Wrap(
                                          key: const Key('sense_switcher'),
                                          spacing: 8,
                                          runSpacing: 6,
                                          children: _lookupResult!.meanings
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                                final idx = entry.key;
                                                final m = entry.value;
                                                final isSelected =
                                                    _selectedSenseIndex == idx;
                                                return ChoiceChip(
                                                  label: Text(
                                                    '${idx + 1}: ${_capitalize(m.partOfSpeech)}',
                                                  ),
                                                  selected: isSelected,
                                                  onSelected: (selected) {
                                                    if (selected) {
                                                      setState(() {
                                                        _selectedSenseIndex =
                                                            idx;
                                                      });
                                                    }
                                                  },
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ],

                                      // Hebrew translation chips (RTL)
                                      if (_lookupResult!
                                          .meanings
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Text(
                                          'Hebrew Translations',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: _lookupResult!
                                              .meanings[_selectedSenseIndex]
                                              .hebrewTranslations
                                              .map((trans) {
                                                final isSelected =
                                                    _selectedTranslationsPerSense[_selectedSenseIndex]
                                                        ?.contains(trans) ??
                                                    false;
                                                return Directionality(
                                                  textDirection:
                                                      TextDirection.rtl,
                                                  child: FilterChip(
                                                    label: Text(
                                                      trans,
                                                      textDirection:
                                                          TextDirection.rtl,
                                                      style: const TextStyle(
                                                        fontFamily:
                                                            'FrankRuhlLibre',
                                                        fontSize: 15,
                                                      ),
                                                    ),
                                                    selected: isSelected,
                                                    onSelected: (_) =>
                                                        _toggleTranslationChip(
                                                          _selectedSenseIndex,
                                                          trans,
                                                        ),
                                                  ),
                                                );
                                              })
                                              .toList(),
                                        ),
                                      ],

                                      // Formatted Definition Box
                                      if (_lookupResult!
                                          .meanings
                                          .isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        Container(
                                          key: const Key('ai_definition_box'),
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surfaceContainerHighest
                                                .withValues(alpha: 0.35),
                                            borderRadius:
                                                const BorderRadius.only(
                                                  topRight: Radius.circular(8),
                                                  bottomRight: Radius.circular(
                                                    8,
                                                  ),
                                                ),
                                            border: Border(
                                              left: BorderSide(
                                                color: Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                                width: 4,
                                              ),
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          child: Text(
                                            _lookupResult!
                                                .meanings[_selectedSenseIndex]
                                                .definition,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  height: 1.4,
                                                  color: Theme.of(
                                                    context,
                                                  ).colorScheme.onSurface,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 16),

                            // 3. Collapsible Custom Drawer
                            InkWell(
                              key: const Key('custom_drawer_header'),
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                setState(() {
                                  _isDrawerExpanded = !_isDrawerExpanded;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 4,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _isDrawerExpanded
                                          ? 'Need custom meaning or notes? ▴'
                                          : 'Need custom meaning or notes? ▾',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Icon(
                                      _isDrawerExpanded
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_isDrawerExpanded) ...[
                              const SizedBox(height: 8),
                              TextFormField(
                                key: const Key('source_field'),
                                controller: _sourceController,
                                decoration: const InputDecoration(
                                  labelText: 'Source (Optional)',
                                  hintText: 'e.g. Book title, article',
                                ),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('context_field'),
                                controller: _contextController,
                                maxLines: 2,
                                decoration: const InputDecoration(
                                  labelText: 'Context (Optional)',
                                  hintText: 'Sentence or example usage',
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                key: const Key('manual_meanings_section'),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Meanings (${_meaningsData.length}/3)',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                        if (_meaningsData.length < 3)
                                          TextButton.icon(
                                            onPressed: () {
                                              setState(() {
                                                _meaningsData.add(
                                                  MeaningFormData(
                                                    partOfSpeech: '',
                                                    definition: '',
                                                    translations: [''],
                                                  ),
                                                );
                                              });
                                            },
                                            icon: const Icon(
                                              Icons.add,
                                              size: 18,
                                            ),
                                            label: Text(
                                              context.l10n.addMeaning,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ..._meaningsData.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final mData = entry.value;

                                      return Card(
                                        margin: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Text(
                                                    'Meaning #${index + 1}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                  if (_meaningsData.length > 1)
                                                    IconButton(
                                                      icon: const Icon(
                                                        Icons.delete_outline,
                                                        color: Colors.redAccent,
                                                        size: 20,
                                                      ),
                                                      onPressed: () {
                                                        setState(() {
                                                          _meaningsData
                                                              .removeAt(index)
                                                              .dispose();
                                                        });
                                                      },
                                                    ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller: mData.posController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Part of Speech *',
                                                  hintText:
                                                      'e.g. noun, verb, adjective',
                                                ),
                                                validator: (val) =>
                                                    (val == null ||
                                                        val.trim().isEmpty)
                                                    ? 'Required'
                                                    : null,
                                              ),
                                              const SizedBox(height: 10),
                                              TextFormField(
                                                controller:
                                                    mData.definitionController,
                                                decoration:
                                                    const InputDecoration(
                                                      labelText:
                                                          'English Definition *',
                                                      hintText:
                                                          'Simple explanation',
                                                    ),
                                                validator: (val) =>
                                                    (val == null ||
                                                        val.trim().isEmpty)
                                                    ? 'Required'
                                                    : null,
                                              ),
                                              const SizedBox(height: 14),
                                              const Text(
                                                'Hebrew Translations (RTL)',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              ...mData.translationControllers.asMap().entries.map((
                                                tEntry,
                                              ) {
                                                final tIndex = tEntry.key;
                                                final tController =
                                                    tEntry.value;

                                                return Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        bottom: 8.0,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Expanded(
                                                        child: Directionality(
                                                          textDirection:
                                                              TextDirection.rtl,
                                                          child: TextFormField(
                                                            controller:
                                                                tController,
                                                            textDirection:
                                                                TextDirection
                                                                    .rtl,
                                                            decoration:
                                                                const InputDecoration(
                                                                  hintText:
                                                                      'תרגום בעברית',
                                                                ),
                                                            validator: (val) =>
                                                                (val == null ||
                                                                    val
                                                                        .trim()
                                                                        .isEmpty)
                                                                ? 'Required'
                                                                : null,
                                                          ),
                                                        ),
                                                      ),
                                                      if (mData
                                                              .translationControllers
                                                              .length >
                                                          1)
                                                        IconButton(
                                                          icon: const Icon(
                                                            Icons
                                                                .remove_circle_outline,
                                                            size: 20,
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              mData
                                                                  .translationControllers
                                                                  .removeAt(
                                                                    tIndex,
                                                                  )
                                                                  .dispose();
                                                            });
                                                          },
                                                        ),
                                                    ],
                                                  ),
                                                );
                                              }),
                                              Align(
                                                alignment:
                                                    Alignment.centerRight,
                                                child: TextButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      mData
                                                          .translationControllers
                                                          .add(
                                                            TextEditingController(),
                                                          );
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.add,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Add Translation',
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // 4. Primary Save Action Button
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                key: const Key('save_to_library_button'),
                                onPressed: _isSaving ? null : _saveEntry,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  isEditing
                                      ? 'Save Changes'
                                      : 'Save to Library',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
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

class _QuickCaptureScreen extends ConsumerStatefulWidget {
  const _QuickCaptureScreen({this.initialTerm, this.onSaved});
  final String? initialTerm;
  final Future<void> Function(Entry savedEntry)? onSaved;

  @override
  ConsumerState<_QuickCaptureScreen> createState() =>
      _QuickCaptureScreenState();
}

class _QuickCaptureScreenState extends ConsumerState<_QuickCaptureScreen> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTerm ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    final term = _controller.text.trim();
    if (!RegExp(r"^[A-Za-z]+(?:[ '-][A-Za-z]+)*$").hasMatch(term)) {
      setState(() => _error = context.l10n.quickCaptureEnglishRequired);
      return;
    }
    final repository = ref.read(wordsRepositoryProvider);
    if (await repository.existsEnglishKey(Entry.generateKey(term))) {
      setState(() => _error = context.l10n.quickCaptureDuplicate);
      return;
    }
    final entry = await ref.read(pendingEntryProvider).capture(term);
    await widget.onSaved?.call(entry);
    await ref.read(vocabularyListProvider.notifier).refreshList();
    _controller.clear();
    _focusNode.requestFocus();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(pendingEntryProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.quickCaptureTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              key: const Key('quick_capture_field'),
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: context.l10n.quickCaptureTermLabel,
                hintText: context.l10n.quickCaptureTermHint,
              ),
              onSubmitted: (_) => _add(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _add,
              child: Text(context.l10n.quickCaptureAdd),
            ),
            const SizedBox(height: 12),
            Text(
              queue.isRunning
                  ? context.l10n.quickCaptureProcessing
                  : context.l10n.quickCaptureWaiting,
            ),
          ],
        ),
      ),
    );
  }
}
