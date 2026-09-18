import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/entry.dart';
import '../domain/meaning.dart';
import '../presentation/vocabulary_providers.dart';
import '../../discover/data/suggested_words_repository.dart';

class ExportImportException implements Exception {
  final String message;

  ExportImportException(this.message);

  @override
  String toString() => 'ExportImportException: $message';
}

class ExportImportService {
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MiB
  static const int maxEntriesCount = 10000;

  static final RegExp _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static final RegExp _dateRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Generates a pretty-printed JSON v1 payload representing the provided entries.
  static String generateExportPayload(
    List<Entry> entries, {
    Map<String, dynamic>? discovery,
  }) {
    if (entries.length > maxEntriesCount) {
      throw ExportImportException(
        'Library exceeds maximum export limit of $maxEntriesCount entries.',
      );
    }

    final nowUtc = DateTime.now().toUtc().toIso8601String();
    final wordsJson = entries.map((e) {
      return {
        'id': e.id,
        'english': e.english,
        'meanings': e.meanings.map((m) {
          return {
            'partOfSpeech': m.partOfSpeech,
            'hebrew': m.hebrewTranslations,
            'definition': m.definition,
          };
        }).toList(),
        'source': e.source,
        'context': e.context,
        'level': e.level,
        'dueDate': e.dueDate,
        'lastReviewedAt': e.lastReviewedAt,
        'timesCorrect': e.timesCorrect,
        'timesWrong': e.timesWrong,
        'createdAt': e.createdAt,
        'updatedAt': e.updatedAt,
      };
    }).toList();

    final payloadMap = {
      'version': 1,
      'exportedAt': nowUtc,
      'words': wordsJson,
      'discovery': ?discovery,
    };

    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(payloadMap);
  }

