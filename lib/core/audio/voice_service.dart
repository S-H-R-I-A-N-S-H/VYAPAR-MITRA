import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

enum VoiceState { idle, recording, processing, playing }

/// Unified voice and speech intelligence service for Vyapar Mitra.
/// Handles:
/// 1. Native client-side Speech-to-Text (STT) for Indian English & Hindi without requiring server quotas.
/// 2. Native client-side Text-to-Speech (TTS) for natural vernacular responses.
/// 3. Raw audio WAV recording and Base64 streaming to FastAPI / Bhashini backend.
/// 4. Resilient audio playback from base64 streams or network endpoints.
class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  final ValueNotifier<VoiceState> stateNotifier = ValueNotifier(VoiceState.idle);
  final ValueNotifier<String> liveWordsNotifier = ValueNotifier<String>('');
  String? _currentRecordingPath;
  StreamSubscription? _playerCompleteSub;
  bool _speechInitialized = false;

  VoiceState get currentState => stateNotifier.value;
  String get liveWords => liveWordsNotifier.value;
  bool get isRecording => stateNotifier.value == VoiceState.recording;
  bool get isPlaying => stateNotifier.value == VoiceState.playing;

  void clearLiveWords() {
    liveWordsNotifier.value = '';
  }

  VoiceService() {
    _player.onPlayerComplete.listen((_) {
      stateNotifier.value = VoiceState.idle;
    });

    try {
      _flutterTts.setCompletionHandler(() {
        stateNotifier.value = VoiceState.idle;
      });
      _flutterTts.setErrorHandler((_) {
        stateNotifier.value = VoiceState.idle;
      });
    } catch (e) {
      debugPrint('FlutterTts initialization warning: $e');
    }
  }

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('VoiceService hasPermission error: $e');
      return false;
    }
  }

  /// Initialize native client-side speech recognition
  Future<bool> initializeSpeech() async {
    if (_speechInitialized) return true;
    try {
      _speechInitialized = await _speechToText.initialize(
        onError: (err) => debugPrint('STT Error: ${err.errorMsg}'),
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (stateNotifier.value == VoiceState.recording) {
              stateNotifier.value = VoiceState.idle;
            }
          }
        },
      );
      return _speechInitialized;
    } catch (e) {
      debugPrint('STT initialize failed: $e');
      return false;
    }
  }

  /// Start on-device speech-to-text recognition with vernacular locale support
  Future<void> startListening({
    required void Function(String words, bool isFinal) onResult,
    String languageCode = 'hi',
  }) async {
    try {
      await stopAudio();
      liveWordsNotifier.value = '';
      final available = await initializeSpeech();
      if (!available) {
        // Fall back to WAV recording if STT engine not available on platform
        await startRecording();
        return;
      }

      final localeId = languageCode == 'hi' ? 'hi_IN' : 'en_IN';
      stateNotifier.value = VoiceState.recording;

      await _speechToText.listen(
        onResult: (result) {
          liveWordsNotifier.value = result.recognizedWords;
          onResult(result.recognizedWords, result.finalResult);
          if (result.finalResult) {
            stateNotifier.value = VoiceState.idle;
          }
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.confirmation,
          cancelOnError: true,
          localeId: localeId,
        ),
      );
    } catch (e) {
      debugPrint('startListening error: $e');
      stateNotifier.value = VoiceState.idle;
      liveWordsNotifier.value = '';
    }
  }

  /// Stop native speech recognition
  Future<void> stopListening() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop().catchError((_) {});
      }
      stateNotifier.value = VoiceState.idle;
    } catch (e) {
      debugPrint('stopListening error: $e');
      stateNotifier.value = VoiceState.idle;
    }
  }

  /// Speak vernacular text aloud via native TTS
  Future<void> speakText(
    String text, {
    String languageCode = 'hi',
    VoidCallback? onComplete,
  }) async {
    try {
      if (text.isEmpty) return;
      await stopAudio();

      stateNotifier.value = VoiceState.playing;
      final locale = languageCode == 'hi' ? 'hi-IN' : 'en-IN';
      await _flutterTts.setLanguage(locale);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setSpeechRate(0.9);

      _flutterTts.setCompletionHandler(() {
        stateNotifier.value = VoiceState.idle;
        onComplete?.call();
      });

      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('speakText error: $e');
      stateNotifier.value = VoiceState.idle;
    }
  }

  /// Record raw audio to WAV file
  Future<void> startRecording() async {
    try {
      final hasPerm = await hasPermission();
      if (!hasPerm) {
        throw Exception('Microphone permission not granted');
      }

      await stopAudio();

      if (kIsWeb) {
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
          path: '',
        );
      } else {
        final tempDir = Directory.systemTemp;
        _currentRecordingPath =
            '${tempDir.path}/vm_voice_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000),
          path: _currentRecordingPath!,
        );
      }
      stateNotifier.value = VoiceState.recording;
    } catch (e) {
      debugPrint('VoiceService startRecording error: $e');
      stateNotifier.value = VoiceState.idle;
      rethrow;
    }
  }

  Future<String?> stopRecordingAndGetBase64() async {
    try {
      if (!isRecording) return null;
      stateNotifier.value = VoiceState.processing;
      final path = await _recorder.stop();
      String? base64Result;

      if (path != null && path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) {
            base64Result = base64Encode(bytes);
          }
          try {
            await file.delete();
          } catch (_) {}
        }
      }

      stateNotifier.value = VoiceState.idle;
      return base64Result;
    } catch (e) {
      debugPrint('VoiceService stopRecording error: $e');
      stateNotifier.value = VoiceState.idle;
      return null;
    }
  }

  Future<void> playAudioFromBase64(
    String base64Audio, {
    VoidCallback? onComplete,
  }) async {
    try {
      if (base64Audio.isEmpty) return;
      await stopAudio();

      final bytes = base64Decode(base64Audio);
      stateNotifier.value = VoiceState.playing;

      _playerCompleteSub?.cancel();
      _playerCompleteSub = _player.onPlayerComplete.listen((_) {
        stateNotifier.value = VoiceState.idle;
        onComplete?.call();
      });

      await _player.play(BytesSource(bytes));
    } catch (e) {
      debugPrint('VoiceService playAudioFromBase64 error: $e');
      stateNotifier.value = VoiceState.idle;
    }
  }

  Future<void> stopAudio() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop().catchError((_) {});
      }
      try {
        await _flutterTts.stop().catchError((_) {});
      } catch (_) {}
      if (isPlaying) {
        await _player.stop().catchError((_) {});
      }
      stateNotifier.value = VoiceState.idle;
    } catch (e) {
      debugPrint('VoiceService stopAudio error: $e');
      stateNotifier.value = VoiceState.idle;
    }
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    try {
      _recorder.dispose().catchError((_) {});
    } catch (_) {}
    try {
      _player.dispose().catchError((_) {});
    } catch (_) {}
    try {
      _speechToText.stop().catchError((_) {});
    } catch (_) {}
    try {
      _flutterTts.stop().catchError((_) {});
    } catch (_) {}
    stateNotifier.dispose();
    liveWordsNotifier.dispose();
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});
