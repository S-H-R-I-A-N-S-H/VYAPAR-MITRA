import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Standard top application bar following Stitch "Empowered Enterprise" specifications.
/// Includes optional back navigation, branding, step badge, audio assist, and progress bar.
class VyaparTopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final String? stepText;
  final double? progress; // 0.0 to 1.0
  final bool showBackButton;
  final VoidCallback? onBack;
  final bool showAudioButton;
  final VoidCallback? onAudioTap;
  final Widget? trailing;

  const VyaparTopAppBar({
    super.key,
    this.title = 'VYAPAR MITRA',
    this.subtitle,
    this.stepText,
    this.progress,
    this.showBackButton = true,
    this.onBack,
    this.showAudioButton = false,
    this.onAudioTap,
    this.trailing,
  });

  @override
  Size get preferredSize => Size.fromHeight(
      progress != null ? 68.0 : (subtitle != null ? 66.0 : 60.0));

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: Row(
                children: [
                  if (showBackButton)
                    InkWell(
                      onTap: onBack ?? () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.storefront_rounded,
                          size: 22,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: AppTypography.headlineSmall.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null)
                          Text(
                            subtitle!,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  if (stepText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        stepText!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (showAudioButton) ...[
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onAudioTap ?? () {},
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.volume_up_rounded,
                              size: 16,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Listen',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (trailing != null) ...[
                    const SizedBox(width: 8),
                    trailing!,
                  ],
                ],
              ),
            ),
            if (progress != null)
              Container(
                height: 3,
                width: double.infinity,
                color: AppColors.border.withValues(alpha: 0.5),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress!.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(2),
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
