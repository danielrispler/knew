import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:knew/src/features/vocabulary/data/gemini_client.dart';
import 'package:knew/src/features/vocabulary/data/gemini_models.dart';
import 'package:knew/src/features/vocabulary/domain/meaning.dart';

void main() {
  const key = 'test-key';
  http.Response response(Object value) => http.Response.bytes(
    utf8.encode(
      jsonEncode({
        'status': 'completed',
        'outputs': [
          {'type': 'text', 'text': jsonEncode(value)},
        ],
      }),
    ),
    200,
  );
  final result = {
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
  };
  test('uses Interactions with structured JSON and low thinking', () async {
    late http.Request request;
    final client = GeminiClient(
      httpClient: MockClient((r) async {
        request = r;
        return response(result);
      }),
    );
    await client.lookup(
      input: 'apple',
      apiKey: key,
      model: GeminiModels.gemini38Flash,
    );
    final body = jsonDecode(request.body) as Map;
    expect(request.url.path, '/v1beta/interactions');
    expect(request.headers['x-goog-api-key'], key);
    expect(body['input'], contains('"inputLanguage":"english"'));
    expect(
      body['response_format'],
      containsPair('mime_type', 'application/json'),
    );
    expect(body['generation_config'], {
      'thinking_level': 'low',
      'max_output_tokens': 512,
    });
    expect(
      body.keys,
      isNot(containsAll(['contents', 'generationConfig', 'candidateCount'])),
    );
  });
  test(
    'retries unsupported custom thinking once and omits it for Flash-Lite',
    () async {
      final bodies = <Map>[];
      var count = 0;
      final client = GeminiClient(
        httpClient: MockClient((r) async {
          bodies.add(jsonDecode(r.body));
          return ++count == 1
              ? http.Response(
                  '{"error":{"message":"thinking unsupported"}}',
                  400,
                )
              : response(result);
        }),
      );
      await client.lookup(input: 'apple', apiKey: key, model: 'custom');
      expect(bodies, hasLength(2));
      expect(bodies[1]['generation_config'], {'max_output_tokens': 512});
    },
  );
  test(
    'all flows use shared Interaction path and fallback logs no learner data',
    () async {
      final logs = <String>[];
      final client = GeminiClient(
        logger: logs.add,
        httpClient: MockClient((r) async {
          final b = jsonDecode(r.body) as Map;
          if (b['model'] == GeminiModels.gemini38Flash)
            return http.Response('{}', 429);
          return response(result);
        }),
      );
      await client.lookupWithFallback(
        input: 'private apple',
        apiKey: key,
        primaryModel: GeminiModels.gemini38Flash,
      );
      expect(logs.join(), isNot(contains('private apple')));
      expect(logs.join(), isNot(contains(key)));
      final other = GeminiClient(
        httpClient: MockClient((r) async {
          final p = (jsonDecode(r.body) as Map)['system_instruction'] as String;
          if (p.contains('suggestions'))
            return response({
              'words': ['useful'],
            });
          if (p.contains('examples')) return response({'meanings': []});
          return response({
            'usesTargetTerm': true,
            'meaningCorrect': true,
            'grammarCorrect': true,
            'naturalUsage': true,
            'feedback': 'ok',
            'suggestedImprovement': null,
          });
        }),
      );
      await other.suggestedWords(
        excluded: {},
        bandCenter: 1,
        apiKey: key,
        model: GeminiModels.gemini35FlashLite,
      );
      await other.enrich(
        term: 'run',
        meanings: const [
          Meaning(
            partOfSpeech: 'verb',
            definition: 'move',
            hebrewTranslations: ['לרוץ'],
          ),
        ],
        apiKey: key,
        model: GeminiModels.gemini35FlashLite,
      );
      await other.evaluateSentenceWithFallback(
        term: 'run',
        meaning: const Meaning(
          partOfSpeech: 'verb',
          definition: 'move',
          hebrewTranslations: ['לרוץ'],
        ),
        sentence: 'I run.',
        feedbackLanguage: 'English',
        apiKey: key,
        primaryModel: GeminiModels.gemini35FlashLite,
      );
    },
  );
}
