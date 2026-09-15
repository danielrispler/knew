import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'practice_session_controller.dart';
import 'practice_session_state.dart';

abstract class TtsService {
  Future<void> speak(String text);
}

class StubTtsService implements TtsService {
  @override
  Future<void> speak(String text) async {}
}

final ttsServiceProvider = Provider<TtsService>((ref) {
  return StubTtsService();
});

final practiceSessionProvider =
    NotifierProvider<PracticeSessionNotifier, PracticeSessionState>(() {
  return PracticeSessionNotifier();
});
