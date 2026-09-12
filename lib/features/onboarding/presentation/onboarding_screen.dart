import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedLanguage = 'hi';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 36),
              ),
              const SizedBox(height: 24),
              Text(
                AppConstants.appName,
                style: AppTypography.displayLarge.copyWith(color: AppColors.primary),
              ),
              const SizedBox(height: 8),
              Text(
                loc?.translate('tagline') ?? 'Evidence-Based Business Advisory & Smart Financing Companion',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Text(
                loc?.translate('select_language') ?? 'Choose language',
                style: AppTypography.titleLarge,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildLangCard('hi', 'हिन्दी'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildLangCard('en', 'English'),
                  ),
                ],
              ),
              const Spacer(),
              PrimaryButton(
                label: loc?.translate('continue_btn') ?? 'Continue',
                onPressed: () {
                  Navigator.pushNamed(context, '/interview');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLangCard(String code, String name) {
    final isSelected = _selectedLanguage == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: AppTypography.titleLarge.copyWith(
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }
}
