import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio/voice_service.dart';
import '../../core/providers/app_providers.dart';
import '../../core/theme/app_colors.dart';

/// Compact, tactile microphone button with micro-animations for STT & TTS.
/// Suitable for standalone floating action buttons or inline inside text fields.
class VoiceMicButton extends ConsumerStatefulWidget {
  final VoiceState? voiceState;
  final VoidCallback? onTap;
  final void Function(String words, bool isFinal)? onTranscribed;
  final String? languageCode;
  final double size;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? iconColor;
  final String? tooltip;
  final bool hasElevation;
  final VoiceService? customVoiceService;

  const VoiceMicButton({
    super.key,
    this.voiceState,
    this.onTap,
    this.onTranscribed,
    this.languageCode,
    this.size = 42.0,
    this.backgroundColor,
    this.activeColor,
    this.iconColor,
    this.tooltip,
    this.hasElevation = true,
    this.customVoiceService,
  });

  @override
  ConsumerState<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends ConsumerState<VoiceMicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.2, end: 0.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  VoiceService _getVoiceService() {
    return widget.customVoiceService ?? ref.read(voiceServiceProvider);
  }

  void _handleTap(VoiceState effectiveState) async {
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }

    final voiceService = _getVoiceService();
    if (effectiveState == VoiceState.recording) {
      await voiceService.stopListening();
    } else if (effectiveState == VoiceState.playing) {
      await voiceService.stopAudio();
    } else if (effectiveState == VoiceState.idle) {
      final lang = widget.languageCode ??
          ref.read(localeProvider).languageCode;
      await voiceService.startListening(
        languageCode: lang,
        onResult: (words, isFinal) {
          widget.onTranscribed?.call(words, isFinal);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final voiceService = _getVoiceService();

    return ValueListenableBuilder<VoiceState>(
      valueListenable: voiceService.stateNotifier,
      builder: (context, serviceState, _) {
        final state = widget.voiceState ?? serviceState;
        final isRecording = state == VoiceState.recording;
        final isProcessing = state == VoiceState.processing;
        final isPlaying = state == VoiceState.playing;

        if (isRecording) {
          if (!_pulseController.isAnimating) {
            _pulseController.repeat(reverse: true);
          }
        } else {
          if (_pulseController.isAnimating) {
            _pulseController.stop();
            _pulseController.reset();
          }
        }

        final defaultBg = isRecording
            ? (widget.activeColor ?? const Color(0xFFD32F2F))
            : (widget.backgroundColor ?? (widget.hasElevation ? AppColors.primary : Colors.transparent));

        final defaultIconColor = isRecording
            ? Colors.white
            : (widget.iconColor ?? (widget.hasElevation ? Colors.white : AppColors.primary));

        Widget iconWidget;
        if (isProcessing) {
          iconWidget = SizedBox(
            width: widget.size * 0.45,
            height: widget.size * 0.45,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(defaultIconColor),
            ),
          );
        } else if (isPlaying) {
          iconWidget = Icon(
            Icons.volume_up_rounded,
            size: widget.size * 0.52,
            color: defaultIconColor,
          );
        } else if (isRecording) {
          iconWidget = Icon(
            Icons.stop_rounded,
            size: widget.size * 0.56,
            color: Colors.white,
          );
        } else {
          iconWidget = Icon(
            Icons.mic_rounded,
            size: widget.size * 0.52,
            color: defaultIconColor,
          );
        }

        return Tooltip(
          message: widget.tooltip ??
              (isRecording
                  ? 'Tap to stop'
                  : isPlaying
                      ? 'Tap to mute'
                      : 'Tap to speak'),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = isRecording ? _scaleAnimation.value : 1.0;
              final glowAlpha = isRecording ? _glowAnimation.value : 0.0;

              return Transform.scale(
                scale: scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    color: defaultBg,
                    shape: BoxShape.circle,
                    boxShadow: widget.hasElevation || isRecording
                        ? [
                            BoxShadow(
                              color: isRecording
                                  ? const Color(0xFFD32F2F).withValues(alpha: glowAlpha)
                                  : AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: isRecording ? 12 : 6,
                              spreadRadius: isRecording ? 3 : 0,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                    border: !widget.hasElevation && !isRecording
                        ? Border.all(color: AppColors.border, width: 1.0)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _handleTap(state),
                      customBorder: const CircleBorder(),
                      child: Center(child: iconWidget),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
