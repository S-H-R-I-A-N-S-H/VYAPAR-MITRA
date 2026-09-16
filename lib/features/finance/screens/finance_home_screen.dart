import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/tactile_card.dart';

/// Screen: Finance Home (Financial Intelligence Hub)
/// Conforms to SIH 26091 App UI Specification (Section 6.1)
/// Gives the entrepreneur a clear picture of funding needs, available capital, and financing pathways.
class FinanceHomeScreen extends ConsumerWidget {
  const FinanceHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final profile = ref.watch(businessProfileProvider);
    final business = ref.watch(selectedBusinessProvider);

    final ownCapital = profile.personalCapital;
    final totalCost = business.estimatedCapital;
    final loanRequired = (totalCost > ownCapital) ? totalCost - ownCapital : 0.0;
    final subsidyAmount = totalCost * 0.35; // 35% PMEGP rural subsidy

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────────────────
              Text(
                isHindi ? 'वित्त एवं ऋण योजना' : 'Finance & Capital Hub',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isHindi
                    ? 'पूंजी आवश्यकताएं, सरकारी सब्सिडी व सुरक्षित ऋण भुगतान योजना।'
                    : 'Understand project cost, subsidy eligibility, and safe debt capacity.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              // ── Capital Overview Card ────────────────────────────────────────────
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'पूंजी एवं वित्त पोषण अवलोकन' : 'Funding & Capital Overview',
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
                            isHindi ? 'व्यवहार्य' : 'Feasible',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // 3 Metric columns
                    Row(
                      children: [
                        _buildMetricColumn(
                          isHindi ? 'उपलब्ध पूंजी' : 'Own Capital',
                          '₹${(ownCapital / 1000).toStringAsFixed(0)}K',
                          AppColors.primary,
                        ),
                        _buildDivider(),
                        _buildMetricColumn(
                          isHindi ? 'कुल अनुमानित लागत' : 'Total Project Cost',
                          '₹${(totalCost / 100000).toStringAsFixed(2)}L',
                          AppColors.primary,
                        ),
                        _buildDivider(),
                        _buildMetricColumn(
                          isHindi ? 'ऋण आवश्यकता' : 'Financing Gap',
                          '₹${(loanRequired / 100000).toStringAsFixed(2)}L',
                          AppColors.secondary,
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Subsidy Highlight Box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.successBg.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.savings_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHindi
                                      ? '35% पीएमईजीपी (PMEGP) पूंजी सब्सिडी उपलब्ध'
                                      : '35% PMEGP Capital Subsidy Available',
                                  style: AppTypography.labelMedium.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                                Text(
                                  isHindi
                                      ? 'अनुमानित ₹${(subsidyAmount / 1000).toStringAsFixed(0)}K की सीधी सरकारी छूट जिससे कर्ज का बोझ कम होता है।'
                                      : 'Estimated ₹${(subsidyAmount / 1000).toStringAsFixed(0)}K grant reducing your effective loan burden.',
                                  style: AppTypography.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Core Safety Principle Banner ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.infoBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFC6DAEE)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.info, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'सुरक्षा नियम • Financial Safety Principle' : 'Financial Safety Principle',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHindi
                                ? '"ऋण की पात्रता होना" और "ऋण को सुरक्षित रूप से चुका पाना" दो अलग बातें हैं। हम आपकी व्यापारिक बचत से ही सुरक्षित कर्ज तय करते हैं।'
                                : '"Eligible for a loan" does not mean "able to safely afford the loan." We test stress repayment against conservative cash flows.',
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ── Financial Tools & Simulators ─────────────────────────────────────
              Text(
                isHindi ? 'वित्तीय साधन एवं सिमुलेटर' : 'Financial Tools & Simulators',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              // Tool 1: Interactive Financial Scenario Modeler
              _buildFinanceToolCard(
                context: context,
                icon: Icons.tune_rounded,
                title: isHindi ? 'वित्तीय परिदृश्य व लाभ सिमुलेटर' : 'Financial Scenario Modeler',
                subtitle: isHindi
                    ? 'बिक्री मूल्य, कच्चा माल लागत व क्षमता बदलकर शुद्ध मासिक बचत देखें'
                    : 'Adjust volume, raw seed rates, and electricity to simulate cash flow',
                badge: isHindi ? 'व्हाट-इफ सिमुलेटर' : 'What-If Engine',
                route: '/finance-modeler',
                color: AppColors.primary,
              ),

              // Tool 2: Loan & Repayment Planner
              _buildFinanceToolCard(
                context: context,
                icon: Icons.calculate_rounded,
                title: isHindi ? 'ऋण किस्त (EMI) एवं तनाव परीक्षण' : 'Loan Repayment & Stress Test',
                subtitle: isHindi
                    ? 'ब्याज दर, अवधि व मंदे महीनों में किस्त चुकाने की क्षमता जांचें'
                    : 'Test whether your expected cash flow safely covers monthly bank EMIs',
                badge: isHindi ? 'ईएमआई विश्लेषक' : 'EMI Calculator',
                route: '/loan-planner',
                color: AppColors.secondary,
              ),

              const SizedBox(height: 14),

              // ── Government Financing Schemes ─────────────────────────────────────
              Text(
                isHindi ? 'पात्र सरकारी योजनाएं' : 'Eligible Government Schemes',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 10),

              _buildSchemeCard(
                title: 'PMEGP (पीएमईजीपी योजना)',
                subsidyText: isHindi ? '35% ग्रामीण पूंजी सब्सिडी' : '35% Rural Capital Subsidy',
                eligibility: isHindi ? 'पात्र • निर्माण कार्य हेतु ₹50 लाख तक' : 'Eligible • Manufacturing up to ₹50L',
                documents: isHindi ? 'आधार, पैन, जाति प्रमाण पत्र, निवास' : 'Aadhaar, PAN, Category, Address',
                source: 'KVIC / MSME Portal',
              ),

              const SizedBox(height: 8),

              _buildSchemeCard(
                title: 'PM Mudra Yojana (मुद्रा योजना - किशोर)',
                subsidyText: isHindi ? '₹50,000 से ₹5,00,000 संपार्श्विक मुक्त ऋण' : '₹50K - ₹5L Collateral-Free Loan',
                eligibility: isHindi ? 'पात्र • सूक्ष्म उद्यम मशीनरी खरीद' : 'Eligible • Micro-enterprise setup',
                documents: isHindi ? 'उद्यम आधार, बैंक खाता विवरण 6 माह' : 'Udyam Aadhaar, 6-month bank statement',
                source: 'Department of Financial Services',
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildFinanceToolCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String badge,
    required String route,
    required Color color,
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
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
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
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge,
                          style: AppTypography.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
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

  Widget _buildSchemeCard({
    required String title,
    required String subsidyText,
    required String eligibility,
    required String documents,
    required String source,
  }) {
    return TactileCard(
      padding: const EdgeInsets.all(12),
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
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Eligible',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subsidyText,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.tertiary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  eligibility,
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.description_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  documents,
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
