import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../vocabulary/data/export_import_service.dart';
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
  bool _isTestingKey = false;

  @override
  void initState() {
    super.initState();
    _apiKeyController = TextEditingController();
    final settingsState = ref.read(settingsProvider).value;
    if (settingsState != null) {
      _apiKeyController.text = settingsState.apiKey;
    }
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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

                  return ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      Text(
                        'Practice Defaults',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Session Size'),
                        subtitle: Text('${settings.sessionSize} entries per session'),
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
                        'Appearance',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'system', label: Text('System')),
                          ButtonSegment(value: 'light', label: Text('Light')),
                          ButtonSegment(value: 'dark', label: Text('Dark')),
                        ],
                        selected: {settings.theme},
                        onSelectionChanged: (newSelection) {
                          ref
                              .read(settingsProvider.notifier)
                              .setTheme(newSelection.first);
                        },
                      ),
                      const Divider(height: 32),
                      Text(
                        'Gemini Assisted Lookup Settings',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: settings.model,
                        decoration: const InputDecoration(
                          labelText: 'Model Choice',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'gemini-2.5-flash',
                            child: Text('gemini-2.5-flash (Default)'),
                          ),
                          DropdownMenuItem(
                            value: 'gemini-1.5-pro',
                            child: Text('gemini-1.5-pro'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            ref.read(settingsProvider.notifier).setModel(val);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _apiKeyController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Gemini API Key',
                          hintText: 'Paste API key here',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.save),
                            onPressed: () {
                              ref
                                  .read(settingsProvider.notifier)
                                  .setApiKey(_apiKeyController.text);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('API Key saved securely')),
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
                                      const SnackBar(
                                        content: Text(
                                            'Connection successful! Gemini API key is active.'),
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
                        label: const Text('Test Key Connection'),
                      ),
                      const Divider(height: 32),
                      Text(
                        'Data & Backup',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Export or import your vocabulary library and learning progress as a backup JSON file.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => ExportImportService.exportData(context, ref),
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Export Backup'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => ExportImportService.importData(context, ref),
                              icon: const Icon(Icons.download_for_offline),
                              label: const Text('Import Backup'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
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
}
