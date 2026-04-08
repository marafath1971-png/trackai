import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../core/utils/logger.dart';

class VoiceService {
  static final SpeechToText _speech = SpeechToText();
  static final FlutterTts _tts = FlutterTts();

  static Future<void> init() async {
    await _speech.initialize(
      onError: (val) => appLogger.e('[VoiceService] Error: $val'),
      onStatus: (val) => appLogger.d('[VoiceService] Status: $val'),
    );
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
  }

  static Future<void> speak(String text) async {
    await _tts.speak(text);
  }

  static Future<void> listen({
    required Function(String) onResult,
    required Function(bool) onListeningChanged,
  }) async {
    bool available = await _speech.initialize();
    if (available) {
      onListeningChanged(true);
      _speech.listen(
        onResult: (val) {
          if (val.finalResult) {
            onResult(val.recognizedWords);
            onListeningChanged(false);
          }
        },
      );
    } else {
      appLogger.w('[VoiceService] Speech recognition not available');
    }
  }

  static Future<void> stop() async {
    await _speech.stop();
  }
}