  /// Strictly validates and parses raw JSON bytes into a list of valid [Entry] instances.
  static List<Entry> validateAndParseImport(List<int> bytes) {
    if (bytes.length > maxFileSizeBytes) {
      throw ExportImportException(
        'File exceeds maximum allowed size of 10 MB (size: ${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB).',
      );
    }

    String rawContent;
    try {
      rawContent = utf8.decode(bytes);
    } catch (e) {
      throw ExportImportException('Failed to decode UTF-8 file content: $e');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(rawContent);
    } catch (e) {
      throw ExportImportException('Invalid JSON format: $e');
    }

    if (decoded is! Map<String, dynamic>) {
      throw ExportImportException('Backup file root must be a JSON object.');
    }

    final version = decoded['version'];
    if (version == null || version is! int) {
      throw ExportImportException('Missing or invalid backup version number.');
    }
    if (version != 1) {
      throw ExportImportException(
        'This backup needs a newer version of knew. Update the app and try again.',
      );
    }

    final exportedAt = decoded['exportedAt'];
    if (exportedAt is! String || DateTime.tryParse(exportedAt) == null) {
      throw ExportImportException('Missing or invalid exportedAt timestamp.');
    }

    final wordsRaw = decoded['words'];
    if (wordsRaw is! List) {
      throw ExportImportException('Backup "words" field must be an array.');
    }

    if (wordsRaw.length > maxEntriesCount) {
      throw ExportImportException(
        'Backup contains ${wordsRaw.length} entries, exceeding the maximum allowed $maxEntriesCount entries.',
      );
    }

    final List<Entry> parsedEntries = [];
    final Set<String> seenIds = {};
    final Set<String> seenEnglishKeys = {};

    for (int i = 0; i < wordsRaw.length; i++) {
      final item = wordsRaw[i];
      if (item is! Map<String, dynamic>) {
        throw ExportImportException('Entry at index $i is not a JSON object.');
      }

      // ID
      final id = item['id'];
      if (id is! String || !_uuidRegex.hasMatch(id)) {
        throw ExportImportException(
          'Entry at index $i has invalid UUID: "$id".',
        );
      }
      if (seenIds.contains(id)) {
        throw ExportImportException('Duplicate UUID "$id" found at index $i.');
      }
      seenIds.add(id);

      // English term
      final english = item['english'];
      if (english is! String || english.trim().isEmpty) {
        throw ExportImportException(
          'Entry at index $i has missing or empty English term.',
        );
      }
      final englishKey = Entry.generateKey(english);
      if (seenEnglishKeys.contains(englishKey)) {
        throw ExportImportException(
          'Duplicate term key "$englishKey" found at index $i.',
        );
      }
      seenEnglishKeys.add(englishKey);

      // Meanings
      final meaningsRaw = item['meanings'];
      if (meaningsRaw is! List ||
          meaningsRaw.isEmpty ||
          meaningsRaw.length > 3) {
        throw ExportImportException(
          'Entry "$english" (index $i) must have between 1 and 3 meanings.',
        );
      }

      final List<Meaning> parsedMeanings = [];
      for (int mIdx = 0; mIdx < meaningsRaw.length; mIdx++) {
        final m = meaningsRaw[mIdx];
        if (m is! Map<String, dynamic>) {
          throw ExportImportException(
            'Meaning $mIdx of entry "$english" (index $i) is not an object.',
          );
        }

        final pos = m['partOfSpeech'];
        if (pos is! String || pos.trim().isEmpty) {
          throw ExportImportException(
            'Meaning $mIdx of entry "$english" (index $i) has empty partOfSpeech.',
          );
        }

        final def = m['definition'];
        if (def is! String || def.trim().isEmpty) {
          throw ExportImportException(
            'Meaning $mIdx of entry "$english" (index $i) has empty definition.',
          );
        }

        final hebRaw = m['hebrew'];
        if (hebRaw is! List || hebRaw.isEmpty) {
          throw ExportImportException(
            'Meaning $mIdx of entry "$english" (index $i) has missing Hebrew translations.',
          );
        }

        final List<String> hebTranslations = [];
        for (final h in hebRaw) {
          if (h is! String || h.trim().isEmpty) {
            throw ExportImportException(
              'Meaning $mIdx of entry "$english" (index $i) has an empty Hebrew translation.',
            );
          }
          hebTranslations.add(h.trim());
        }

        parsedMeanings.add(
          Meaning(
            partOfSpeech: pos.trim(),
            hebrewTranslations: hebTranslations,
            definition: def.trim(),
          ),
        );
      }

      // Source / Context
      final source = item['source'] as String?;
      final context = item['context'] as String?;

      // Level
      final level = item['level'];
      if (level is! int || level < 0 || level > 6) {
        throw ExportImportException(
          'Entry "$english" (index $i) has invalid level: $level (must be 0-6).',
        );
      }

      // Due date validation
      final dueDate = item['dueDate'];
      if (dueDate is! String || !_dateRegex.hasMatch(dueDate)) {
        throw ExportImportException(
          'Entry "$english" (index $i) has invalid dueDate format: "$dueDate".',
        );
      }
      final dateParts = dueDate.split('-');
      final year = int.parse(dateParts[0]);
      final month = int.parse(dateParts[1]);
      final day = int.parse(dateParts[2]);
      final roundTripDate = DateTime(year, month, day);
      if (roundTripDate.year != year ||
          roundTripDate.month != month ||
          roundTripDate.day != day) {
        throw ExportImportException(
          'Entry "$english" (index $i) has invalid calendar date: "$dueDate".',
        );
      }

      // Counters
      final timesCorrect = item['timesCorrect'];
      if (timesCorrect is! int || timesCorrect < 0) {
        throw ExportImportException(
          'Entry "$english" (index $i) has invalid timesCorrect.',
        );
      }

      final timesWrong = item['timesWrong'];
      if (timesWrong is! int || timesWrong < 0) {
        throw ExportImportException(
          'Entry "$english" (index $i) has invalid timesWrong.',
        );
      }

      // Last reviewed at
      final lastReviewedAt = item['lastReviewedAt'] as String?;
      if (level == 0) {
        if (lastReviewedAt != null || timesCorrect != 0 || timesWrong != 0) {
          throw ExportImportException(
            'Unreviewed Level 0 entry "$english" (index $i) must have null lastReviewedAt and 0 counters.',
          );
        }
      } else {
        if (lastReviewedAt == null ||
            DateTime.tryParse(lastReviewedAt) == null) {
          throw ExportImportException(
            'Reviewed entry "$english" (index $i) requires valid lastReviewedAt timestamp.',
          );
        }
        if (timesCorrect + timesWrong < 1) {
          throw ExportImportException(
            'Reviewed entry "$english" (index $i) requires at least 1 total answer recorded.',
          );
        }
      }

      // Timestamps
      final createdAt = item['createdAt'];
      if (createdAt is! String || DateTime.tryParse(createdAt) == null) {
        throw ExportImportException(
          'Entry "$english" (index $i) missing valid createdAt.',
        );
      }

      final updatedAt = item['updatedAt'];
      if (updatedAt is! String || DateTime.tryParse(updatedAt) == null) {
        throw ExportImportException(
          'Entry "$english" (index $i) missing valid updatedAt.',
        );
      }

      final createdInst = DateTime.parse(createdAt).toUtc();
      final updatedInst = DateTime.parse(updatedAt).toUtc();
      if (updatedInst.isBefore(createdInst)) {
        throw ExportImportException(
          'Entry "$english" (index $i) updatedAt ($updatedAt) is before createdAt ($createdAt).',
        );
      }

      if (lastReviewedAt != null) {
        final lastRevInst = DateTime.parse(lastReviewedAt).toUtc();
        if (lastRevInst.isAfter(updatedInst)) {
          throw ExportImportException(
            'Entry "$english" (index $i) lastReviewedAt ($lastReviewedAt) is after updatedAt ($updatedAt).',
          );
        }
      }

      parsedEntries.add(
        Entry(
          id: id,
          english: english.trim(),
          englishKey: englishKey,
          meanings: parsedMeanings,
          source: (source != null && source.trim().isNotEmpty)
              ? source.trim()
              : null,
          context: (context != null && context.trim().isNotEmpty)
              ? context.trim()
              : null,
          level: level,
          dueDate: dueDate,
          lastReviewedAt: lastReviewedAt,
          timesCorrect: timesCorrect,
          timesWrong: timesWrong,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      );
    }

    return parsedEntries;
  }

  /// Parses the optional Discover data from a valid or legacy backup.
  static Map<String, dynamic>? parseDiscoveryImport(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, dynamic> || !decoded.containsKey('discovery')) {
      return null;
    }
    final discovery = decoded['discovery'];
    if (discovery is! Map<String, dynamic> ||
        discovery['bandCenter'] is! int ||
        discovery['known'] is! List ||
        discovery['learned'] is! List) {
      throw ExportImportException('Invalid discovery backup data.');
    }
    for (final status in ['known', 'learned']) {
      for (final record in discovery[status] as List) {
        if (record is! Map<String, dynamic> ||
            record['key'] is! String ||
            (record['key'] as String).isEmpty ||
            record['updatedAt'] is! String ||
            DateTime.tryParse(record['updatedAt'] as String) == null) {
          throw ExportImportException('Invalid discovery $status record.');
        }
      }
    }
    return discovery;
  }

