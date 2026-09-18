import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:knew/src/features/vocabulary/data/gemini_client.dart';
import 'package:knew/src/features/vocabulary/data/gemini_models.dart';
import 'package:knew/src/features/vocabulary/domain/gemini_lookup_result.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';

void main() {
  group('GeminiModels', () {
    test(
      'getFallbackSequence returns 2-hop sequence [primary, 3.5-flash-lite] for non-lite models',
      () {
        expect(
          GeminiModels.getFallbackSequence(GeminiModels.gemini38Flash),
          equals([GeminiModels.gemini38Flash, GeminiModels.gemini35FlashLite]),
        );
        expect(
          GeminiModels.getFallbackSequence(GeminiModels.gemini37Flash),
          equals([GeminiModels.gemini37Flash, GeminiModels.gemini35FlashLite]),
        );
        expect(
          GeminiModels.getFallbackSequence('custom-model'),
          equals(['custom-model', GeminiModels.gemini35FlashLite]),
        );
      },
    );

    test(
      'getFallbackSequence returns single hop [3.5-flash-lite] when primary model is flash-lite',
      () {
        expect(
          GeminiModels.getFallbackSequence(GeminiModels.gemini35FlashLite),
          equals([GeminiModels.gemini35FlashLite]),
        );
      },
    );
  });

  group('GeminiClient', () {
    const testApiKey = 'AIzaSyTestKey123';
    const testModel = GeminiModels.gemini38Flash;

    test(
      'evaluates a sentence and requests feedback in the app language',
      () async {
        late Map<String, dynamic> requestBody;
        final client = GeminiClient(
          httpClient: MockClient((request) async {
            requestBody = jsonDecode(request.body) as Map<String, dynamic>;
            return http.Response.bytes(
              utf8.encode(
                jsonEncode({
                  'candidates': [
                    {
                      'content': {
                        'parts': [
                          {
                            'text': jsonEncode({
                              'usesTargetTerm': true,
                              'meaningCorrect': true,
                              'grammarCorrect': true,
                              'naturalUsage': false,
                              'feedback': 'משוב',
                              'suggestedImprovement': null,
                            }),
                          },
                        ],
                      },
                    },
                  ],
                }),
              ),
              200,
            );
          }),
        );

        final result = await client.evaluateSentenceWithFallback(
          term: 'run',
          meaning: const Meaning(
            partOfSpeech: 'verb',
            definition: 'move fast',
            hebrewTranslations: ['לרוץ'],
          ),
          sentence: 'I run daily.',
          feedbackLanguage: 'Hebrew',
          apiKey: testApiKey,
          primaryModel: testModel,
        );

        expect(result.isValid, isTrue);
        expect(result.naturalUsage, isFalse);
        expect(
          requestBody['systemInstruction']['parts'][0]['text'],
          contains('Hebrew'),
        );
      },
    );

    test('throws missingKey when API key is empty', () async {
      final client = GeminiClient();

      expect(
        () => client.lookup(input: 'test', apiKey: '', model: testModel),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.missingKey),
          ),
        ),
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
                          'definition': 'A round fruit with red or green skin.',
                        },
                      ],
                    }),
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responsePayload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
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

    test(
      'sets maxOutputTokens to 512 and includes zero thinking budget for primary model',
      () async {
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
                            'definition': 'A round fruit.',
                          },
                        ],
                      }),
                    },
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          };
          return http.Response.bytes(
            utf8.encode(jsonEncode(responsePayload)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final geminiClient = GeminiClient(httpClient: mockHttpClient);
        await geminiClient.lookup(
          input: 'apple',
          apiKey: testApiKey,
          model: GeminiModels.gemini38Flash,
        );

        final bodyJson = jsonDecode(capturedRequest.body);
        final genConfig = bodyJson['generationConfig'];
        expect(genConfig['maxOutputTokens'], equals(512));
        expect(genConfig['thinkingConfig'], equals({'thinkingBudget': 0}));
      },
    );

    test('omits thinkingConfig for gemini-3.5-flash-lite', () async {
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
                          'definition': 'A round fruit.',
                        },
                      ],
                    }),
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responsePayload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      await geminiClient.lookup(
        input: 'apple',
        apiKey: testApiKey,
        model: GeminiModels.gemini35FlashLite,
      );

      final bodyJson = jsonDecode(capturedRequest.body);
      final genConfig = bodyJson['generationConfig'];
      expect(genConfig['maxOutputTokens'], equals(512));
      expect(genConfig.containsKey('thinkingConfig'), isFalse);
    });

    test(
      'retries without thinkingConfig when primary model returns 400 for unsupported thinkingConfig',
      () async {
        int attempt = 0;
        final capturedRequests = <http.Request>[];
        final mockHttpClient = MockClient((request) async {
          attempt++;
          capturedRequests.add(request);
          if (attempt == 1) {
            return http.Response(
              jsonEncode({
                'error': {
                  'code': 400,
                  'status': 'INVALID_ARGUMENT',
                  'message': 'thinkingConfig is not supported for this model',
                },
              }),
              400,
            );
          }
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
                            'definition': 'A round fruit.',
                          },
                        ],
                      }),
                    },
                  ],
                },
                'finishReason': 'STOP',
              },
            ],
          };
          return http.Response.bytes(
            utf8.encode(jsonEncode(responsePayload)),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final geminiClient = GeminiClient(httpClient: mockHttpClient);
        final result = await geminiClient.lookup(
          input: 'apple',
          apiKey: testApiKey,
          model: GeminiModels.gemini38Flash,
        );

        expect(result, isA<GeminiSuccessResult>());
        expect(attempt, equals(2));
        final firstBody = jsonDecode(capturedRequests[0].body);
        expect(
          firstBody['generationConfig']['thinkingConfig'],
          equals({'thinkingBudget': 0}),
        );
        final secondBody = jsonDecode(capturedRequests[1].body);
        expect(
          secondBody['generationConfig'].containsKey('thinkingConfig'),
          isFalse,
        );
      },
    );

    test('logs timing per model attempt in structured format', () async {
      final logs = <String>[];
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
                      'english': 'apple',
                      'englishAlternatives': [],
                      'meanings': [
                        {
                          'partOfSpeech': 'noun',
                          'hebrew': ['תפוח'],
                          'definition': 'A round fruit.',
                        },
                      ],
                    }),
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responsePayload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final geminiClient = GeminiClient(
        httpClient: mockHttpClient,
        logger: (msg) => logs.add(msg),
      );
      await geminiClient.lookup(
        input: 'apple',
        apiKey: testApiKey,
        model: GeminiModels.gemini38Flash,
      );

      expect(logs.length, equals(1));
      final logRegex = RegExp(
        r'^\[GeminiClient\] "apple" -> model: gemini-3.8-flash \| duration: \d+ms \| status: 200$',
      );
      expect(
        logRegex.hasMatch(logs[0]),
        isTrue,
        reason: 'Expected log to match pattern but got: ${logs[0]}',
      );
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
                          'definition': 'A round fruit.',
                        },
                      ],
                    }),
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responsePayload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
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
                'reason': 'API_KEY_INVALID',
              },
            ],
          },
        };
        return http.Response(jsonEncode(errorPayload), 400);
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookup(
          input: 'test',
          apiKey: testApiKey,
          model: testModel,
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.invalidKey),
          ),
        ),
      );
    });

    test('handles 429 rate limit / quota exhausted error', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          '{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}',
          429,
        );
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookup(
          input: 'test',
          apiKey: testApiKey,
          model: testModel,
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.quotaExhausted),
          ),
        ),
      );
    });

    test('handles 404 model unavailable error', () async {
      final mockHttpClient = MockClient((request) async {
        return http.Response(
          '{"error": {"code": 404, "status": "NOT_FOUND"}}',
          404,
        );
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);

      expect(
        () => geminiClient.lookup(
          input: 'test',
          apiKey: testApiKey,
          model: testModel,
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.modelUnavailable),
          ),
        ),
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
        () => geminiClient.lookup(
          input: 'test',
          apiKey: testApiKey,
          model: testModel,
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.timeout),
          ),
        ),
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
                          'definition': 'A procedure for critical evaluation.',
                        },
                      ],
                    }),
                  },
                ],
              },
              'finishReason': 'STOP',
            },
          ],
        };
        return http.Response.bytes(
          utf8.encode(jsonEncode(responsePayload)),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final geminiClient = GeminiClient(httpClient: mockHttpClient);
      final ok = await geminiClient.testConnection(
        apiKey: testApiKey,
        model: testModel,
      );

      expect(ok, isTrue);
    });

    test(
      'lookupWithFallback falls back directly to 3.5-flash-lite when 3.8 returns 429 quota exhausted',
      () async {
        final requestedModels = <String>[];
        final mockHttpClient = MockClient((request) async {
          final uriPath = request.url.path;
          if (uriPath.contains('gemini-3.8-flash')) {
            requestedModels.add('gemini-3.8-flash');
            return http.Response(
              '{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}',
              429,
            );
          } else if (uriPath.contains('gemini-3.5-flash-lite')) {
            requestedModels.add('gemini-3.5-flash-lite');
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
                              'definition': 'A round fruit.',
                            },
                          ],
                        }),
                      },
                    ],
                  },
                  'finishReason': 'STOP',
                },
              ],
            };
            return http.Response.bytes(
              utf8.encode(jsonEncode(responsePayload)),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final geminiClient = GeminiClient(httpClient: mockHttpClient);
        final result = await geminiClient.lookupWithFallback(
          input: 'apple',
          apiKey: testApiKey,
          primaryModel: GeminiModels.gemini38Flash,
        );

        expect(result, isA<GeminiSuccessResult>());
        expect(
          requestedModels,
          equals(['gemini-3.8-flash', 'gemini-3.5-flash-lite']),
        );
      },
    );

    test(
      'lookupWithFallback executes only a single hop when primary model is 3.5-flash-lite',
      () async {
        final requestedModels = <String>[];
        final mockHttpClient = MockClient((request) async {
          final uriPath = request.url.path;
          if (uriPath.contains('gemini-3.5-flash-lite')) {
            requestedModels.add('gemini-3.5-flash-lite');
            return http.Response(
              '{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}',
              429,
            );
          }
          return http.Response('Not Found', 404);
        });

        final geminiClient = GeminiClient(httpClient: mockHttpClient);

        await expectLater(
          () => geminiClient.lookupWithFallback(
            input: 'apple',
            apiKey: testApiKey,
            primaryModel: GeminiModels.gemini35FlashLite,
          ),
          throwsA(
            isA<GeminiException>().having(
              (e) => e.errorType,
              'errorType',
              equals(GeminiErrorType.quotaExhausted),
            ),
          ),
        );

        expect(requestedModels, equals(['gemini-3.5-flash-lite']));
      },
    );

    test(
      'lookupWithFallback stops immediately and rethrows on invalid key (400)',
      () async {
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
                  'reason': 'API_KEY_INVALID',
                },
              ],
            },
          };
          return http.Response(jsonEncode(errorPayload), 400);
        });

        final geminiClient = GeminiClient(httpClient: mockHttpClient);

        await expectLater(
          () => geminiClient.lookupWithFallback(
            input: 'test',
            apiKey: testApiKey,
            primaryModel: 'gemini-3.8-flash',
          ),
          throwsA(
            isA<GeminiException>().having(
              (e) => e.errorType,
              'errorType',
              equals(GeminiErrorType.invalidKey),
            ),
          ),
        );
        expect(requestedModels.length, equals(1));
      },
    );

    test(
      'lookupWithFallback attempts custom model first then falls back directly to 3.5-flash-lite',
      () async {
        final requestedModels = <String>[];
        final mockHttpClient = MockClient((request) async {
          final uriPath = request.url.path;
          if (uriPath.contains('custom-experimental-model')) {
            requestedModels.add('custom-experimental-model');
            return http.Response(
              '{"error": {"code": 404, "status": "NOT_FOUND"}}',
              404,
            );
          } else if (uriPath.contains('gemini-3.5-flash-lite')) {
            requestedModels.add('gemini-3.5-flash-lite');
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
                              'definition': 'A round fruit.',
                            },
                          ],
                        }),
                      },
                    ],
                  },
                  'finishReason': 'STOP',
                },
              ],
            };
            return http.Response.bytes(
              utf8.encode(jsonEncode(responsePayload)),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
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
        expect(
          requestedModels,
          equals(['custom-experimental-model', 'gemini-3.5-flash-lite']),
        );
      },
    );

    test(
      'lookupWithFallback falls back to 3.5-flash-lite on 503 server error',
      () async {
        final requestedModels = <String>[];
        final mockHttpClient = MockClient((request) async {
          final uriPath = request.url.path;
          if (uriPath.contains('gemini-3.8-flash')) {
            requestedModels.add('gemini-3.8-flash');
            return http.Response(
              '{"error": {"code": 503, "status": "UNAVAILABLE"}}',
              503,
            );
          } else if (uriPath.contains('gemini-3.5-flash-lite')) {
            requestedModels.add('gemini-3.5-flash-lite');
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
                              'definition': 'A round fruit.',
                            },
                          ],
                        }),
                      },
                    ],
                  },
                  'finishReason': 'STOP',
                },
              ],
            };
            return http.Response.bytes(
              utf8.encode(jsonEncode(responsePayload)),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response('Not Found', 404);
        });

        final geminiClient = GeminiClient(httpClient: mockHttpClient);
        final result = await geminiClient.lookupWithFallback(
          input: 'apple',
          apiKey: testApiKey,
          primaryModel: GeminiModels.gemini38Flash,
        );

        expect(result, isA<GeminiSuccessResult>());
        expect(
          requestedModels,
          equals(['gemini-3.8-flash', 'gemini-3.5-flash-lite']),
        );
      },
    );

    test('logs timing on error and timeout', () async {
      final logs = <String>[];
      final mockHttpClient = MockClient((request) async {
        if (request.url.path.contains('timeout')) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
        return http.Response(
          '{"error": {"code": 429, "status": "RESOURCE_EXHAUSTED"}}',
          429,
        );
      });

      final client = GeminiClient(
        httpClient: mockHttpClient,
        timeout: const Duration(milliseconds: 30),
        logger: (msg) => logs.add(msg),
      );

      await expectLater(
        () => client.lookup(
          input: 'hello',
          apiKey: testApiKey,
          model: 'timeout-model',
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.timeout),
          ),
        ),
      );
      expect(logs.any((l) => l.contains('status: timeout')), isTrue);

      await expectLater(
        () => client.lookup(
          input: 'world',
          apiKey: testApiKey,
          model: GeminiModels.gemini38Flash,
        ),
        throwsA(
          isA<GeminiException>().having(
            (e) => e.errorType,
            'errorType',
            equals(GeminiErrorType.quotaExhausted),
          ),
        ),
      );
      expect(logs.any((l) => l.contains('status: 429')), isTrue);
    });
  });
}
