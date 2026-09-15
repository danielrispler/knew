import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/vocabulary/data/gemini_parser.dart';
import 'package:knew/src/features/vocabulary/domain/gemini_lookup_result.dart';

void main() {
  group('GeminiParser', () {
    test('parses valid English lookup response successfully', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'valid': true,
                    'suggestion': null,
                    'english': 'persistent',
                    'englishAlternatives': [],
                    'meanings': [
                      {
                        'partOfSpeech': 'adjective',
                        'hebrew': ['עקשן', 'מתמיד'],
                        'definition': 'Continuing firmly or obstinately in a course of action.'
                      }
                    ]
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      final result = GeminiParser.parseResponse(
        responseBody: jsonEncode(jsonResponse),
        originalInput: 'persistent',
        inputLanguage: 'english',
      );

      expect(result, isA<GeminiSuccessResult>());
      final success = result as GeminiSuccessResult;
      expect(success.english, equals('persistent'));
      expect(success.englishAlternatives, isEmpty);
      expect(success.meanings.length, equals(1));
      expect(success.meanings.first.partOfSpeech, equals('adjective'));
      expect(success.meanings.first.hebrewTranslations, equals(['עקשן', 'מתמיד']));
      expect(success.meanings.first.definition, equals('Continuing firmly or obstinately in a course of action.'));
    });

    test('parses valid Hebrew lookup response with englishAlternatives', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'valid': true,
                    'suggestion': null,
                    'english': 'stubborn',
                    'englishAlternatives': ['persistent', 'obstinate'],
                    'meanings': [
                      {
                        'partOfSpeech': 'adjective',
                        'hebrew': ['עקשן'],
                        'definition': 'Refusing to change one\'s opinion or position.'
                      }
                    ]
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      final result = GeminiParser.parseResponse(
        responseBody: jsonEncode(jsonResponse),
        originalInput: 'עקשן',
        inputLanguage: 'hebrew',
      );

      expect(result, isA<GeminiSuccessResult>());
      final success = result as GeminiSuccessResult;
      expect(success.english, equals('stubborn'));
      expect(success.englishAlternatives, equals(['persistent', 'obstinate']));
      expect(success.meanings.length, equals(1));
    });

    test('parses invalid result with suggestion', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'valid': false,
                    'suggestion': 'persistent',
                    'english': '',
                    'englishAlternatives': [],
                    'meanings': []
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      final result = GeminiParser.parseResponse(
        responseBody: jsonEncode(jsonResponse),
        originalInput: 'persistant',
        inputLanguage: 'english',
      );

      expect(result, isA<GeminiInvalidResult>());
      final invalid = result as GeminiInvalidResult;
      expect(invalid.suggestion, equals('persistent'));
    });

    test('parses invalid result without suggestion', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'valid': false,
                    'suggestion': null,
                    'english': '',
                    'englishAlternatives': [],
                    'meanings': []
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      final result = GeminiParser.parseResponse(
        responseBody: jsonEncode(jsonResponse),
        originalInput: 'asdfghjkl',
        inputLanguage: 'english',
      );

      expect(result, isA<GeminiInvalidResult>());
      final invalid = result as GeminiInvalidResult;
      expect(invalid.suggestion, null);
    });

    test('ignores thought parts and concatenates text parts', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'thought': true,
                  'text': 'Internal reasoning text that should be ignored'
                },
                {
                  'text': '{"valid": true, "suggestion": null, "english": "test", "englishAlternatives": [], "meanings": [{"partOfSpeech": "noun", "hebrew": ["מבחן"], "definition": "A procedure for critical evaluation."}]}'
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      final result = GeminiParser.parseResponse(
        responseBody: jsonEncode(jsonResponse),
        originalInput: 'test',
        inputLanguage: 'english',
      );

      expect(result, isA<GeminiSuccessResult>());
      final success = result as GeminiSuccessResult;
      expect(success.english, equals('test'));
    });

    test('handles candidate finishReason MAX_TOKENS as truncated error', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [{'text': '{"valid": true,'}]
            },
            'finishReason': 'MAX_TOKENS'
          }
        ]
      };

      expect(
        () => GeminiParser.parseResponse(
          responseBody: jsonEncode(jsonResponse),
          originalInput: 'test',
          inputLanguage: 'english',
        ),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.responseTruncated))),
      );
    });

    test('handles candidate finishReason SAFETY as safety block error', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [{'text': ''}]
            },
            'finishReason': 'SAFETY'
          }
        ]
      };

      expect(
        () => GeminiParser.parseResponse(
          responseBody: jsonEncode(jsonResponse),
          originalInput: 'test',
          inputLanguage: 'english',
        ),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.safetyBlock))),
      );
    });

    test('throws unusable response on malformed JSON payload', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [{'text': 'not a json'}]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      expect(
        () => GeminiParser.parseResponse(
          responseBody: jsonEncode(jsonResponse),
          originalInput: 'test',
          inputLanguage: 'english',
        ),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.unusableResponse))),
      );
    });

    test('throws unusable response when missing required fields', () {
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'valid': true,
                    // missing english and meanings
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      expect(
        () => GeminiParser.parseResponse(
          responseBody: jsonEncode(jsonResponse),
          originalInput: 'test',
          inputLanguage: 'english',
        ),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.unusableResponse))),
      );
    });

    test('trims definition exceeding 15 words to 15 words', () {
      final longDef = List.generate(20, (i) => 'word$i').join(' ');
      final jsonResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'valid': true,
                    'suggestion': null,
                    'english': 'run',
                    'englishAlternatives': [],
                    'meanings': [
                      {
                        'partOfSpeech': 'verb',
                        'hebrew': ['לרוץ'],
                        'definition': longDef
                      }
                    ]
                  })
                }
              ]
            },
            'finishReason': 'STOP'
          }
        ]
      };

      final result = GeminiParser.parseResponse(
        responseBody: jsonEncode(jsonResponse),
        originalInput: 'run',
        inputLanguage: 'english',
      );

      final success = result as GeminiSuccessResult;
      final words = success.meanings.first.definition.split(RegExp(r'\s+'));
      expect(words.length, lessThanOrEqualTo(15));
    });
  });
}
