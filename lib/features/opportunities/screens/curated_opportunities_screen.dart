import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class OpportunityItem {
  final String title;
  final String domain;
  final int fitPercentage;
  final String capital;
  final double rawCapital;
  final double monthlyRevenue;
  final double monthlyCosts;
  final double monthlyEmi;
  final double netCash;
  final String demand;
  final String competition;
  final String whyFits;
  final String majorRisk;
  final String subsidyScheme;

  const OpportunityItem({
    required this.title,
    required this.domain,
    required this.fitPercentage,
    required this.capital,
    required this.rawCapital,
    required this.monthlyRevenue,
    required this.monthlyCosts,
    required this.monthlyEmi,
    required this.netCash,
    required this.demand,
    required this.competition,
    required this.whyFits,
    required this.majorRisk,
    required this.subsidyScheme,
  });
}

/// Screen 5: Curated Business Opportunities
/// Stitch Reference: Screen 74d92a0ffcbe4c13a1146ee0379871c8
class CuratedOpportunitiesScreen extends ConsumerStatefulWidget {
  const CuratedOpportunitiesScreen({super.key});

  @override
  ConsumerState<CuratedOpportunitiesScreen> createState() =>
      _CuratedOpportunitiesScreenState();
}

class _CuratedOpportunitiesScreenState
    extends ConsumerState<CuratedOpportunitiesScreen> {
  int _selectedIndex = 0;

  final List<OpportunityItem> _opportunities = const [
    OpportunityItem(
      title: 'Cold-Press Mustard Oil Mill',
      domain: 'Agri-Processing & Food Products',
      fitPercentage: 92,
      capital: '₹1.80 Lakh',
      rawCapital: 180000.0,
      monthlyRevenue: 62000.0,
      monthlyCosts: 33500.0,
      monthlyEmi: 3100.0,
      netCash: 25400.0,
      demand: 'High',
      competition: 'Moderate',
      whyFits: 'Matches your machinery skills and utilizes local Mandi surplus seed.',
      majorRisk: 'Seed price fluctuations during off-season monsoon months.',
      subsidyScheme: 'Eligible for 35% PMEGP grant + Mudra loan',
    ),
    OpportunityItem(
      title: 'Organic Compost & Fertilizer Unit',
      domain: 'Agri-Inputs & Bio-Nutrients',
      fitPercentage: 84,
      capital: '₹85,000',
      rawCapital: 85000.0,
      monthlyRevenue: 38000.0,
      monthlyCosts: 18000.0,
      monthlyEmi: 1500.0,
      netCash: 18500.0,
      demand: 'Growing',
      competition: 'Low',
      whyFits: 'Zero raw material expense using cow dung & crop residues.',
      majorRisk: 'Requires 45 days maturation cycle before first batch sale.',
      subsidyScheme: 'Eligible for Mudra Shishu ₹50k collateral-free loan',
    ),
    OpportunityItem(
      title: 'Cattle Feed & Grain Depot',
      domain: 'Livestock & Rural Retail',
      fitPercentage: 78,
      capital: '₹1.20 Lakh',
      rawCapital: 120000.0,
      monthlyRevenue: 52000.0,
      monthlyCosts: 36000.0,
      monthlyEmi: 2200.0,
      netCash: 13800.0,
      demand: 'Constant',
      competition: 'Moderate',
      whyFits: 'Daily cash sales to village dairy farmers.',
      majorRisk: 'Credit demand from local farmers requires working capital.',
      subsidyScheme: 'Eligible for Mudra Kishore + PMEGP',
    ),
  ];

  void _confirmSelection() {
    final chosen = _opportunities[_selectedIndex];

    ref.read(selectedBusinessProvider.notifier).selectBusiness(
          SelectedBusinessState(
            title: chosen.title,
            domain: chosen.domain,
            estimatedCapital: chosen.rawCapital,
            monthlyRevenue: chosen.monthlyRevenue,
            monthlyOperatingCosts: chosen.monthlyCosts,
            monthlyEmi: chosen.monthlyEmi,
            netCashMonthly: chosen.netCash,
            status: 'IDEA',
            schemeEligible: chosen.subsidyScheme,
          ),
        );

    Navigator.pushNamed(context, '/business-confirmation');
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final profile = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'VYAPAR MITRA',
        stepText: '3 Found',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recommendation Header
                    Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            size: 16, color: AppColors.secondary),
                        const SizedBox(width: 6),
                        Text(
                          isHindi
                              ? 'आपके लिए विशेष रूप से अनुशंसित'
                              : 'RECOMMENDED FOR YOU',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHindi ? 'व्यवसाय के श्रेष्ठ अवसर' : 'Curated Business Opportunities',
                      style: AppTypography.headlineLarge.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi
                          ? 'आपके अनुभव, ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K निजी बजट और ${profile.block} मंडी के आधार पर।'
                          : 'Based on your experience, ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K capital, and ${profile.block} market signals.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Opportunities List
                    ..._opportunities.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      final isSelected = _selectedIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14.0),
                        child: TactileCard(
                          onTap: () => setState(() => _selectedIndex = index),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Row: Title + Fit Badge + Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: AppTypography.headlineSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.successBg,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${item.fitPercentage}% Match • ${index == 0 ? "Top Recommendation" : "Viable Option"}',
                                            style: AppTypography.labelSmall.copyWith(
                                              color: AppColors.success,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.surfaceVariant,
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 18, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // 3 Metrics Bar (Capital, Demand, Competition)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceContainerLow,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildMetric('Capital', item.capital),
                                    Container(
                                        height: 28,
                                        width: 1,
                                        color: AppColors.border),
                                    _buildMetric('Demand', item.demand,
                                        color: AppColors.success),
                                    Container(
                                        height: 28,
                                        width: 1,
                                        color: AppColors.border),
                                    _buildMetric('Competition', item.competition),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Why it fits
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.lightbulb_rounded,
                                      size: 16, color: AppColors.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item.whyFits,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // Major Risk Warning Card
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warningBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        size: 16, color: AppColors.warning),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Risk: ${item.majorRisk}',
                                        style: AppTypography.labelSmall.copyWith(
                                          color: AppColors.warning,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              // Subsidy Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.infoBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFFC6DAEE)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.account_balance_rounded,
                                        size: 14, color: AppColors.info),
                                    const SizedBox(width: 6),
                                    Text(
                                      item.subsidyScheme,
                                      style: AppTypography.labelSmall.copyWith(
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
                      );
                    }),
                  ],
                ),
              ),
            ),

            // Confirm Selection Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              color: AppColors.surface,
              child: PrimaryButton(
                label: isHindi
                    ? 'यह अवसर चुनें और पुष्टि करें'
                    : 'Confirm Selected Business →',
                onPressed: _confirmSelection,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? color}) {
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
          style: AppTypography.labelLarge.copyWith(
            color: color ?? AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
