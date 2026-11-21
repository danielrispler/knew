import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:knew/src/features/reading/data/claude_client.dart';
import 'package:knew/src/features/reading/domain/reading.dart';

void main() {
  final reading = Reading(readingBooks.first, 5);

  http.Response message(Object words, {String stopReason = 'end_turn'}) =>
      http.Response.bytes(
        utf8.encode(
          jsonEncode({
            'stop_reason': stopReason,
            'content': [
              {'type': 'thinking', 'thinking': ''},
              {
                'type': 'text',
                'text': jsonEncode({'words': words}),
              },
            ],
          }),
        ),
        200,
      );

  Future<ClaudeErrorType> errorFor(http.Response response) async {
    final client = ClaudeClient(httpClient: MockClient((_) async => response));
    try {
      await client.chapterWords(reading: reading, apiKey: 'key');
    } on ClaudeException catch (e) {
      return e.type;
    }
    fail('expected a ClaudeException');
  }

  test('asks Opus at low effort for structured chapter words', () async {
    late http.Request request;
    final client = ClaudeClient(
      httpClient: MockClient((r) async {
        request = r;
        return message([
          {'term': 'Vault', 'hebrew': 'כספת', 'definition': 'A locked room.'},
        ]);
      }),
    );

    final words = await client.chapterWords(
      reading: reading,
      apiKey: ' key ',
      alreadySuggested: ['dodge'],
      tooEasy: ['door'],
      rightLevel: ['gleam'],
    );

    final body = jsonDecode(request.body) as Map;
    final input = jsonDecode((body['messages'] as List).single['content']);
    expect(request.url.toString(), 'https://api.anthropic.com/v1/messages');
    expect(request.headers['x-api-key'], 'key');
    expect(request.headers['anthropic-version'], isNotEmpty);
    expect(body['model'], 'claude-opus-5-5');
    expect(body['output_config']['effort'], 'low');
    expect(body['output_config']['format']['type'], 'json_schema');
    expect(input['book'], "Harry Potter and the Philosopher's Stone");
    expect(input['alsoPublishedAs'], "Harry Potter and the Sorcerer's Stone");
    expect(input['chapter'], 5);
    expect(input['alreadySuggested'], ['dodge']);
    expect(input['learnerFindsTooEasy'], ['door']);
    expect(input['learnerChoseToLearn'], ['gleam']);
    expect(words.single.key, 'vault');
    expect(words.single.term, 'Vault');
    expect(words.single.meaning, 'כספת; A locked room.');
  });

  test('names the epilogue instead of a chapter number', () async {
    late http.Request request;
    final client = ClaudeClient(
      httpClient: MockClient((r) async {
        request = r;
        return message(const []);
      }),
    );
    final book = readingBooks.last;
    await client.chapterWords(
      reading: Reading(book, book.chapterCount),
      apiKey: 'key',
    );
    final body = jsonDecode(request.body) as Map;
    final input = jsonDecode((body['messages'] as List).single['content']);
    expect(input['chapter'], 'epilogue');
  });

  test('a missing key fails without a request', () async {
    var calls = 0;
    final client = ClaudeClient(
      httpClient: MockClient((_) async {
        calls++;
        return message(const []);
      }),
    );
    await expectLater(
      client.chapterWords(reading: reading, apiKey: '  '),
      throwsA(
        isA<ClaudeException>().having(
          (e) => e.type,
          'type',
          ClaudeErrorType.missingKey,
        ),
      ),
    );
    expect(calls, 0);
  });

  test('classifies HTTP failures', () async {
    expect(
      await errorFor(http.Response('{}', 401)),
      ClaudeErrorType.rejectedKey,
    );
    expect(await errorFor(http.Response('{}', 402)), ClaudeErrorType.billing);
    expect(
      await errorFor(http.Response('Your credit balance is too low', 400)),
      ClaudeErrorType.billing,
    );
    expect(
      await errorFor(http.Response('{}', 429)),
      ClaudeErrorType.rateLimited,
    );
    expect(
      await errorFor(http.Response('{}', 529)),
      ClaudeErrorType.unavailable,
    );
    expect(
      await errorFor(http.Response('{}', 400)),
      ClaudeErrorType.rejectedRequest,
    );
  });

  test('refusals, cut-off and malformed answers are unusable', () async {
    expect(
      await errorFor(message(const [], stopReason: 'refusal')),
      ClaudeErrorType.unusableResponse,
    );
    expect(
      await errorFor(message(const [], stopReason: 'max_tokens')),
      ClaudeErrorType.unusableResponse,
    );
    expect(
      await errorFor(http.Response('{"content": []}', 200)),
      ClaudeErrorType.unusableResponse,
    );
    expect(
      await errorFor(http.Response('not json', 200)),
      ClaudeErrorType.unusableResponse,
    );
  });

  test('network failures and timeouts are reported as such', () async {
    final offline = ClaudeClient(
      httpClient: MockClient((_) async => throw http.ClientException('down')),
    );
    await expectLater(
      offline.chapterWords(reading: reading, apiKey: 'key'),
      throwsA(
        isA<ClaudeException>().having(
          (e) => e.type,
          'type',
          ClaudeErrorType.network,
        ),
      ),
    );
    final slow = ClaudeClient(
      timeout: const Duration(milliseconds: 10),
      httpClient: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return message(const []);
      }),
    );
    await expectLater(
      slow.chapterWords(reading: reading, apiKey: 'key'),
      throwsA(
        isA<ClaudeException>().having(
          (e) => e.type,
          'type',
          ClaudeErrorType.timeout,
        ),
      ),
    );
  });

  test('testConnection lists models with the key', () async {
    late http.Request request;
    final client = ClaudeClient(
      httpClient: MockClient((r) async {
        request = r;
        return http.Response('{"data": []}', 200);
      }),
    );
    await client.testConnection(apiKey: 'key');
    expect(request.method, 'GET');
    expect(request.url.path, '/v1/models');
    expect(request.headers['x-api-key'], 'key');
  });
}
