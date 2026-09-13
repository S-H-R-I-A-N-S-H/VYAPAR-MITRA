import 'package:flutter/material.dart';
import '../../core/audio/voice_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Floating tactile voice assistant dock adhering to Stitch "Empowered Enterprise" tokens.
/// Features dynamic responsive states for Idle, Recording (active mic wave), Processing, and Playing.
class FloatingVoiceBar extends StatefulWidget {
  final VoidCallback? onMicTap;
  final VoidCallback? onStopTap;
  final VoiceState voiceState;
  final String? customTitle;
  final String? customSubtitle;

  const FloatingVoiceBar({
    super.key,
    this.onMicTap,
    this.onStopTap,
    this.voiceState = VoiceState.idle,
    this.customTitle,
    this.customSubtitle,
  });

  @override
  State<FloatingVoiceBar> createState() => _FloatingVoiceBarState();
}

class _FloatingVoiceBarState extends State<FloatingVoiceBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant FloatingVoiceBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.voiceState == VoiceState.recording) {
      _pulseController.duration = const Duration(milliseconds: 700);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    } else {
      _pulseController.duration = const Duration(milliseconds: 1400);
      if (!_pulseController.isAnimating) _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = widget.voiceState == VoiceState.recording;
    final isProcessing = widget.voiceState == VoiceState.processing;
    final isPlaying = widget.voiceState == VoiceState.playing;

    String displayTitle;
    String displaySubtitle;
    Color indicatorColor;
    Color buttonColor;
    IconData buttonIcon;

    if (isRecording) {
      displayTitle = widget.customTitle ?? 'बोलिए, सुन रहे हैं... • Listening...';
      displaySubtitle = widget.customSubtitle ?? 'बात पूरी होने पर टैप करें • Tap button when done';
      indicatorColor = const Color(0xFFD32F2F);
      buttonColor = const Color(0xFFD32F2F);
      buttonIcon = Icons.stop_rounded;
    } else if (isProcessing) {
      displayTitle = widget.customTitle ?? 'विचार कर रहे हैं... • Processing Voice...';
      displaySubtitle = widget.customSubtitle ?? 'Bhashini ASR & Vyapar Mitra AI...';
      indicatorColor = AppColors.secondary;
      buttonColor = AppColors.secondary;
      buttonIcon = Icons.hourglass_top_rounded;
    } else if (isPlaying) {
      displayTitle = widget.customTitle ?? 'सलाहकार बोल रहे हैं • Advisor Speaking...';
      displaySubtitle = widget.customSubtitle ?? 'रोकने के लिए टैप करें • Tap button to stop audio';
      indicatorColor = AppColors.tertiary;
      buttonColor = AppColors.tertiary;
      buttonIcon = Icons.stop_rounded;
    } else {
      displayTitle = widget.customTitle ?? 'बोलकर पूछें / Tap to Speak';
      displaySubtitle = widget.customSubtitle ?? 'Ask any business question in your own voice';
      indicatorColor = AppColors.secondary;
      buttonColor = AppColors.secondary;
      buttonIcon = Icons.mic_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background.withValues(alpha: 0.0),
            AppColors.background.withValues(alpha: 0.95),
            AppColors.background,
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isRecording ? const Color(0xFFFFF4F2) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecording ? const Color(0xFFFFCDD2) : AppColors.border,
            width: isRecording ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isRecording
                  ? const Color(0xFFD32F2F).withValues(alpha: 0.12)
                  : AppColors.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: indicatorColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: AppTypography.labelMedium.copyWith(
                            color: isRecording ? const Color(0xFFB71C1C) : AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    displaySubtitle,
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 11,
                      color: isRecording ? const Color(0xFFC62828) : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final pulseVal = _pulseController.value;
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: buttonColor.withValues(
                          alpha: isRecording
                              ? (0.2 + (pulseVal * 0.3))
                              : (0.12 + (pulseVal * 0.12)),
                        ),
                        blurRadius: isRecording
                            ? (12 + (pulseVal * 12))
                            : (8 + (pulseVal * 6)),
                        spreadRadius: isRecording
                            ? (3 + (pulseVal * 4))
                            : (1 + (pulseVal * 2)),
                      ),
                    ],
                  ),
                  child: child,
                );
              },
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (isRecording || isPlaying) {
                      if (widget.onStopTap != null) {
                        widget.onStopTap!();
                      } else {
                        widget.onMicTap?.call();
                      }
                    } else if (!isProcessing) {
                      widget.onMicTap?.call();
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: buttonColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(
                              buttonIcon,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
