import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'signaling_service.dart';

class SpeechToTextService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;
  final SignalingService signalingService;
  bool isMutedForSending = false;

  SpeechToTextService(this.signalingService);

  Future<void> initialize() async {
    try {
      _isInitialized = await _speechToText.initialize(
        onStatus: (status) {
          if (kDebugMode) print('STT Status: $status');
        },
        onError: (errorNotification) {
          if (kDebugMode) print('STT Error: $errorNotification');
        },
      );
    } catch (e) {
      if (kDebugMode) print('STT Init Error: $e');
    }
  }

  void startListening(String roomId, String userId, String role) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_isInitialized) {
      _speechToText.listen(
        onResult: (result) {
          if (!isMutedForSending) {
            signalingService.sendMessage({
              'type': 'transcript',
              'room_id': roomId,
              'speaker_id': userId,
              'role': role,
              'text': result.recognizedWords,
              'is_final': result.finalResult,
              'timestamp': DateTime.now().toUtc().toIso8601String(),
            });
          }

          if (result.finalResult) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (true) {
                startListening(roomId, userId, role);
              }
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        localeId: 'th_TH', // You can make this dynamic or user-selected
        cancelOnError: false,
        listenMode: stt.ListenMode.dictation,
      );
    }
  }

  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }

  bool get isListening => _speechToText.isListening;
}
