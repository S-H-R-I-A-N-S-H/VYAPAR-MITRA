import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/voice_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'voice_mic_button.dart';

/// An interactive text field that transforms into an animated voice waveform
/// with live transcription whenever Speech-to-Text is active.
class VoiceAwareTextField extends ConsumerStatefulWidget {
  final TextEditingController? controller;
  final String? hintText;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String? languageCode;
  final bool appendTranscription;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final InputDecoration? decoration;
  final TextStyle? style;

  const VoiceAwareTextField({
    super.key,
    this.controller,
    this.hintText,
    this.maxLines = 1,
    this.minLines,
    this.onSubmitted,
    this.onChanged,
    this.languageCode,
    this.appendTranscription = false,
    this.autofocus = false,
    this.textInputAction,
    this.decoration,
    this.style,
  });

  @override
  ConsumerState<VoiceAwareTextField> createState() => _VoiceAwareTextFieldState();
}

class _VoiceAwareTextFieldState extends ConsumerState<VoiceAwareTextField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _internalController;
  late AnimationController _waveformController;
  bool _isListening = false;
  String _initialTextBeforeSpeech = '';

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = TextEditingController();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _waveformController.dispose();
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  void _startVoiceInput(VoiceService voiceService) async {
    FocusScope.of(context).unfocus();
    _initialTextBeforeSpeech = _effectiveController.text;

    final lang = widget.languageCode ?? ref.read(localeProvider).languageCode;
    setState(() {
      _isListening = true;
    });
    _waveformController.repeat();

    await voiceService.startListening(
      languageCode: lang,
      onResult: (words, isFinal) {
        if (!mounted) return;

        if (isFinal) {
          _finishVoiceInput(words);
        }
      },
    );
  }

  void _stopVoiceInput(VoiceService voiceService) async {
    await voiceService.stopListening();
    final liveWords = voiceService.liveWords;
    _finishVoiceInput(liveWords);
  }

  void _finishVoiceInput(String transcribed) {
    if (!mounted) return;

    _waveformController.stop();
    _waveformController.reset();

    if (transcribed.trim().isNotEmpty) {
      final updatedText = widget.appendTranscription && _initialTextBeforeSpeech.isNotEmpty
          ? '$_initialTextBeforeSpeech ${transcribed.trim()}'
          : transcribed.trim();

      _effectiveController.text = updatedText;
      _effectiveController.selection = TextSelection.fromPosition(
        TextPosition(offset: _effectiveController.text.length),
      );

      widget.onChanged?.call(updatedText);
      widget.onSubmitted?.call(updatedText);
    }

    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = ref.watch(voiceServiceProvider);
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    return ValueListenableBuilder<VoiceState>(
      valueListenable: voiceService.stateNotifier,
      builder: (context, voiceState, _) {
        final currentlyRecording = voiceState == VoiceState.recording && _isListening;

        if (!currentlyRecording && _isListening) {
          // Voice service ended externally
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _isListening) {
              _finishVoiceInput(voiceService.liveWords);
            }
          });
        }

        return AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: currentlyRecording
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: _buildStandardTextField(voiceService),
          secondChild: _buildWaveformRecordingBox(voiceService, isHindi),
        );
      },
    );
  }

  Widget _buildStandardTextField(VoiceService voiceService) {
    final baseDecoration = widget.decoration ??
        InputDecoration(
          hintText: widget.hintText ?? 'Type or speak...',
          hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        );

    final effectiveDecoration = baseDecoration.copyWith(
      suffixIcon: Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: VoiceMicButton(
          size: 36,
          hasElevation: false,
          iconColor: AppColors.primary,
          tooltip: 'Tap to speak',
          onTap: () => _startVoiceInput(voiceService),
        ),
      ),
    );

    return TextField(
      controller: _effectiveController,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      autofocus: widget.autofocus,
      textInputAction: widget.textInputAction,
      style: widget.style ?? AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
      decoration: effectiveDecoration,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
    );
  }

  Widget _buildWaveformRecordingBox(VoiceService voiceService, bool isHindi) {
    return Container(
      constraints: BoxConstraints(
        minHeight: widget.maxLines > 1 ? (widget.maxLines * 24.0 + 24.0) : 52.0,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFCDD2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD32F2F).withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Waveform bars animation
          _buildWaveformBars(),
          const SizedBox(width: 12),

          // Live transcribed text or listening status
          Expanded(
            child: ValueListenableBuilder<String>(
              valueListenable: voiceService.liveWordsNotifier,
              builder: (context, liveWords, _) {
                final hasWords = liveWords.trim().isNotEmpty;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      hasWords
                          ? liveWords
                          : (isHindi ? 'सुन रहे हैं... बोलिए' : 'Listening... Speak now'),
                      style: AppTypography.bodyMedium.copyWith(
                        color: hasWords ? AppColors.textPrimary : const Color(0xFFD32F2F),
                        fontWeight: hasWords ? FontWeight.w500 : FontWeight.bold,
                        fontStyle: hasWords ? FontStyle.normal : FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!hasWords)
                      Text(
                        isHindi ? 'बोलना पूरा होने पर रोकें' : 'Tap stop when done',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 10,
                          color: const Color(0xFFE57373),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // Stop button
          Material(
            color: const Color(0xFFD32F2F),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: () => _stopVoiceInput(voiceService),
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformBars() {
    return AnimatedBuilder(
      animation: _waveformController,
      builder: (context, _) {
        final t = _waveformController.value * 2 * math.pi;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final phase = index * (math.pi / 3);
            final heightFactor = (math.sin(t + phase).abs() * 0.7) + 0.3;
            const maxHeight = 28.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2.0),
              width: 3.5,
              height: maxHeight * heightFactor,
              decoration: BoxDecoration(
                color: const Color(0xFFD32F2F).withValues(alpha: 0.7 + (heightFactor * 0.3)),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
