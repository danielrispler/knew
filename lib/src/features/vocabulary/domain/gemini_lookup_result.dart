import 'meaning.dart';

enum GeminiErrorType {
  missingKey,
  invalidKey,
  unauthenticated,
  permissionDenied,
  quotaExhausted,
  modelUnavailable,
  configurationError,
  timeout,
  networkError,
  serviceUnavailable,
  responseTruncated,
  safetyBlock,
  unusableResponse,
}

class GeminiException implements Exception {
  final GeminiErrorType errorType;
  final String message;
  final String? originalDetails;

  const GeminiException(this.errorType, this.message, [this.originalDetails]);

  @override
  String toString() => 'GeminiException($errorType): $message';
}

abstract class GeminiLookupResult {
  const GeminiLookupResult();
}

class GeminiSuccessResult extends GeminiLookupResult {
  final String english;
  final List<String> englishAlternatives;
  final List<Meaning> meanings;
  final String originalInput;
  final String inputLanguage;

  const GeminiSuccessResult({
    required this.english,
    required this.englishAlternatives,
    required this.meanings,
    required this.originalInput,
    required this.inputLanguage,
  });
}

class GeminiInvalidResult extends GeminiLookupResult {
  final String? suggestion;
  final String originalInput;
  final String inputLanguage;

  const GeminiInvalidResult({
    this.suggestion,
    required this.originalInput,
    required this.inputLanguage,
  });
}

class GeminiErrorResult extends GeminiLookupResult {
  final GeminiErrorType errorType;
  final String message;
  final String originalInput;

  const GeminiErrorResult({
    required this.errorType,
    required this.message,
    required this.originalInput,
  });
}
