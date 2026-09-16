import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/tactile_card.dart';

/// Screen: Analyzer (Business Analysis Hub)
/// Conforms to SIH 26091 App UI Specification (Section 5.2)
/// A single consolidated place for all research, validation, and decision-support work.
class AnalyzerScreen extends ConsumerWidget {
  const AnalyzerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final profile = ref.watch(businessProfileProvider);
    final business = ref.watch(selectedBusinessProvider);

    final businessTitle = business.title.isNotEmpty
        ? business.title
        : (profile.businessIdea.isNotEmpty
            ? profile.businessIdea
            : (isHindi ? 'कोल्ड-प्रेस सरसों तेल मिल' : 'Cold-Press Mustard Oil Mill'));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hub Header ──────────────────────────────────────────────────────
              Text(
                isHindi ? 'व्यापार विश्लेषक हब' : 'Business Analyzer Hub',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHindi
                    ? 'सभी बाजार अनुसंधान, जमीनी साक्ष्य और व्यवहार्यता विश्लेषण एक स्थान पर।'
                    : 'A single place for all market research, ground evidence, and decision support.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              // ── Active Business Header Card ─────────────────────────────────────
              TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFC6DAEE)),
                          ),
                          child: Text(
                            isHindi ? 'सत्यापन प्रक्रिया सक्रिय' : 'ANALYSIS STATUS: VALIDATING',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.info,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, size: 14, color: AppColors.secondary),
                            const SizedBox(width: 4),
                            Text(
                              '${profile.block}, ${profile.district}',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      businessTitle,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business.domain,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Evidence Provenance Banner ───────────────────────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.fact_check_rounded, color: AppColors.tertiary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'साक्ष्य स्रोत: प्राथमिक + द्वितीयक' : 'Evidence: Primary + Secondary',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            isHindi
                                ? 'द्वितीयक डेटा 3/3 सत्यापित • जमीनी फील्ड सर्वे की आवश्यकता है'
                                : 'Secondary data verified • 1 field survey recommended for pricing',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Analysis Modules List ────────────────────────────────────────────
              Text(
                isHindi ? 'विश्लेषण एवं सत्यापन मॉड्यूल' : 'Analysis & Validation Modules',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              // Module 1: Business Discovery & Opportunities
              _buildModuleCard(
                context: context,
                icon: Icons.lightbulb_rounded,
                title: isHindi ? '1. व्यवसाय अवसर खोज' : '1. Business Opportunity Discovery',
                subtitle: isHindi
                    ? 'स्थानीय क्षमता व पूंजी के अनुसार 3-5 श्रेष्ठ अवसर'
                    : '3-5 curated opportunities fitting your capital and locality',
                tag: isHindi ? 'तैयार' : 'Curated',
                route: '/opportunities',
                statusColor: AppColors.success,
              ),

              // Module 2: Business Definition Checkpoint
              _buildModuleCard(
                context: context,
                icon: Icons.assignment_turned_in_rounded,
                title: isHindi ? '2. व्यवसाय परिभाषा व पुष्टि' : '2. Business Definition Checkpoint',
                subtitle: isHindi
                    ? 'उत्पाद, लक्षित ग्राहक, कार्यक्षेत्र और पैमाने की पुष्टि'
                    : 'Confirm target customers, operating scale, and location',
                tag: isHindi ? 'पुष्टि' : 'Confirmed',
                route: '/business-confirmation',
                statusColor: AppColors.success,
              ),

              // Module 3: Secondary Market Research & Demand
              _buildModuleCard(
                context: context,
                icon: Icons.travel_explore_rounded,
                title: isHindi ? '3. बाजार मांग व अनुसंधान' : '3. Market Demand & Research',
                subtitle: isHindi
                    ? 'मंडी डेटा, क्षेत्रीय खपत और सरकारी एमएसएमई साक्ष्य'
                    : 'Mandi pricing trends, local catchment demand, and MSME data',
                tag: isHindi ? 'प्रगति पर' : 'Active',
                route: '/research-progress',
                statusColor: AppColors.info,
              ),

              // Module 4: Competitor Map & Field Signals
              _buildModuleCard(
                context: context,
                icon: Icons.map_rounded,
                title: isHindi ? '4. प्रतियोगी मानचित्र' : '4. Competitor Map & Territory',
                subtitle: isHindi
                    ? 'स्थानीय मिलों की दूरी, क्षमता व मूल्य निर्धारण'
                    : 'GPS mapping of competing mills, capacity, and price bands',
                tag: isHindi ? '4 मिले' : '4 Mapped',
                route: '/competitor-map',
                statusColor: AppColors.secondary,
              ),

              // Module 5: Feasibility Analysis (6 Pillars)
              _buildModuleCard(
                context: context,
                icon: Icons.dashboard_customize_rounded,
                title: isHindi ? '5. व्यवहार्यता के 6 आधार स्तंभ' : '5. Feasibility (6 Pillars)',
                subtitle: isHindi
                    ? 'मांग, प्रतिस्पर्धा, मूल्य, क्रय शक्ति, वितरण और जोखिम'
                    : 'Demand, competition, pricing, purchasing power, channels, risk',
                tag: isHindi ? '84% व्यवहार्य' : '84% Score',
                route: '/validation-dashboard',
                statusColor: AppColors.tertiary,
              ),

              // Module 6: Strategic SWOT Matrix
              _buildModuleCard(
                context: context,
                icon: Icons.grid_view_rounded,
                title: isHindi ? '6. सामर्थ्य (SWOT) विश्लेषण' : '6. Strategic SWOT Matrix',
                subtitle: isHindi
                    ? 'ताकत, कमजोरियां, अवसर और खतरों का स्पष्ट ढांचा'
                    : 'Strengths, weaknesses, market opportunities, and threats',
                tag: isHindi ? 'समीक्षित' : 'Reviewed',
                route: '/swot-analysis',
                statusColor: AppColors.primary,
              ),

              // Module 7: Final Recommendation & Action Plan
              _buildModuleCard(
                context: context,
                icon: Icons.verified_rounded,
                title: isHindi ? '7. अंतिम सिफारिश व कार्ययोजना' : '7. Final Recommendation & Plan',
                subtitle: isHindi
                    ? 'एआई निर्णय सारांश, ग्रीन लाइट और 7-दिवसीय चेकलिस्ट'
                    : 'Executive decision view, confidence rating, and action checklist',
                tag: isHindi ? 'हरी झंडी' : 'Green Light',
                route: '/action-plan',
                statusColor: AppColors.success,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String tag,
    required String route,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: TactileCard(
        onTap: () => Navigator.pushNamed(context, route),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: statusColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: AppTypography.labelSmall.copyWith(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}
