import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';
import '../models/financial_models.dart';
import '../providers/financial_provider.dart';

/// Screen: Loan & Repayment Planner
/// Visualizes projected loan amortization, payment composition, and tenure trade-offs.
class LoanRepaymentScreen extends ConsumerStatefulWidget {
  const LoanRepaymentScreen({super.key});

  @override
  ConsumerState<LoanRepaymentScreen> createState() =>
      _LoanRepaymentScreenState();
}

class _LoanRepaymentScreenState extends ConsumerState<LoanRepaymentScreen> {
  int _selectedYear = 1;
  int _comparisonTenure = 36; // 36 vs 60 months

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final financeState = ref.watch(financialProvider);
    final sim = financeState.simulation;

    // Safety: If no valid simulation exists, render an informative empty state
    if (sim.totalProjectCost <= 0) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: VyaparTopAppBar(
          title: isHindi ? 'ऋण पुनर्भुगतान योजना' : 'Loan & Repayment Planner',
          showAudioButton: true,
          onAudioTap: () {
            final voiceService = ref.read(voiceServiceProvider);
            final readout = isHindi
                ? 'कृपया पहले व्यवसाय व पूंजी मॉडल का चयन करें ताकि ऋण किस्त की गणना की जा सके।'
                : 'Please select a business profile first to calculate loan repayment schedule.';
            voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
          },
        ),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isHindi
                        ? 'कोई सक्रिय वित्तीय योजना नहीं मिली'
                        : 'No Active Financial Plan Found',
                    style: AppTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isHindi
                        ? 'ऋण व पुनर्भुगतान देखने के लिए कृपया पहले वित्तीय योजना तैयार करें।'
                        : 'Please configure your business setup cost and financing before viewing the loan planner.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: isHindi
                        ? 'वित्तीय योजना पर लौटें'
                        : 'Back to Financial Planning',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final loanAmount = sim.requiredLoanAmount;
    final emi = sim.monthlyEmi;
    final totalInterest = sim.totalInterestPayable;
    final totalRepayment = sim.totalRepaymentAmount;
    const annualRate = 9.0;
    const baseTenureMonths = 60;

    // Payment Composition: Principal vs Interest
    final double principalPct;
    final double interestPct;
    if (totalRepayment > 0) {
      principalPct = (loanAmount / totalRepayment) * 100.0;
      interestPct = (totalInterest / totalRepayment) * 100.0;
    } else {
      principalPct = 100.0;
      interestPct = 0.0;
    }

    // Full Amortization Schedule using deterministic reducing-balance math
    final fullSchedule = DeterministicFinancialCalculator.generateAmortizationSchedule(
      principal: loanAmount,
      annualRatePct: annualRate,
      tenureMonths: baseTenureMonths,
      emiOverride: emi,
    );

    // First month payment breakdown
    final firstPayment = fullSchedule.isNotEmpty ? fullSchedule.first : null;

    // Filter schedule by selected year (12 months per year)
    final totalYears = (baseTenureMonths / 12).ceil();
    final startMonth = (_selectedYear - 1) * 12 + 1;
    final endMonth = (_selectedYear * 12).clamp(1, baseTenureMonths);
    final displayedMonths = fullSchedule
        .where((item) => item.month >= startMonth && item.month <= endMonth)
        .toList();

    // Lightweight Tenure Comparison calculations (pure local math, no state mutation)
    final compEmi36 = DeterministicFinancialCalculator.calculateEmi(
      principal: loanAmount,
      annualRatePct: annualRate,
      tenureMonths: 36,
    );
    final compRepay36 = double.parse((compEmi36 * 36).toStringAsFixed(2));
    final compInterest36 = double.parse((compRepay36 - loanAmount).toStringAsFixed(2));

    final compEmi60 = DeterministicFinancialCalculator.calculateEmi(
      principal: loanAmount,
      annualRatePct: annualRate,
      tenureMonths: 60,
    );
    final compRepay60 = double.parse((compEmi60 * 60).toStringAsFixed(2));
    final compInterest60 = double.parse((compRepay60 - loanAmount).toStringAsFixed(2));

