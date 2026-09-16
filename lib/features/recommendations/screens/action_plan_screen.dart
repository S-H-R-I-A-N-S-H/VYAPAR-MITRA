import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class MilestoneItem {
  final String week;
  final String title;
  final String description;
  bool isCompleted;

  MilestoneItem({
    required this.week,
    required this.title,
    required this.description,
    this.isCompleted = false,
  });
}

/// Screen 10: Mobile AI Final Recommendation & Action Plan
/// Stitch Reference: Screens c4b39ef5748e4ad28a3301d6d53e52e4 & 2db0d174907a44afa6ca826c67f3ad8b
class ActionPlanScreen extends ConsumerStatefulWidget {
  const ActionPlanScreen({super.key});

  @override
  ConsumerState<ActionPlanScreen> createState() => _ActionPlanScreenState();
}

class _ActionPlanScreenState extends ConsumerState<ActionPlanScreen> {
  final List<MilestoneItem> _milestones = [
    MilestoneItem(
      week: 'Week 1',
      title: 'Submit PMEGP Subsidy Application',
      description: 'Fill KVIC e-portal form with Vyapar Mitra project report for 35% capital grant.',
      isCompleted: true,
    ),
    MilestoneItem(
      week: 'Week 2',
      title: 'Finalize Equipment Vendor & Kirana Tie-ups',
      description: 'Collect quotations for 100 kg/day cold-press expeller and secure 5 village store commitments.',
    ),
    MilestoneItem(
      week: 'Week 3',
      title: 'Machine Installation & 100 kg Test Batch',
      description: 'Set up single-phase power connection, install filter press, and test sample oil extraction.',
    ),
    MilestoneItem(
      week: 'Week 4',
      title: 'Commercial Launch & Haat Market Sales',
      description: 'Commence daily pressing, distribute bottled oil to village kirana stores, and sell oil cake.',
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
        title: isHindi ? 'अंतिम सिफारिश व कार्ययोजना' : 'Executive Summary',
        subtitle: '${business.title} • 4-Week Plan',
        showAudioButton: true,
        onAudioTap: () {
          final voiceService = ref.read(voiceServiceProvider);
          final readout = isHindi
              ? '${business.title} के लिए 4-सप्ताह की कार्ययोजना तैयार है। पहले सप्ताह में पंजीकरण और स्थान चयन पूरा करें।'
              : '4-week action plan for ${business.title} is ready. Week 1 focuses on registration and site setup.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Final Recommendation Hero Card
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
                                ? 'सत्यापित रणनीति • हरी झंडी (GREEN LIGHT)'
                                : 'Validated Strategy • Green Light',
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
                          ? '100 किलो/दिन मिनी-पायलट के साथ शुरुआत करें'
                          : 'Start with a 100 kg/day Mini-Pilot',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isHindi
                          ? 'स्थानीय मांग, कच्चा माल और 35% PMEGP सब्सिडी आपके पक्ष में हैं। पहले 10 किराना दुकानों को आपूर्ति करके सुरक्षित शुरुआत करें।'
                          : 'Local demand, seed supply, and the 35% PMEGP subsidy align favorably. Start lean with 10 village kirana stores before expanding.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // 3-Col Key Metrics
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildFeasibilityMetric(
                            isHindi ? 'कुल पूंजी' : 'Capital Req',
                            '₹1.80 L',
                            '35% PMEGP',
                          ),
                          Container(height: 32, width: 1, color: AppColors.border),
                          _buildFeasibilityMetric(
                            isHindi ? 'अनुमानित बचत' : 'Est. Net',
                            '₹25,400',
                            'Per Month',
                            color: AppColors.success,
                          ),
                          Container(height: 32, width: 1, color: AppColors.border),
                          _buildFeasibilityMetric(
                            isHindi ? 'जोखिम स्तर' : 'Risk Level',
                            'Low-Mod',
                            'Defensible',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3 Core Guardrails
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shield_rounded,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          isHindi
                              ? 'सुरक्षित संचालन के 3 मुख्य नियम'
                              : '3 Core Guardrails for Safe Operation',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildGuardrail(
                      '1. Cap Setup Cost at ₹1.80 Lakh',
                      'Secure the 35% PMEGP capital subsidy before purchasing machinery. Never exceed initial budget.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuardrail(
                      '2. Pre-sell 50% Volume to Kirana Stores',
                      'Secure village shopkeeper supply commitments before pressing each batch to avoid unsold inventory.',
                    ),
                    const SizedBox(height: 10),
                    _buildGuardrail(
                      '3. Hold 3-Month Working Capital Buffer',
                      'Retain ₹25,000 in liquid reserve for seasonal mustard seed price restocking.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Re-evaluate Strategy Callout
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 18, color: AppColors.warning),
                        const SizedBox(width: 6),
                        Text(
                          isHindi ? 'रणनीति पर पुनर्विचार करें यदि:' : 'Re-evaluate Strategy If:',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '• Raw seed price exceeds ₹65/kg at ${profile.block} Mandi.\n• Competitor drops retail oil price below ₹175/L in village haats.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4-Week Milestone Checklist
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? '4-हफ्तों का एक्शन प्लान' : '4-Week Milestone Checklist',
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          'Interactive',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._milestones.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () {
                                setState(() {
                                  m.isCompleted = !m.isCompleted;
                                });
                              },
                              child: Container(
                                width: 24,
                                height: 24,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: m.isCompleted
                                      ? AppColors.tertiary
                                      : AppColors.surface,
                                  border: Border.all(
                                    color: m.isCompleted
                                        ? AppColors.tertiary
                                        : AppColors.border,
                                    width: 1.5,
                                  ),
                                ),
                                child: m.isCompleted
                                    ? const Icon(Icons.check,
                                        size: 16, color: Colors.white)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceContainerLow,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          m.week,
                                          style: AppTypography.labelSmall.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          m.title,
                                          style: AppTypography.labelMedium.copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            decoration: m.isCompleted
                                                ? TextDecoration.lineThrough
                                                : null,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    m.description,
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
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Share / Export Button
              PrimaryButton(
                label: isHindi
                    ? 'कार्ययोजना साझा करें (WhatsApp / PDF)'
                    : 'Share Action Plan (WhatsApp / PDF)',
                icon: Icons.share_rounded,
                backgroundColor: AppColors.secondary,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isHindi
                          ? 'व्यवसाय योजना सफलतापूर्वक सहेजी गई!'
                          : 'Action plan exported successfully!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Start Over / Explore Another
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/', (route) => false);
                  },
                  child: Text(
                    isHindi ? 'मुख्य पृष्ठ पर लौटें' : 'Back to Home',
                    style: AppTypography.labelMedium.copyWith(color: AppColors.primary),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeasibilityMetric(String label, String value, String subtext,
      {Color? color}) {
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
            fontSize: 14,
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

  Widget _buildGuardrail(String title, String desc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          desc,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
