import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum BadgeType { success, warning, info, primary, neutral }

/// Pill badge for schemes, validation states, and confidence metrics.
class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeType type;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = BadgeType.neutral,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    Color border;

    switch (type) {
      case BadgeType.success:
        bg = AppColors.successBg;
        fg = AppColors.success;
        border = const Color(0xFFC8E6C9);
        break;
      case BadgeType.warning:
        bg = AppColors.warningBg;
        fg = AppColors.warning;
        border = const Color(0xFFFDE68A);
        break;
      case BadgeType.info:
        bg = AppColors.infoBg;
        fg = AppColors.info;
        border = const Color(0xFFC6DAEE);
        break;
      case BadgeType.primary:
        bg = AppColors.surfaceContainerLow;
        fg = AppColors.primary;
        border = AppColors.border;
        break;
      case BadgeType.neutral:
        bg = AppColors.surface;
        fg = AppColors.textSecondary;
        border = AppColors.border;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: fg,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
