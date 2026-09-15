import 'package:flutter_test/flutter_test.dart';
import 'package:knew/src/features/practice/data/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TtsService', () {
    test('initializes and handles missing voice gracefully without throwing exceptions', () async {
      final ttsService = TtsService();
      // On desktop unit test environment where native TTS channel is absent, init returns false
      final ok = await ttsService.init();
      expect(ok, isFalse);
      expect(ttsService.isVoiceAvailable, isFalse);
    });

    test('speak returns false when voice is unavailable', () async {
      final ttsService = TtsService();
      final result = await ttsService.speak('hello');
      expect(result, isFalse);
    });
  });
}
