import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

enum VoiceState { idle, recording, processing, playing }

/// Unified hardware voice recording and audio playback service.
/// Connects Flutter microphone stream to Bhashini ASR and plays synthesized TTS voice responses.
class VoiceService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  final ValueNotifier<VoiceState> stateNotifier = ValueNotifier(VoiceState.idle);
  String? _currentRecordingPath;
  StreamSubscription? _playerCompleteSub;

  VoiceState get currentState => stateNotifier.value;
  bool get isRecording => stateNotifier.value == VoiceState.recording;
  bool get isPlaying => stateNotifier.value == VoiceState.playing;

  VoiceService() {
    _player.onPlayerComplete.listen((_) {
      stateNotifier.value = VoiceState.idle;
    });
  }

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      debugPrint('VoiceService hasPermission error: $e');
      return false;
    }
  }

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
      if (isPlaying) {
        await _player.stop();
        stateNotifier.value = VoiceState.idle;
      }
    } catch (e) {
      debugPrint('VoiceService stopAudio error: $e');
    }
  }

  void dispose() {
    _playerCompleteSub?.cancel();
    _recorder.dispose();
    _player.dispose();
    stateNotifier.dispose();
  }
}

final voiceServiceProvider = Provider<VoiceService>((ref) {
  final service = VoiceService();
  ref.onDispose(() => service.dispose());
  return service;
});
