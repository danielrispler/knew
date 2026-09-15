import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:knew/src/features/vocabulary/data/gemini_client.dart';
import 'package:knew/src/features/vocabulary/domain/gemini_lookup_result.dart';

void main() {
  group('GeminiClient', () {
    const testApiKey = 'AIzaSyTestKey123';
    const testModel = 'gemini-2.5-flash';

    test('throws missingKey when API key is empty', () async {
      final client = GeminiClient();

      expect(
        () => client.lookup(input: 'test', apiKey: '', model: testModel),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.missingKey))),
      );
    });

    test('detects English input language correctly', () async {
      late http.Request capturedRequest;
      final mockHttpClient = MockClient((request) async {
        capturedRequest = request;
        final responsePayload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'valid': true,
                      'suggestion': null,
                      'english': 'apple',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'noun',
                          'hebrew': ['תפוח'],
                          'definition': 'A round fruit with red or green skin.'
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
        return http.Response.bytes(utf8.encode(jsonEncode(responsePayload)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      final result = await geminiClient.lookup(
        input: 'apple',
        apiKey: testApiKey,
        model: testModel,
      );

      expect(result, isA<GeminiSuccessResult>());
      expect(capturedRequest.headers['x-goog-api-key'], equals(testApiKey));
      final bodyJson = jsonDecode(capturedRequest.body);
      final userPart = bodyJson['contents'][0]['parts'][0]['text'];
      expect(userPart, contains('"inputLanguage":"english"'));
    });

    test('detects Hebrew input language correctly', () async {
      late http.Request capturedRequest;
      final mockHttpClient = MockClient((request) async {
        capturedRequest = request;
        final responsePayload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'valid': true,
                      'suggestion': null,
                      'english': 'apple',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'noun',
                          'hebrew': ['תפוח'],
                          'definition': 'A round fruit.'
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
        return http.Response.bytes(utf8.encode(jsonEncode(responsePayload)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      final result = await geminiClient.lookup(
        input: 'תפוח',
        apiKey: testApiKey,
        model: testModel,
      );

      expect(result, isA<GeminiSuccessResult>());
      final bodyJson = jsonDecode(capturedRequest.body);
      final userPart = bodyJson['contents'][0]['parts'][0]['text'];
      expect(userPart, contains('"inputLanguage":"hebrew"'));
    });

    test('handles 400 invalid key error response', () async {
      final mockHttpClient = MockClient((request) async {
        final errorPayload = {
          'error': {
            'code': 400,
            'status': 'INVALID_ARGUMENT',
            'message': 'API key not valid',
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
                'reason': 'API_KEY_INVALID'
              }
            ]
          }
        };
        return http.Response(jsonEncode(errorPayload), 400);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookup(input: 'test', apiKey: testApiKey, model: testModel),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.invalidKey))),
      );
    });

    test('handles 429 rate limit / quota exhausted error', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}', 429);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookup(input: 'test', apiKey: testApiKey, model: testModel),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.quotaExhausted))),
      );
    });

    test('handles 404 model unavailable error', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response('{"error": {"code": 404, "status": "NOT_FOUND"}}', 404);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookup(input: 'test', apiKey: testApiKey, model: testModel),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.modelUnavailable))),
      );
    });

    test('handles timeout exception as GeminiErrorType.timeout', () async {
      final mockHttpClient = MockClient((request) async {
        await Future.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      });

      final geminiClient = GeminiClient(
        httpClient: mockHttpClient,
        timeout: const Duration(milliseconds: 50),
      );

      expect(
        () => geminiClient.lookup(input: 'test', apiKey: testApiKey, model: testModel),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.timeout))),
      );
    });

    test('testConnection returns true on valid key lookup', () async {
      final mockHttpClient = MockClient((request) async {
        final responsePayload = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode({
                      'valid': true,
                      'suggestion': null,
                      'english': 'test',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'noun',
                          'hebrew': ['מבחן'],
                          'definition': 'A procedure for critical evaluation.'
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
        return http.Response.bytes(utf8.encode(jsonEncode(responsePayload)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      final ok = await geminiClient.testConnection(apiKey: testApiKey, model: testModel);

      expect(ok, isTrue);
    });

    test('lookupWithFallback falls back from 3.8 to 3.7 when 3.8 returns 429 quota exhausted', () async {
      final requestedModels = <String>[];
      final mockHttpClient = MockClient((request) async {
        final uriPath = request.url.path;
        if (uriPath.contains('gemini-3.8-flash')) {
          requestedModels.add('gemini-3.8-flash');
          return http.Response('{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}', 429);
        } else if (uriPath.contains('gemini-3.7-flash')) {
          requestedModels.add('gemini-3.7-flash');
          final responsePayload = {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'valid': true,
                        'suggestion': null,
                        'english': 'apple',
                        'englishAlternatives': [],
                        'meanings': [
                          {
                            'partOfSpeech': 'noun',
                            'hebrew': ['תפוח'],
                            'definition': 'A round fruit.'
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
          return http.Response.bytes(utf8.encode(jsonEncode(responsePayload)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('Not Found', 404);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      final result = await geminiClient.lookupWithFallback(
        input: 'apple',
        apiKey: testApiKey,
        primaryModel: 'gemini-3.8-flash',
      );

      expect(result, isA<GeminiSuccessResult>());
      expect(requestedModels, equals(['gemini-3.8-flash', 'gemini-3.7-flash']));
    });

    test('lookupWithFallback stops immediately and rethrows on invalid key (400)', () async {
      final requestedModels = <String>[];
      final mockHttpClient = MockClient((request) async {
        requestedModels.add(request.url.path);
        final errorPayload = {
          'error': {
            'code': 400,
            'status': 'INVALID_ARGUMENT',
            'message': 'API key not valid',
            'details': [
              {
                '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
                'reason': 'API_KEY_INVALID'
              }
            ]
          }
        };
        return http.Response(jsonEncode(errorPayload), 400);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookupWithFallback(
          input: 'test',
          apiKey: testApiKey,
          primaryModel: 'gemini-3.8-flash',
        ),
        throwsA(isA<GeminiException>().having((e) => e.errorType, 'errorType', equals(GeminiErrorType.invalidKey))),
      );
      expect(requestedModels.length, equals(1));
    });

    test('lookupWithFallback attempts custom model first then falls back to standard chain', () async {
      final requestedModels = <String>[];
      final mockHttpClient = MockClient((request) async {
        final uriPath = request.url.path;
        if (uriPath.contains('custom-experimental-model')) {
          requestedModels.add('custom-experimental-model');
          return http.Response('{"error": {"code": 404, "status": "NOT_FOUND"}}', 404);
        } else if (uriPath.contains('gemini-3.8-flash')) {
          requestedModels.add('gemini-3.8-flash');
          final responsePayload = {
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'valid': true,
                        'suggestion': null,
                        'english': 'apple',
                        'englishAlternatives': [],
                        'meanings': [
                          {
                            'partOfSpeech': 'noun',
                            'hebrew': ['תפוח'],
                            'definition': 'A round fruit.'
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
          return http.Response.bytes(utf8.encode(jsonEncode(responsePayload)), 200, headers: {'content-type': 'application/json; charset=utf-8'});
        }
        return http.Response('Not Found', 404);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      final result = await geminiClient.lookupWithFallback(
        input: 'apple',
        apiKey: testApiKey,
        primaryModel: 'custom-experimental-model',
      );

      expect(result, isA<GeminiSuccessResult>());
      expect(requestedModels, equals(['custom-experimental-model', 'gemini-3.8-flash']));
    });
  });
}
