import 'dart:io';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts;
  bool _isInitialized = false;
  bool _isVoiceAvailable = false;

  TtsService({FlutterTts? flutterTts}) : _flutterTts = flutterTts ?? FlutterTts();

  bool get isVoiceAvailable => _isVoiceAvailable;

  Future<bool> init() async {
    if (_isInitialized) return _isVoiceAvailable;

    try {
      await _flutterTts.setLanguage('en-US');

      // Check available voices on device
      final voices = await _flutterTts.getVoices;
      bool foundInstalledEnVoice = false;

      if (voices is List) {
        for (final voice in voices) {
          if (voice is Map) {
            final locale = (voice['locale'] ?? '').toString().replaceAll('_', '-');
            if (locale.toLowerCase().startsWith('en-us')) {
              // On Android, check network_required flag ('0' means offline/installed)
              final networkRequired = voice['network_required']?.toString();
              if (Platform.isAndroid) {
                if (networkRequired == '0' || networkRequired == null) {
                  foundInstalledEnVoice = true;
                  try {
                    await _flutterTts.setVoice({
                      'name': voice['name'],
                      'locale': voice['locale'],
                    });
                  } catch (_) {}
                  break;
                }
              } else {
                foundInstalledEnVoice = true;
                break;
              }
            }
          }
        }
      }

      // Fallback: if voices list could not be parsed, test setLanguage result
      if (!foundInstalledEnVoice) {
        final isAvailable = await _flutterTts.isLanguageAvailable('en-US');
        foundInstalledEnVoice = (isAvailable == true || isAvailable == 1 || isAvailable == 'true');
      }

      _isVoiceAvailable = foundInstalledEnVoice;
      _isInitialized = true;
      return _isVoiceAvailable;
    } catch (e) {
      _isVoiceAvailable = false;
      _isInitialized = true;
      return false;
    }
  }

  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;

    if (!_isInitialized) {
      final ok = await init();
      if (!ok) return false;
    } else if (!_isVoiceAvailable) {
      return false;
    }

    try {
      final result = await _flutterTts.speak(text);
      if (result == 1 || result == true) {
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
  }
}
