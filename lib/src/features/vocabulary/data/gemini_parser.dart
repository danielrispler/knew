import 'dart:convert';
import '../domain/gemini_lookup_result.dart';
import '../domain/meaning.dart';

class GeminiParser {
  static GeminiLookupResult parseResponse({
    required String responseBody,
    required String originalInput,
    required String inputLanguage,
  }) {
    Map<String, dynamic> json;
    try {
      json = jsonDecode(responseBody) as Map<String, dynamic>;
    } catch (_) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    if (json.containsKey('promptFeedback')) {
      final feedback = json['promptFeedback'];
      if (feedback is Map && feedback.containsKey('blockReason')) {
        throw const GeminiException(
          GeminiErrorType.safetyBlock,
          'Gemini could not answer this lookup. Try another wording or add the word manually.',
        );
      }
    }

    final candidates = json['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final finishReason = firstCandidate['finishReason'] as String?;
    if (finishReason == 'MAX_TOKENS') {
      throw const GeminiException(
        GeminiErrorType.responseTruncated,
        'Gemini returned an incomplete answer. Try again or add the word manually.',
      );
    } else if (finishReason == 'SAFETY') {
      throw const GeminiException(
        GeminiErrorType.safetyBlock,
        'Gemini could not answer this lookup. Try another wording or add the word manually.',
      );
    } else if (finishReason != 'STOP') {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final content = firstCandidate['content'];
    if (content is! Map) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final buffer = StringBuffer();
    for (var part in parts) {
      if (part is Map) {
        if (part['thought'] == true || part['thought'] == 'true') {
          continue;
        }
        final text = part['text'];
        if (text is String) {
          buffer.write(text);
        }
      }
    }

    final concatenatedText = buffer.toString().trim();
    if (concatenatedText.isEmpty) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(concatenatedText) as Map<String, dynamic>;
    } catch (_) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    if (!payload.containsKey('valid') ||
        !payload.containsKey('english') ||
        !payload.containsKey('englishAlternatives') ||
        !payload.containsKey('meanings')) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final valid = payload['valid'];
    if (valid is! bool) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final suggestion = payload['suggestion'] as String?;

    if (!valid) {
      return GeminiInvalidResult(
        suggestion: (suggestion != null && suggestion.trim().isNotEmpty) ? suggestion.trim() : null,
        originalInput: originalInput,
        inputLanguage: inputLanguage,
      );
    }

    final english = payload['english'];
    if (english is! String || english.trim().isEmpty) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final rawAlternatives = payload['englishAlternatives'];
    final List<String> englishAlternatives = [];
    if (rawAlternatives is List) {
      for (var alt in rawAlternatives) {
        if (alt is String && alt.trim().isNotEmpty) {
          englishAlternatives.add(alt.trim());
        }
      }
    }

    final rawMeanings = payload['meanings'];
    if (rawMeanings is! List || rawMeanings.isEmpty || rawMeanings.length > 3) {
      throw const GeminiException(
        GeminiErrorType.unusableResponse,
        'Gemini returned an unusable answer. Try again or add the word manually.',
      );
    }

    final List<Meaning> parsedMeanings = [];
    for (var m in rawMeanings) {
      if (m is! Map) {
        throw const GeminiException(
          GeminiErrorType.unusableResponse,
          'Gemini returned an unusable answer. Try again or add the word manually.',
        );
      }

      final pos = m['partOfSpeech'];
      final rawHebrew = m['hebrew'] ?? m['hebrewTranslations'];
      final def = m['definition'];

      if (pos is! String || pos.trim().isEmpty || def is! String || def.trim().isEmpty) {
        throw const GeminiException(
          GeminiErrorType.unusableResponse,
          'Gemini returned an unusable answer. Try again or add the word manually.',
        );
      }

      final List<String> hebrewList = [];
      if (rawHebrew is List) {
        for (var h in rawHebrew) {
          if (h is String && h.trim().isNotEmpty) {
            hebrewList.add(h.trim());
          }
        }
      }

      if (hebrewList.isEmpty) {
        throw const GeminiException(
          GeminiErrorType.unusableResponse,
          'Gemini returned an unusable answer. Try again or add the word manually.',
        );
      }

      final words = def.trim().split(RegExp(r'\s+'));
      final trimmedDef = words.length > 15 ? words.take(15).join(' ') : def.trim();

      parsedMeanings.add(Meaning(
        partOfSpeech: pos.trim(),
        definition: trimmedDef,
        hebrewTranslations: hebrewList,
      ));
    }

    return GeminiSuccessResult(
      english: english.trim(),
      englishAlternatives: englishAlternatives,
      meanings: parsedMeanings,
      originalInput: originalInput,
      inputLanguage: inputLanguage,
    );
  }
}
