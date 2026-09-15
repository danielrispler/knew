import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:knew/src/core/l10n/l10n.dart';
import '../../vocabulary/data/export_import_service.dart';
import '../../vocabulary/data/gemini_models.dart';
import '../../vocabulary/domain/gemini_lookup_result.dart';
import '../../vocabulary/presentation/vocabulary_providers.dart';
import 'settings_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _apiKeyController;
  late final TextEditingController _customModelController;
  bool _isTestingKey = false;
  bool _isCustomModelSelected = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    _customModelController = TextEditingController();
    final settingsState = ref.read(settingsProvider).value;
    if (settingsState != null) {
      _apiKeyController.text = settingsState.apiKey;
      if (!GeminiModels.availableModels.contains(settingsState.model)) {
        _isCustomModelSelected = true;
        _customModelController.text = settingsState.model;
      }
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600.0),
              child: settingsAsync.when(
                data: (settings) {
                  if (_apiKeyController.text != settings.apiKey) {
                    _apiKeyController.text = settings.apiKey;
                  }

                  final isKnownPreset = GeminiModels.availableModels.contains(settings.model);
                  final dropdownValue = _isCustomModelSelected || !isKnownPreset
                      ? 'custom'
                      : settings.model;

                  if (_isCustomModelSelected &&
                      _customModelController.text != settings.model &&
                      !isKnownPreset) {
                    _customModelController.text = settings.model;
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        l10n.practiceDefaults,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.sessionSize),
                        subtitle: Text(l10n.entriesPerSession(settings.sessionSize)),
                        trailing: SizedBox(
                          width: 150,
                          child: Slider(
                            value: settings.sessionSize.toDouble(),
                            min: 1,
                            max: 100,
                            divisions: 99,
                            label: '${settings.sessionSize}',
                            onChanged: (val) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setSessionSize(val.round());
                            },
                          ),
                        ),
                      ),
                      const Divider(height: 32),
                      Text(
                        l10n.appearance,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'system', label: Text(l10n.themeSystem)),
                          ButtonSegment(value: 'light', label: Text(l10n.themeLight)),
                          ButtonSegment(value: 'dark', label: Text(l10n.themeDark)),
                        ],
                        selected: {settings.theme},
                        onSelectionChanged: (newSelection) {
                          ref
                              .read(settingsProvider.notifier)
                              .setTheme(newSelection.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.appLanguage,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: [
                          ButtonSegment(value: 'system', label: Text(l10n.languageSystem)),
                          ButtonSegment(value: 'en', label: Text(l10n.languageEnglish)),
                          ButtonSegment(value: 'he', label: Text(l10n.languageHebrew)),
                        ],
                        selected: {settings.language},
                        onSelectionChanged: (newSelection) {
                          ref
                              .read(settingsProvider.notifier)
                              .setLanguage(newSelection.first);
                        },
                      ),
                      const Divider(height: 32),
                      Text(
                        l10n.geminiSettings,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _showModelPickerBottomSheet(context, dropdownValue, settings.model),
                        borderRadius: BorderRadius.circular(4),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.primaryModelChoice,
                            helperText: l10n.modelFallbackHelper,
                            border: const OutlineInputBorder(),
                            suffixIcon: const Icon(Icons.arrow_drop_down),
                          ),
                          child: Text(
                            _getModelDisplayTitle(dropdownValue, settings.model),
                            style: Theme.of(context).textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      if (_isCustomModelSelected || dropdownValue == 'custom') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customModelController,
                          decoration: InputDecoration(
                            labelText: l10n.customModelName,
                            hintText: l10n.customModelHint,
                            helperText: l10n.customModelHelper,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () {
                                final customVal = _customModelController.text.trim();
                                if (customVal.isNotEmpty) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setModel(customVal);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Custom model set to: $customVal')),
                                  );
                                }
                              },
                            ),
                          ),
                          onChanged: (val) {
                            final trimmed = val.trim();
                            if (trimmed.isNotEmpty) {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setModel(trimmed);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: l10n.geminiApiKey,
                          hintText: l10n.apiKeyHint,
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setApiKey(_apiKeyController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(l10n.apiKeySaved)),
                              );
                            },
                          ),
                        ),
                        onChanged: (val) {
                          ref.read(settingsProvider.notifier).setApiKey(val);
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _isTestingKey
                            ? null
                            : () async {
                                final key = _apiKeyController.text.trim();
                                if (key.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Add your Gemini API key in Settings, or enter the word manually.'),
                                    ),
                                  );
                                  return;
                                }
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() {
                                  _isTestingKey = true;
                                });
                                try {
                                  final currentModel = settings.model;
                                  final client = ref.read(geminiClientProvider);
                                  await client.testConnection(
                                    apiKey: key,
                                    model: currentModel,
                                  );
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(l10n.connectionSuccessful),
                                      ),
                                    );
                                  }
                                } on GeminiException catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text(e.message)),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    messenger.showSnackBar(
                                      SnackBar(content: Text('Connection error: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      _isTestingKey = false;
                                    });
                                  }
                                }
                              },
                        icon: _isTestingKey
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bolt),
                        label: Text(l10n.testKeyConnection),
                      ),
                      const Divider(height: 32),
                      Text(
                        l10n.dataBackup,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.dataBackupDesc,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 12),
                      LayoutBuilder(
                        builder: (context, buttonConstraints) {
                          final isNarrow = buttonConstraints.maxWidth < 340;
                          if (isNarrow) {
                            return Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: () => ExportImportService.exportData(context, ref),
                                    icon: const Icon(Icons.file_upload_outlined),
                                    label: Text(l10n.exportBackup),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () => ExportImportService.importData(context, ref),
                                    icon: const Icon(Icons.file_download_outlined),
                                    label: Text(l10n.importBackup),
                                    style: ElevatedButton.styleFrom(
                                      minimumSize: const Size.fromHeight(48),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }
                          return Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => ExportImportService.exportData(context, ref),
                                  icon: const Icon(Icons.file_upload_outlined),
                                  label: Text(l10n.exportBackup),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () => ExportImportService.importData(context, ref),
                                  icon: const Icon(Icons.file_download_outlined),
                                  label: Text(l10n.importBackup),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(48),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error loading settings: $err')),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getModelDisplayTitle(String dropdownValue, String activeModel) {
    switch (dropdownValue) {
      case GeminiModels.gemini38Flash:
        return 'Gemini 3.8 Flash (Default - Strongest)';
      case GeminiModels.gemini37Flash:
        return 'Gemini 3.7 Flash';
      case GeminiModels.gemini36Flash:
        return 'Gemini 3.6 Flash';
      case GeminiModels.gemini35Flash:
        return 'Gemini 3.5 Flash';
      case GeminiModels.gemini35FlashLite:
        return 'Gemini 3.5 Flash Lite';
      case 'custom':
        return activeModel.isNotEmpty ? 'Custom: $activeModel' : 'Custom Model...';
      default:
        return activeModel;
    }
  }

  void _showModelPickerBottomSheet(
      BuildContext context, String currentDropdownValue, String activeModel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final models = [
          {
            'val': GeminiModels.gemini38Flash,
            'title': 'Gemini 3.8 Flash',
            'subtitle': 'Default - Strongest model'
          },
          {
            'val': GeminiModels.gemini37Flash,
            'title': 'Gemini 3.7 Flash',
            'subtitle': 'High performance model'
          },
          {
            'val': GeminiModels.gemini36Flash,
            'title': 'Gemini 3.6 Flash',
            'subtitle': 'Fast & capable model'
          },
          {
            'val': GeminiModels.gemini35Flash,
            'title': 'Gemini 3.5 Flash',
            'subtitle': 'Balanced standard model'
          },
          {
            'val': GeminiModels.gemini35FlashLite,
            'title': 'Gemini 3.5 Flash Lite',
            'subtitle': 'Lightweight fast fallback'
          },
          {
            'val': 'custom',
            'title': 'Custom Model...',
            'subtitle': 'Specify custom model identifier'
          },
        ];

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Theme.of(sheetContext)
                          .colorScheme
                          .outline
                          .withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Select Gemini Model',
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Primary choice for automated lookups. Automatically falls back if rate-limited.',
                  style: Theme.of(sheetContext).textTheme.bodySmall?.copyWith(
                        color: Theme.of(sheetContext).colorScheme.outline,
                      ),
                ),
                const SizedBox(height: 16),
                ...models.map((m) {
                  final value = m['val']!;
                  final isSelected = currentDropdownValue == value;
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isSelected
                        ? Theme.of(sheetContext)
                            .colorScheme
                            .primaryContainer
                            .withOpacity(0.4)
                        : Theme.of(sheetContext)
                            .colorScheme
                            .surfaceContainerLowest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? Theme.of(sheetContext).colorScheme.primary
                            : Theme.of(sheetContext).colorScheme.outlineVariant,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        if (value == 'custom') {
                          setState(() {
                            _isCustomModelSelected = true;
                          });
                          final customVal = _customModelController.text.trim();
                          if (customVal.isNotEmpty) {
                            ref
                                .read(settingsProvider.notifier)
                                .setModel(customVal);
                          }
                        } else {
                          setState(() {
                            _isCustomModelSelected = false;
                          });
                          ref.read(settingsProvider.notifier).setModel(value);
                        }
                      },
                      leading: Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: isSelected
                            ? Theme.of(sheetContext).colorScheme.primary
                            : Theme.of(sheetContext).colorScheme.outline,
                      ),
                      title: Text(
                        m['title']!,
                        style: TextStyle(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(m['subtitle']!),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
