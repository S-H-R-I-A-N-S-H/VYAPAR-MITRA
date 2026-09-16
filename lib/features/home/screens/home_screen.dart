import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/main_navigation_shell.dart';
import '../../../core/models/business_lifecycle.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';

/// Screen: Lifecycle-Aware Home Dashboard
/// Conforms to SIH 26091 App UI Specification (Section 5.1 & Section 10)
/// Answers the core question: "What should I do next?" based on active BusinessLifecycleStage.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final profile = ref.watch(businessProfileProvider);
    final business = ref.watch(selectedBusinessProvider);
    final stage = ref.watch(businessLifecycleProvider);

    final entrepreneurName = (profile.fullName != null && profile.fullName!.isNotEmpty)
        ? profile.fullName!
        : (isHindi ? 'रमेश कुमार' : 'Ramesh Kumar');

    final businessTitle = business.title.isNotEmpty
        ? business.title
        : (profile.businessIdea.isNotEmpty
            ? profile.businessIdea
            : (isHindi ? 'कोल्ड-प्रेस सरसों तेल मिल' : 'Cold-Press Mustard Oil Mill'));

    final locationText = '${profile.block}, ${profile.district} (M.P.)';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Header / Entrepreneur Greeting ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.secondary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isHindi ? 'नमस्ते, $entrepreneurName' : 'Namaste, $entrepreneurName',
                              style: AppTypography.headlineMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                size: 14, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              locationText,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Interactive Stage Switcher Badge (Allows demo/testing across all 7 stages)
                  InkWell(
                    onTap: () => _showStageSelector(context, ref, isHindi),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(stage.icon, size: 14, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            stage.getStageTag(isHindi),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_drop_down, size: 16, color: Colors.white70),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Active Venture Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        businessTitle,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Hero Card: Next Best Action ("What should I do next?") ──────────
              TactileCard(
                padding: const EdgeInsets.all(16),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3), width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Eyebrow badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.warningBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.bolt_rounded, size: 14, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'अगला सबसे महत्वपूर्ण कदम' : 'NEXT BEST ACTION',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(stage.progressValue * 100).toInt()}% ${isHindi ? "पूर्ण" : "Done"}',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Stage Title
                    Text(
                      stage.getTitle(isHindi),
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // "Why this matters" explanation
                    Text(
                      stage.getWhyItMatters(isHindi),
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress indicator bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: stage.progressValue,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                        minHeight: 6,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Primary CTA
                    PrimaryButton(
                      label: stage.getPrimaryCtaLabel(isHindi),
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        final route = stage.getPrimaryCtaRoute();
                        Navigator.pushNamed(context, route);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Quick Actions Row ────────────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickActionChip(
                      icon: Icons.analytics_rounded,
                      label: isHindi ? 'शोध व सबूत' : 'Research',
                      onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      icon: Icons.account_balance_wallet_rounded,
                      label: isHindi ? 'वित्त योजना' : 'Finance',
                      onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 2,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      icon: Icons.menu_book_rounded,
                      label: isHindi ? 'व्यवसाय ज्ञान' : 'Learn',
                      onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 3,
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionChip(
                      icon: Icons.mic_rounded,
                      label: isHindi ? 'बोलकर पूछें' : 'Ask AI',
                      color: AppColors.secondary,
                      onTap: () => Navigator.pushNamed(context, '/conversational-interview'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Supporting Card 1: Research / Validation Progress ────────────────
              TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'शोध एवं जमीनी साक्ष्य' : 'Research & Ground Signals',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isHindi ? 'सत्यापित' : 'Active',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildStatBox('3', isHindi ? 'द्वितीयक स्रोत' : 'Secondary Sources'),
                        const SizedBox(width: 10),
                        _buildStatBox('0', isHindi ? 'फील्ड सर्वे' : 'Field Surveys'),
                        const SizedBox(width: 10),
                        _buildStatBox('2', isHindi ? 'कमियां' : 'Info Gaps', isWarning: true),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => ref.read(bottomNavIndexProvider.notifier).state = 1,
                      child: Row(
                        children: [
                          Text(
                            isHindi ? 'पूर्ण शोध व साक्ष्य डैशबोर्ड खोलें →' : 'View Full Research Hub →',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Supporting Card 2: Financial Snapshot ────────────────────────────
              TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'पूंजी व सरकारी सब्सिडी' : 'Capital & Subsidy Status',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PMEGP / Mudra',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildFinanceItem(
                          isHindi ? 'निजी पूंजी' : 'Own Capital',
                          '₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K',
                        ),
                        _buildFinanceItem(
                          isHindi ? 'अनुमानित लागत' : 'Est. Project Cost',
                          '₹${(business.estimatedCapital / 100000).toStringAsFixed(2)}L',
                        ),
                        _buildFinanceItem(
                          isHindi ? 'सब्सिडी पात्रता' : 'Subsidy Match',
                          '35% PMEGP',
                          color: AppColors.tertiary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, size: 16, color: AppColors.tertiary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              isHindi
                                  ? 'कर्ज पात्रता से अधिक महत्वपूर्ण है कि आप उसे सुरक्षित भर सकें।'
                                  : 'Safety rule: Repayment capacity matters more than eligibility.',
                              style: AppTypography.bodySmall.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Supporting Card 3: Hyper-Local Ground Advisory ───────────────────
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.warningBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.warning.withValues(alpha: 0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: AppColors.warning, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'स्थानीय मंडी अंतर्दृष्टि' : 'Locality Catchment Insight',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isHindi
                                ? 'सांवेर मंडी में सरसों आवक मजबूत है। सीधे किसान स्तर पर खरीद से 18% कच्चा माल लागत लाभ मिल सकता है।'
                                : 'Mandi arrivals are strong in Sanwer. Direct farmer sourcing can yield an 18% raw material margin advantage.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = AppColors.primary,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String value, String label, {bool isWarning = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isWarning ? AppColors.warningBg.withValues(alpha: 0.4) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.headlineSmall.copyWith(
                fontWeight: FontWeight.bold,
                color: isWarning ? AppColors.warning : AppColors.primary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinanceItem(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.primary,
          ),
        ),
      ],
    );
  }

  void _showStageSelector(BuildContext context, WidgetRef ref, bool isHindi) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHindi ? 'व्यापार जीवनचक्र चरण चुनें' : 'Select Business Lifecycle Stage',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                ...BusinessLifecycleStage.values.map((s) {
                  final isCurrent = s == ref.watch(businessLifecycleProvider);
                  return ListTile(
                    leading: Icon(s.icon, color: isCurrent ? AppColors.secondary : AppColors.primary),
                    title: Text(
                      s.getTitle(isHindi),
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.secondary : AppColors.textPrimary,
                      ),
                    ),
                    trailing: isCurrent
                        ? const Icon(Icons.check, color: AppColors.secondary)
                        : null,
                    onTap: () {
                      ref.read(businessLifecycleProvider.notifier).setStage(s);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
