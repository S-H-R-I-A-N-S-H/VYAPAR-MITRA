import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

/// Screen displaying government scheme recommendations
class SchemeRecommendationsScreen extends ConsumerStatefulWidget {
  const SchemeRecommendationsScreen({super.key});

  @override
  ConsumerState<SchemeRecommendationsScreen> createState() =>
      _SchemeRecommendationsScreenState();
}

class _SchemeRecommendationsScreenState
    extends ConsumerState<SchemeRecommendationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(businessProfileProvider);
      ref.read(schemeRecommendationsProvider.notifier).fetchRecommendations(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final recsState = ref.watch(schemeRecommendationsProvider);
    final profile = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: isHindi ? 'सरकारी योजनाएं' : 'Scheme Recommendations',
        subtitle: '${profile.businessIdea} • ${profile.district}',
        showAudioButton: true,
      ),
      body: SafeArea(
        child: recsState.isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      isHindi
                          ? 'उपयुक्त सरकारी योजनाओं की खोज हो रही है...'
                          : 'Finding suitable government schemes...',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHindi
                          ? 'कठोर पात्रता नियमों व सब्सिडी गणना का सत्यापन...'
                          : 'Evaluating eligibility rules & calculating benefits...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Banner
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_balance_rounded,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi
                                      ? 'आपके व्यवसाय के लिए अनुशंसित योजनाएं'
                                      : 'Matched Government Schemes',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isHindi
                                      ? 'प्रत्येक योजना 100% नियमों और वित्तीय मॉडल पर आधारित है'
                                      : 'Strict rules-based matching with verified subsidy math',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (recsState.recommendations.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            isHindi
                                ? 'वर्तमान में कोई उपयुक्त सरकारी योजना नहीं मिली।'
                                : 'No currently available scheme satisfies all mandatory conditions.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodyMedium,
                          ),
                        ),
                      )
                    else
                      ...recsState.recommendations.map((rec) => _buildSchemeCard(context, rec, isHindi)),

                    const SizedBox(height: 16),

                    // Proceed to Action Plan Button
                    PrimaryButton(
                      label: isHindi
                          ? 'कार्ययोजना व व्यापार योजना देखें'
                          : 'Proceed to Action Plan',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () {
                        Navigator.pushNamed(context, '/action-plan');
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSchemeCard(
    BuildContext context,
    SchemeRecommendationUIModel rec,
    bool isHindi,
  ) {
    final isEligible = rec.eligibilityStatus == 'eligible';
    final isCondEligible = rec.eligibilityStatus == 'conditionally_eligible';
    final isNeedsInfo = rec.eligibilityStatus == 'needs_information';

    Color statusBgColor = AppColors.successBg;
    Color statusTextColor = AppColors.success;
    String statusLabel = isHindi ? 'पात्र (ELIGIBLE)' : 'ELIGIBLE';

    if (isNeedsInfo) {
      statusBgColor = AppColors.warningBg;
      statusTextColor = AppColors.warning;
      statusLabel = isHindi ? 'जानकारी आवश्यक' : 'NEEDS INFO';
    } else if (isCondEligible) {
      statusBgColor = const Color(0xFFE0F2FE);
      statusTextColor = const Color(0xFF0284C7);
      statusLabel = isHindi ? 'सशर्त पात्र' : 'CONDITIONALLY ELIGIBLE';
    } else if (!isEligible) {
      statusBgColor = const Color(0xFFFEE2E2);
      statusTextColor = const Color(0xFFDC2626);
      statusLabel = isHindi ? 'अपात्र' : 'INELIGIBLE';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14.0),
      child: TactileCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Code Badge & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    rec.schemeCode,
                    style: AppTypography.labelSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      fontSize: 10,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: AppTypography.labelSmall.copyWith(
                      color: statusTextColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Scheme Name
            Text(
              rec.officialName,
              style: AppTypography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 2),

            // Authority
            Text(
              rec.authority,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 12),

            // Financial Benefit Highlights
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  if (rec.estimatedSubsidy > 0) ...[
                    _buildMetricCol(
                      isHindi ? 'अनुमानित सब्सिडी' : 'Est. Subsidy',
                      '₹${rec.estimatedSubsidy.toStringAsFixed(0)}',
                      '${rec.subsidyPercentage.toInt()}% Grant',
                      color: AppColors.success,
                    ),
                    Container(height: 28, width: 1, color: AppColors.border),
                  ],
                  _buildMetricCol(
                    isHindi ? 'पात्र बैंक ऋण' : 'Eligible Loan',
                    '₹${rec.estimatedLoan.toStringAsFixed(0)}',
                    'Bank Credit',
                  ),
                  Container(height: 28, width: 1, color: AppColors.border),
                  _buildMetricCol(
                    isHindi ? 'अनुकूलता स्कोर' : 'Fit Score',
                    '${(rec.suitabilityScore * 100).toInt()}%',
                    'Multi-factor',
                    color: AppColors.secondary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Passed Conditions Checklist
            ...rec.whyEligible.take(3).map((reason) {
              return Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        size: 14, color: AppColors.success),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // View Details Button
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.visibility_rounded, size: 16),
                label: Text(
                  isHindi ? 'विस्तृत विवरण व शर्तें देखें →' : 'View Scheme Details & Audit →',
                  style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  ref.read(selectedSchemeDetailProvider.notifier).state = rec;
                  Navigator.pushNamed(context, '/scheme-detail');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(
    String label,
    String value,
    String subtext, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.labelMedium.copyWith(
            color: color ?? AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtext,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}
