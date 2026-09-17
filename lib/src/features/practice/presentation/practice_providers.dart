import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/tts_service.dart';
import 'practice_session_controller.dart';
import 'practice_session_state.dart';

final ttsServiceProvider = Provider<TtsService>((ref) {
  return TtsService();
});

final practiceSessionProvider =
    NotifierProvider<PracticeSessionNotifier, PracticeSessionState>(() {
      return PracticeSessionNotifier();
    });