    final interestSavedBy36 = compInterest60 - compInterest36;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: isHindi ? 'ऋण व पुनर्भुगतान योजना' : 'Loan & Repayment Planner',
        subtitle: isHindi
            ? 'मासिक किस्त व मूलधन-ब्याज विभाजन'
            : 'EMI & Principal Amortization',
        showAudioButton: true,
        onAudioTap: () {
          final voiceService = ref.read(voiceServiceProvider);
          final readout = isHindi
              ? 'ऋण पुनर्भुगतान योजना: अनुमानित मासिक किस्त ₹${emi.toStringAsFixed(0)} है।'
              : 'Loan repayment plan: Estimated monthly EMI is ₹${emi.toStringAsFixed(0)}.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. LOAN SUMMARY CARD
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'ऋण विवरण व शर्तें' : 'Loan Summary & Terms',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.infoBg,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFC6DAEE)),
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
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHindi ? 'अनुमानित बैंक ऋण' : 'Projected Loan Amount',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              '₹${loanAmount.toStringAsFixed(0)}',
                              style: AppTypography.headlineLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              isHindi ? 'मासिक किस्त (EMI)' : 'Monthly EMI',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
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
                      ],
                    ),
                    const Divider(height: 20, color: AppColors.border),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSummaryMetric(
                          isHindi ? 'ब्याज दर' : 'Interest Rate',
                          '${annualRate.toStringAsFixed(1)}% p.a.',
                        ),
                        _buildSummaryMetric(
                          isHindi ? 'अवधि' : 'Tenure',
                          '$baseTenureMonths mo (5 yr)',
                        ),
                        _buildSummaryMetric(
                          isHindi ? 'कुल ब्याज' : 'Total Interest',
                          '₹${totalInterest.toStringAsFixed(0)}',
                        ),
                        _buildSummaryMetric(
                          isHindi ? 'कुल भुगतान' : 'Total Repayment',
                          '₹${totalRepayment.toStringAsFixed(0)}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. PAYMENT COMPOSITION (Principal vs Interest)
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'भुगतान संरचना (मूलधन बनाम ब्याज)' : 'Payment Composition',
                      style: AppTypography.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Visual Progress Split Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 18,
                        child: Row(
                          children: [
                            Expanded(
                              flex: (principalPct * 10).round().clamp(1, 1000),
                              child: Container(
                                color: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              flex: (interestPct * 10).round().clamp(1, 1000),
                              child: Container(
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isHindi ? 'मूलधन' : 'Principal'}: ₹${loanAmount.toStringAsFixed(0)} (${principalPct.toStringAsFixed(1)}%)',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: AppColors.secondary,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${isHindi ? 'ब्याज' : 'Interest'}: ₹${totalInterest.toStringAsFixed(0)} (${interestPct.toStringAsFixed(1)}%)',
                              style: AppTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. FIRST PAYMENT BREAKDOWN
              if (firstPayment != null)
                TactileCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isHindi ? 'पहले महीने की किस्त का विवरण' : 'First Payment Breakdown (Month 1)',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Month 1',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildBreakdownBox(
                              isHindi ? 'प्रारंभिक शेष' : 'Opening Balance',
                              '₹${firstPayment.openingBalance.toStringAsFixed(0)}',
                              AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBreakdownBox(
                              isHindi ? 'मूलधन भुगतान' : 'Principal Paid',
                              '₹${firstPayment.principal.toStringAsFixed(0)}',
                              AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBreakdownBox(
                              isHindi ? 'ब्याज हिस्सा' : 'Interest Paid',
                              '₹${firstPayment.interest.toStringAsFixed(0)}',
                              AppColors.secondary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildBreakdownBox(
                              isHindi ? 'अंतिम शेष' : 'Closing Balance',
                              '₹${firstPayment.closingBalance.toStringAsFixed(0)}',
                              AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 16),

              // 4. REPAYMENT SCHEDULE
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'मासिक पुनर्भुगतान सारणी' : 'Repayment Schedule',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          isHindi ? '$totalYears वर्ष का कार्यक्रम' : '$totalYears-Year Timeline',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Year Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: List.generate(totalYears, (index) {
                          final yr = index + 1;
                          final isSelected = _selectedYear == yr;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(isHindi ? 'वर्ष $yr' : 'Year $yr'),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                              backgroundColor: AppColors.surfaceContainerLow,
                              onSelected: (val) {
                                if (val) setState(() => _selectedYear = yr);
                              },
                            ),
                          );
                        }),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Header Row
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text(
                              isHindi ? 'माह' : 'Month',
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              isHindi ? 'प्रारंभिक' : 'Opening',
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              isHindi ? 'मूलधन' : 'Principal',
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              isHindi ? 'ब्याज' : 'Interest',
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              isHindi ? 'अंतिम शेष' : 'Closing',
                              style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Monthly Schedule Rows
                    ...displayedMonths.map((item) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 50,
                              child: Text(
                                'M${item.month}',
                                style: AppTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '₹${item.openingBalance.toStringAsFixed(0)}',
                                style: AppTypography.bodySmall,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '₹${item.principal.toStringAsFixed(0)}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                '₹${item.interest.toStringAsFixed(0)}',
                                style: AppTypography.bodySmall.copyWith(color: AppColors.secondary),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text(
                                '₹${item.closingBalance.toStringAsFixed(0)}',
                                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w600),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 5. TENURE COMPARISON WIDGET (36 vs 60 Months)
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'अवधि तुलना (तनाव व बचत)' : 'Tenure Trade-Off Comparison',
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const Icon(Icons.compare_arrows_rounded,
                            color: AppColors.secondary, size: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isHindi
                          ? 'देखें कि अवधि बदलने से मासिक किस्त और कुल ब्याज पर क्या असर पड़ता है:'
                          : 'Compare how tenure affects your monthly cash commitment vs overall interest:',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    // Side-by-side comparison tiles
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _comparisonTenure = 36),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _comparisonTenure == 36
                                    ? AppColors.surfaceContainerLow
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _comparisonTenure == 36
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: _comparisonTenure == 36 ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '3 Years (36 mo)',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (_comparisonTenure == 36)
                                        const Icon(Icons.check_circle_rounded,
                                            size: 16, color: AppColors.primary),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${compEmi36.toStringAsFixed(0)} / mo',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total Interest: ₹${compInterest36.toStringAsFixed(0)}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _comparisonTenure = 60),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _comparisonTenure == 60
                                    ? AppColors.surfaceContainerLow
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _comparisonTenure == 60
                                      ? AppColors.primary
                                      : AppColors.border,
                                  width: _comparisonTenure == 60 ? 2.0 : 1.0,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '5 Years (60 mo)',
                                        style: AppTypography.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      if (_comparisonTenure == 60)
                                        const Icon(Icons.check_circle_rounded,
                                            size: 16, color: AppColors.primary),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '₹${compEmi60.toStringAsFixed(0)} / mo',
                                    style: AppTypography.labelLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Total Interest: ₹${compInterest60.toStringAsFixed(0)}',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Insight note
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.successBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC8E6C9)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_rounded,
                              size: 18, color: AppColors.success),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isHindi
                                  ? '3 वर्ष की अवधि चुनने से कुल ब्याज में ₹${interestSavedBy36.toStringAsFixed(0)} की बचत होगी, पर मासिक किस्त ₹${(compEmi36 - compEmi60).toStringAsFixed(0)} अधिक होगी।'
                                  : 'Choosing 3 years saves ₹${interestSavedBy36.toStringAsFixed(0)} in total interest, but requires an extra ₹${(compEmi36 - compEmi60).toStringAsFixed(0)} per month.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 6. BOTTOM CTAs
              PrimaryButton(
                label: isHindi
                    ? 'अंतिम कार्ययोजना व सिफारिशें देखें →'
                    : 'View Final Action Plan & Milestones →',
                onPressed: () {
                  Navigator.pushNamed(context, '/action-plan');
                },
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: Text(
                    isHindi ? 'वित्तीय योजना पर वापस' : 'Back to Financial Planning',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildBreakdownBox(String title, String value, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 9,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