  /// Triggers system share sheet to export all vocabulary entries.
  static Future<void> exportData(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(wordsRepositoryProvider);
      final entries = await repository.getAllEntries();
      final db = await ref.read(databaseProvider.future);
      final discovery = await SuggestedWordsRepository(db).exportHistory();

      if (entries.isEmpty &&
          discovery['known'].isEmpty &&
          discovery['learned'].isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No vocabulary entries to export.')),
          );
        }
        return;
      }

      final jsonPayload = generateExportPayload(entries, discovery: discovery);
      final bytes = utf8.encode(jsonPayload);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[:.]'), '-')
          .substring(0, 19);
      final fileName = 'knew-export-$timestamp.json';

      if (!context.mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      final sharePositionOrigin = box != null
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      final xFile = XFile.fromData(
        bytes,
        name: fileName,
        mimeType: 'application/json',
      );

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          subject: 'knew Vocabulary Backup',
          sharePositionOrigin: sharePositionOrigin,
        ),
      );

      if (result.status == ShareResultStatus.success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vocabulary backup shared successfully.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: ${e.toString()}')),
        );
      }
    }
  }

  /// Opens file picker, validates backup JSON, and merges into SQLite.
  static Future<void> importData(BuildContext context, WidgetRef ref) async {
    try {
      final pickedFile = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFile == null) {
        return; // User cancelled
      }

      final bytes = await pickedFile.readAsBytes();

      // Show progress dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => const Center(child: CircularProgressIndicator()),
        );
      }

      final parsedEntries = validateAndParseImport(bytes);
      final discovery = parseDiscoveryImport(bytes);

      final repository = ref.read(wordsRepositoryProvider);
      final mergeResult = await repository.mergeEntries(parsedEntries);
      if (discovery != null) {
        final db = await ref.read(databaseProvider.future);
        await SuggestedWordsRepository(db).mergeHistory(discovery);
      }

      // Refresh providers
      ref.read(vocabularyListProvider.notifier).refreshList();

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(); // Pop progress dialog

        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total entries processed: ${parsedEntries.length}'),
                const SizedBox(height: 8),
                Text('• Added: ${mergeResult.added}'),
                Text('• Updated: ${mergeResult.updated}'),
                Text('• Kept existing (skipped): ${mergeResult.skipped}'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Pop loading indicator if showing
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Import Failed'),
            content: Text(
              e is ExportImportException
                  ? e.message
                  : 'Error importing backup: $e',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }
}
