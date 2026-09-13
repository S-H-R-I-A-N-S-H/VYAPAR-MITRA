import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class PillarItem {
  final String title;
  final String badgeText;
  final BadgeType badgeType;
  final String description;
  final IconData icon;

  const PillarItem({
    required this.title,
    required this.badgeText,
    required this.badgeType,
    required this.description,
    required this.icon,
  });
}

/// Screen 8: Validation Dashboard
/// Stitch Reference: Screen 525505f8c8e542d295dbbce2faa1cc2f
class ValidationDashboardScreen extends ConsumerStatefulWidget {
  const ValidationDashboardScreen({super.key});

  @override
  ConsumerState<ValidationDashboardScreen> createState() =>
      _ValidationDashboardScreenState();
}

class _ValidationDashboardScreenState
    extends ConsumerState<ValidationDashboardScreen> {
  final List<PillarItem> _pillars = const [
    PillarItem(
      title: 'Customer Demand',
      badgeText: 'Strong (82%)',
      badgeType: BadgeType.success,
      description: 'Local families prefer fresh unadulterated cold-pressed oil over commercial packaged brands.',
      icon: Icons.shopping_bag_rounded,
    ),
    PillarItem(
      title: 'Competition',
      badgeText: 'Moderate',
      badgeType: BadgeType.warning,
      description: '2 mini-mills operating in weekly haat; customer wait times exceed 45 minutes on market days.',
      icon: Icons.storefront_rounded,
    ),
    PillarItem(
      title: 'Pricing & Margin',
      badgeText: 'Healthy Margin',
      badgeType: BadgeType.success,
      description: 'Retail price ₹180/L yields ₹65/L gross operating margin after seed and power expenses.',
      icon: Icons.monetization_on_rounded,
    ),
    PillarItem(
      title: 'Raw Material Supply',
      badgeText: 'Abundant Local',
      badgeType: BadgeType.success,
      description: 'Sanwer Mandi provides direct farmer-sourced mustard seed without intermediary middlemen.',
      icon: Icons.agriculture_rounded,
    ),
    PillarItem(
      title: 'Regulatory & Licenses',
      badgeText: 'Basic FSSAI',
      badgeType: BadgeType.info,
      description: 'Only basic food registration (₹100/yr) required for micro-capacity under 100 kg/day.',
      icon: Icons.verified_rounded,
    ),
    PillarItem(
      title: 'Government Schemes',
      badgeText: '35% PMEGP',
      badgeType: BadgeType.success,
      description: 'Eligible for 35% capital subsidy (₹63,000 grant) under rural PMEGP micro-enterprise category.',
      icon: Icons.account_balance_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final business = ref.watch(selectedBusinessProvider);
    final profile = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'Validation Dashboard',
        subtitle: '${business.title} • ${profile.block}',
        showAudioButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Assessment Hero Card
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 14, color: AppColors.success),
                          const SizedBox(width: 4),
                          Text(
                            isHindi
                                ? 'समग्र मूल्यांकन: अनुकूल (शर्तों के साथ)'
                                : 'Overall: Promising with Conditions',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      isHindi
                          ? 'उच्च स्थानीय मांग और प्रचुर कच्चा माल, मध्यम प्रतियोगी स्तर।'
                          : 'High local household demand and abundant seed supply, with moderate local competition.',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isHindi
                          ? '${profile.block} तहसील में शुद्ध तेल की बढ़ती मांग आपके व्यवसाय के पक्ष में है।'
                          : 'Market conditions in ${profile.block} favor an automated micro oil expeller targeting village households.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bento Grid of Key Drivers
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBentoChip(Icons.check_circle_rounded, 'Raw material nearby', isGood: true),
                        _buildBentoChip(Icons.groups_rounded, '18/25 buyers interested', isGood: true),
                        _buildBentoChip(Icons.verified_rounded, '35% PMEGP subsidy', isGood: true),
                        _buildBentoChip(Icons.warning_rounded, '2 mills within 7 km', isGood: false),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Section Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isHindi ? 'सत्यापन के 6 आधार स्तंभ' : '6 Validation Pillars',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'All Verified',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 6 Pillar Cards
              ..._pillars.map((p) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: TactileCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: p.badgeType == BadgeType.warning
                                ? AppColors.warningBg
                                : AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            p.icon,
                            size: 20,
                            color: p.badgeType == BadgeType.warning
                                ? AppColors.warning
                                : AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    p.title,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  StatusBadge(
                                    label: p.badgeText,
                                    type: p.badgeType,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                p.description,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              if (p.title == 'Competition') ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/competitor-map');
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          isHindi ? 'स्थानीय प्रतियोगी मानचित्र देखें →' : 'View Hyperlocal Competitor Map →',
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: 14),

              // Primary Survey Field Action Card
              TactileCard(
                backgroundColor: const Color(0xFFF0FDF4),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                child: Row(
                  children: [
                    const Icon(Icons.rate_review_rounded,
                        size: 24, color: AppColors.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'ग्रामीण किराना सर्वेक्षण' : 'Primary Field Survey Guide',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isHindi
                                ? 'अपने नजदीकी 3 दुकानदारों से 3 प्रश्न पूछकर पक्का करें।'
                                : 'Survey 3 nearby grocery shops to convert assumptions to confirmed facts.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // CTA to Financial Simulation
              PrimaryButton(
                label: isHindi
                    ? 'वित्तीय योजना व लाभ देखें →'
                    : 'Simulate Financials & What-If →',
                onPressed: () {
                  Navigator.pushNamed(context, '/finance-modeler');
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBentoChip(IconData icon, String text, {required bool isGood}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isGood ? AppColors.successBg : AppColors.warningBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isGood ? const Color(0xFFC8E6C9) : const Color(0xFFFDE68A),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: isGood ? AppColors.success : AppColors.warning),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTypography.labelSmall.copyWith(
              color: isGood ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
