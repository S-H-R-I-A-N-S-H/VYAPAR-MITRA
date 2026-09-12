import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Reusable banner that clearly surfaces market evidence conflicts to the entrepreneur.
class ConflictBanner extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTapAction;

  const ConflictBanner({
    super.key,
    required this.title,
    required this.description,
    this.onTapAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFFB74D)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: const Color(0xFFE65100),
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(description, style: AppTypography.bodyMedium),
          if (onTapAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onTapAction,
                child: const Text('View Evidence Details →'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
