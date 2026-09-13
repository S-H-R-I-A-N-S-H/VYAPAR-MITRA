import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/floating_voice_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';

/// Screen 1: Minimalist Mobile Welcome Screen
/// Stitch Reference: Screen 2fd5614d09ca472ab1d486b379e5a3a0
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isHindi = currentLocale.languageCode == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
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
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppConstants.appName,
                            style: AppTypography.headlineSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'AI Business Companion',
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Interactive Language Pill
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/language'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isHindi ? 'हिन्दी' : 'EN',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image Banner with Gradient & Badge
                    TactileCard(
                      padding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          Container(
                            height: 180,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0F2942), Color(0xFF1E4E79)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.business_center_rounded,
                                    size: 54,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'व्यापार मित्र • Vyapar Mitra',
                                    style: AppTypography.titleLarge.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.95),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.verified_rounded,
                                    size: 14,
                                    color: AppColors.success,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isHindi
                                        ? 'सरकारी योजना एवं बाजार प्रमाणित'
                                        : 'Govt Scheme & Market Aligned',
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
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Headline
                    Text(
                      isHindi
                          ? 'अपने व्यापार के सपने को सच बनाएं'
                          : 'Turn Your Business Idea Into Reality',
                      style: AppTypography.headlineLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHindi
                          ? 'स्थानीय बाजार जांचें, सरकारी ऋण खोजें और चरण-दर-चरण आगे बढ़ें।'
                          : 'Validate your local market, discover government loans, and grow step-by-step.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Feature 1: Market Intelligence
                    _buildFeatureCard(
                      icon: Icons.store_mall_directory_rounded,
                      iconColor: AppColors.secondary,
                      iconBg: const Color(0xFFFFF5EC),
                      title: isHindi ? 'स्थानीय बाजार के संकेत' : 'Local Market Signals',
                      subtitle: isHindi
                          ? 'मंडी भाव एवं नजदीकी ग्राहक मांग'
                          : 'Mandi prices & local demand trends',
                    ),

                    const SizedBox(height: 10),

                    // Feature 2: Schemes & Loans
                    _buildFeatureCard(
                      icon: Icons.account_balance_rounded,
                      iconColor: AppColors.tertiary,
                      iconBg: AppColors.successBg,
                      title: isHindi ? 'सरकारी योजनाएं व सब्सिडी' : 'Government Schemes & Subsidies',
                      subtitle: isHindi
                          ? 'PMEGP एवं मुद्रा ऋण सहायता'
                          : 'PMEGP & Mudra scheme assistance',
                    ),

                    const SizedBox(height: 10),

                    // Feature 3: Action Checklist
                    _buildFeatureCard(
                      icon: Icons.checklist_rounded,
                      iconColor: AppColors.info,
                      iconBg: AppColors.infoBg,
                      title: isHindi ? 'स्पष्ट कार्ययोजना' : 'Clear Action Checklist',
                      subtitle: isHindi
                          ? 'शुरुआत के लिए 4-हफ्तों का मार्गदर्शन'
                          : 'Step-by-step launch guidance',
                    ),

                    const SizedBox(height: 16),

                    // Offline Reassurance Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.tertiary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHindi
                                  ? 'कम इंटरनेट पर भी सुरक्षित काम करता है'
                                  : 'Works 100% Offline • Low Data Friendly',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Main CTAs
                    PrimaryButton(
                      label: isHindi ? 'शुरुआत करें' : 'Get Started',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () => Navigator.pushNamed(context, '/language'),
                    ),

                    const SizedBox(height: 10),

                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.border, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isHindi ? 'क्या आपके पास पहले से योजना है?' : 'Already have an idea?',
                              style: AppTypography.labelMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: AppColors.secondary),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Sticky Bottom Voice Bar
            FloatingVoiceBar(
              onMicTap: () {
                Navigator.pushNamed(context, '/interview');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return TactileCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
