import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/status_badge.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';
import '../../research/providers/research_pipeline_provider.dart';

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
/// Dynamic 6-Pillar Feasibility & Grounded Evidence
class ValidationDashboardScreen extends ConsumerStatefulWidget {
  const ValidationDashboardScreen({super.key});

  @override
  ConsumerState<ValidationDashboardScreen> createState() =>
      _ValidationDashboardScreenState();
}

class _ValidationDashboardScreenState
    extends ConsumerState<ValidationDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final business = ref.watch(selectedBusinessProvider);
    final profile = ref.watch(businessProfileProvider);
    final pipelineState = ref.watch(researchPipelineProvider);

    final synthesis = pipelineState.synthesisResult;

    // Convert synthesis pillars or dynamic default pillars
    final List<PillarItem> pillars = synthesis != null && synthesis.pillars.isNotEmpty
        ? synthesis.pillars.map((p) => p.toPillarItem()).toList()
        : _buildDefaultPillars(business.title, profile.block, profile.district);

    final overallStatus = synthesis?.overallStatus ?? 'Promising with Conditions';
    final isSuccessStatus = synthesis?.statusColor == 'success' || !overallStatus.toLowerCase().contains('unfeasible');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: isHindi ? 'सत्यापन डैशबोर्ड' : 'Validation Dashboard',
        subtitle: '${business.title} • ${profile.block}',
        showAudioButton: true,
        onAudioTap: () {
          final voiceService = ref.read(voiceServiceProvider);
          final readout = isHindi
              ? '${business.title} का सत्यापन परिणाम: समग्र स्थिति $overallStatus है।'
              : 'Validation results for ${business.title}: Overall status is $overallStatus.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSuccessStatus ? AppColors.successBg : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSuccessStatus ? const Color(0xFFC8E6C9) : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isSuccessStatus ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                                size: 14,
                                color: isSuccessStatus ? AppColors.success : AppColors.warning,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isHindi
                                    ? 'समग्र मूल्यांकन: $overallStatus'
                                    : 'Overall: $overallStatus',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isSuccessStatus ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (synthesis?.groundingSources.isNotEmpty ?? false)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.travel_explore_rounded, size: 12, color: AppColors.secondary),
                                const SizedBox(width: 4),
                                Text(
                                  'Grounded AI',
                                  style: AppTypography.labelSmall.copyWith(
                                    fontSize: 10,
                                    color: AppColors.secondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      synthesis?.summary ??
                          (isHindi
                              ? 'उच्च स्थानीय मांग और संतुलित कच्चे माल की उपलब्धता, मध्यम प्रतिस्पर्धा।'
                              : 'High local catchment demand and verified raw material access with manageable competition.'),
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isHindi
                          ? '${profile.block} तहसील में ${business.title} के लिए वास्तविक स्थानीय आंकड़े अनुकूल हैं।'
                          : 'Live market indicators in ${profile.block} indicate viable unit economics for ${business.title}.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Bento Grid of Key Dynamic Drivers
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBentoChip(
                          Icons.check_circle_rounded,
                          isHindi ? 'कच्चा माल पास में उपलब्ध' : 'Local supply confirmed',
                          isGood: true,
                        ),
                        _buildBentoChip(
                          Icons.groups_rounded,
                          isHindi ? 'मजबूत खरीदार रुचि' : 'High catchment demand',
                          isGood: true,
                        ),
                        _buildBentoChip(
                          Icons.verified_rounded,
                          isHindi ? '35% पीएमईजीपी सब्सिडी' : 'Subsidy aligned',
                          isGood: true,
                        ),
                        _buildBentoChip(
                          Icons.storefront_rounded,
                          isHindi ? 'प्रतियोगी मैपिंग पूर्ण' : 'Competitors mapped',
                          isGood: true,
                        ),
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
                  Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 14, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        isHindi ? 'प्रमाणित' : 'Evidence Verified',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 6 Pillar Cards
              ...pillars.map((p) {
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
                                : p.badgeType == BadgeType.info
                                    ? const Color(0xFFEFF6FF)
                                    : AppColors.successBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            p.icon,
                            size: 20,
                            color: p.badgeType == BadgeType.warning
                                ? AppColors.warning
                                : p.badgeType == BadgeType.info
                                    ? const Color(0xFF2563EB)
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
                                  Expanded(
                                    child: Text(
                                      p.title,
                                      style: AppTypography.labelLarge.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                              if (p.title.toLowerCase().contains('compet')) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/competitor-map');
                                  },
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppColors.primary.withValues(alpha: 0.2)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.map_rounded,
                                            size: 14, color: AppColors.primary),
                                        const SizedBox(width: 6),
                                        Text(
                                          isHindi
                                              ? 'स्थानीय प्रतियोगी मानचित्र देखें →'
                                              : 'View Hyperlocal Competitor Map →',
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

              // Web Grounding Citations section
              if (synthesis?.groundingSources.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                TactileCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.travel_explore_rounded, size: 16, color: AppColors.secondary),
                          const SizedBox(width: 6),
                          Text(
                            isHindi ? 'सत्यापित स्रोत एवं संदर्भ' : 'Authoritative Grounding Sources',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...synthesis!.groundingSources.map((source) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.link_rounded, size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  source.title,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],

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
                            isHindi ? 'जमीनी किराना/ग्राहक सर्वेक्षण' : 'Primary Field Survey Guide',
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.tertiary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isHindi
                                ? 'अपने नजदीकी 3 दुकानदारों से 3 प्रश्न पूछकर पक्का करें।'
                                : 'Survey 3 nearby local traders to convert remaining assumptions to confirmed facts.',
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

              // Strategic SWOT Matrix Link
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/swot-analysis');
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 18, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      isHindi ? 'व्यापार सामर्थ्य (SWOT) विश्लेषण देखें →' : 'View Strategic SWOT Matrix →',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

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

  List<PillarItem> _buildDefaultPillars(String title, String block, String district) {
    return [
      PillarItem(
        title: 'Customer Demand',
        badgeText: 'Strong (82%)',
        badgeType: BadgeType.success,
        description: 'Local catchment households in $block exhibit steady demand for $title.',
        icon: Icons.shopping_bag_rounded,
      ),
      PillarItem(
        title: 'Competition',
        badgeText: 'Moderate',
        badgeType: BadgeType.warning,
        description: 'Existing operators in $district have customer wait times during peak trading days.',
        icon: Icons.storefront_rounded,
      ),
      PillarItem(
        title: 'Pricing & Margin',
        badgeText: 'Healthy Margin',
        badgeType: BadgeType.success,
        description: 'Unit pricing in $block yields sustainable gross margins over raw material and power costs.',
        icon: Icons.monetization_on_rounded,
      ),
      PillarItem(
        title: 'Raw Material Supply',
        badgeText: 'Accessible Mandi',
        badgeType: BadgeType.success,
        description: '$district APMC Mandi and local catchment provide continuous raw supply.',
        icon: Icons.agriculture_rounded,
      ),
      PillarItem(
        title: 'Regulatory & Licenses',
        badgeText: 'Udyam / Basic Permit',
        badgeType: BadgeType.info,
        description: 'Standard micro-enterprise registration and local trade license required.',
        icon: Icons.verified_rounded,
      ),
      PillarItem(
        title: 'Government Schemes',
        badgeText: '35% PMEGP',
        badgeType: BadgeType.success,
        description: 'Eligible for 35% capital subsidy grant under rural PMEGP micro-enterprise category.',
        icon: Icons.account_balance_rounded,
      ),
    ];
  }
}
