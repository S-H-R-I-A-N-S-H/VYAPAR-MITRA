import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';
import '../providers/financial_provider.dart';

/// Screen 9: Financial Scenario & What-If Modeler
/// Stitch Reference: Screen 31db70f160de4454a00d35f8e7437f4f
class FinancialScenarioScreen extends ConsumerStatefulWidget {
  const FinancialScenarioScreen({super.key});

  @override
  ConsumerState<FinancialScenarioScreen> createState() =>
      _FinancialScenarioScreenState();
}

class _FinancialScenarioScreenState
    extends ConsumerState<FinancialScenarioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final apiClient = ref.read(apiClientProvider);
      final business = ref.read(selectedBusinessProvider);
      final profile = ref.read(businessProfileProvider);

      ref.read(financialProvider.notifier).calculateBaseScenario(
            apiClient: apiClient,
            business: business,
            profile: profile,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final financeState = ref.watch(financialProvider);
    final sim = financeState.simulation;

    final capacityPercentage = financeState.capacityPercentage;
    final currentRevenue = financeState.currentRevenue;
    final currentOperatingCosts = financeState.currentOperatingCosts;
    final emi = sim.monthlyEmi;
    final netCash = financeState.netCashInHand;
    final isHealthy = financeState.isHealthy;
    final rationaleText = financeState.displayRationale;

    final selfPercent = sim.totalProjectCost > 0
        ? ((sim.ownCapital / sim.totalProjectCost) * 100).round()
        : 33;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: isHindi ? 'वित्तीय योजना व लाभ' : 'Financial Planning',
        subtitle: isHindi
            ? 'मासिक नकदी प्रवाह व तनाव परीक्षण'
            : 'Monthly Cash Flow & What-If',
        showAudioButton: true,
        onAudioTap: () {
          final voiceService = ref.read(voiceServiceProvider);
          final readout = isHindi
              ? 'वित्तीय योजना: अनुमानित मासिक नकदी शेष ₹${netCash.toStringAsFixed(0)} है। आप विभिन्न परिदृश्यों का परीक्षण कर सकते हैं।'
              : 'Financial scenario: Projected monthly net cash in hand is ₹${netCash.toStringAsFixed(0)}. You can test what-if scenarios.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Setup Capital & Loan Breakdown
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'स्थापना पूंजी व बैंक ऋण' : 'Setup Capital & Loan',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Total Plan',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'कुल लागत' : 'Total Setup Cost',
                          style: AppTypography.bodyMedium,
                        ),
                        Text(
                          '₹${(sim.totalProjectCost).toStringAsFixed(0)}',
                          style: AppTypography.headlineLarge.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // 2 Split Cards: Self Contribution vs Loan
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi ? 'आपका अंशदान' : 'Your Contribution',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${(sim.ownCapital).toStringAsFixed(0)}',
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Self funds ($selfPercent%)',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.infoBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFC6DAEE)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi ? 'बैंक ऋण / सब्सिडी' : 'Bank Loan / PMEGP',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.info,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '₹${(sim.requiredLoanAmount).toStringAsFixed(0)}',
                                  style: AppTypography.labelLarge.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'Subsidized loan',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.info,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // EMI Row with No Collateral Reassurance
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month_rounded,
                                      size: 18, color: AppColors.secondary),
                                  const SizedBox(width: 8),
                                  Text(
                                    isHindi ? 'मासिक बैंक किस्त (EMI):' : 'Monthly Loan EMI:',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '₹${emi.toStringAsFixed(0)} / mo',
                                style: AppTypography.headlineSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '5-year tenure @ 9% per annum',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Divider(height: 16, color: AppColors.border),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded,
                                  size: 14, color: AppColors.tertiary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isHindi
                                      ? 'मुद्रा / PMEGP के तहत किसी गारंटी या ज़मीन गिरवी की आवश्यकता नहीं।'
                                      : 'No collateral required under Mudra / PMEGP collateral-free scheme.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.tertiary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          InkWell(
                            onTap: () =>
                                Navigator.pushNamed(context, '/loan-planner'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.table_chart_outlined,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isHindi
                                            ? 'पुनर्भुगतान सारणी देखें →'
                                            : 'View Repayment Schedule →',
                                        style:
                                            AppTypography.labelSmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 12,
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Monthly Cash Flow Expected (Base Case)
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'मासिक नकदी प्रवाह (अनुमानित)' : 'Monthly Cash Flow (Expected)',
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCashFlowRow(
                      isHindi ? 'मासिक बिक्री राजस्व' : 'Monthly Sales Revenue',
                      '+₹${currentRevenue.toStringAsFixed(0)}',
                      isPositive: true,
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildCashFlowRow(
                      isHindi ? 'मासिक संचालन लागत (कच्चा माल व बिजली)' : 'Monthly Operating Costs',
                      '-₹${currentOperatingCosts.toStringAsFixed(0)}',
                      isPositive: false,
                    ),
                    const Divider(height: 16, color: AppColors.border),
                    _buildCashFlowRow(
                      isHindi ? 'बैंक ऋण किस्त (EMI)' : 'Bank Loan EMI',
                      '-₹${emi.toStringAsFixed(0)}',
                      isPositive: false,
                    ),
                    const SizedBox(height: 14),

                    // Net Cash In Hand Highlight Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isHealthy ? AppColors.successBg : AppColors.warningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isHealthy ? const Color(0xFFBDE5C4) : const Color(0xFFFDE68A),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isHindi ? 'हाथ में शुद्ध बचत' : 'NET CASH IN HAND',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isHealthy ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                isHealthy
                                    ? 'Surplus Safe'
                                    : (financeState.activeRiskLevel == 'critical'
                                        ? 'Critical Risk'
                                        : 'Tight Margin'),
                                style: AppTypography.labelSmall.copyWith(
                                  color: isHealthy ? AppColors.success : AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${netCash.toStringAsFixed(0)} / month',
                            style: AppTypography.displayLarge.copyWith(
                              fontSize: 26,
                              color: isHealthy ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rationaleText.isNotEmpty
                                ? rationaleText
                                : (isHindi
                                    ? '6 से 8 महीने में पूंजी वापसी (Payback Period)'
                                    : '6 to 8 months capital payback period'),
                            style: AppTypography.bodySmall.copyWith(
                              color: isHealthy ? AppColors.success : AppColors.warning,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // What-If Scenario Modeler
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.tune_rounded, size: 20, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Text(
                          isHindi ? 'यदि बिक्री कम हो तो क्या होगा?' : 'What if sales are lower?',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isHindi
                          ? 'ऋण लेने से पहले मंदी के महीनों का तनाव परीक्षण करें'
                          : 'Stress-test your business before taking a bank loan',
                      style: AppTypography.bodySmall,
                    ),

                    const SizedBox(height: 14),

                    // Quick Scenario Buttons
                    Row(
                      children: [
                        _buildScenarioChip('100% Normal', 100.0, capacityPercentage),
                        const SizedBox(width: 8),
                        _buildScenarioChip('-20% Slow', 80.0, capacityPercentage),
                        const SizedBox(width: 8),
                        _buildScenarioChip('-40% Tough', 60.0, capacityPercentage),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Slider
                    Slider(
                      value: capacityPercentage,
                      min: 60.0,
                      max: 100.0,
                      divisions: 8,
                      label: '${capacityPercentage.toInt()}%',
                      activeColor: isHealthy ? AppColors.primary : AppColors.warning,
                      onChanged: (val) {
                        final apiClient = ref.read(apiClientProvider);
                        ref.read(financialProvider.notifier).updateCapacity(
                              apiClient: apiClient,
                              capacityPercentage: val,
                            );
                      },
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('60% Off-season', style: AppTypography.labelSmall),
                        Text('${capacityPercentage.toInt()}% Capacity',
                            style: AppTypography.labelSmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            )),
                        Text('100% Peak', style: AppTypography.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Final Action Plan CTA
              PrimaryButton(
                label: isHindi
                    ? 'अंतिम कार्ययोजना व सिफारिशें देखें →'
                    : 'View Final Action Plan & Milestones →',
                onPressed: () {
                  Navigator.pushNamed(context, '/action-plan');
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCashFlowRow(String label, String amount, {required bool isPositive}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          amount,
          style: AppTypography.labelLarge.copyWith(
            color: isPositive ? AppColors.success : AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildScenarioChip(String title, double percentage, double activePercentage) {
    final isSelected = (activePercentage - percentage).abs() < 1.0;
    return Expanded(
      child: InkWell(
        onTap: () {
          final apiClient = ref.read(apiClientProvider);
          ref.read(financialProvider.notifier).updateCapacity(
                apiClient: apiClient,
                capacityPercentage: percentage,
              );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceContainerLow : AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              title,
              style: AppTypography.labelSmall.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
