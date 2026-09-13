import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

/// Screen 7: Mobile Research Step Progress & Live Status
/// Stitch Reference: Screen 9a0e6635716e4feabd4131bae2368be8
class ResearchProgressScreen extends ConsumerStatefulWidget {
  const ResearchProgressScreen({super.key});

  @override
  ConsumerState<ResearchProgressScreen> createState() =>
      _ResearchProgressScreenState();
}

class _ResearchProgressScreenState extends ConsumerState<ResearchProgressScreen> {
  double _progress = 0.5;
  int _completedSteps = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Simulate active research scan completing
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _progress = 1.0;
          _completedSteps = 6;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final business = ref.watch(selectedBusinessProvider);
    final profile = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'VYAPAR MITRA',
        subtitle: isHindi ? 'सक्रिय बाजार अनुसंधान' : 'Live Market Research',
        showAudioButton: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Radar Scanner Hero Card
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
                            color: const Color(0xFFFFF5EC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFCD7C0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isHindi
                                    ? '${profile.block} मंडी सक्रिय जांच'
                                    : 'Analyzing ${profile.block} Market',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(_progress * 100).toInt()}%',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      _progress >= 1.0
                          ? (isHindi
                              ? 'बाजार विश्लेषण पूर्ण हुआ!'
                              : 'Market Analysis Completed!')
                          : (isHindi
                              ? 'मंडी भाव व प्रतियोगी कीमतों की जांच जारी है...'
                              : 'Checking nearby competitor pricing & mandi rates...'),
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      isHindi
                          ? 'हमारा एआई आपके ${business.title} के लिए वास्तविक स्थानीय आंकड़े एकत्र कर रहा है।'
                          : 'Our AI is gathering hyper-local trade signals for your ${business.title}.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceContainerLow,
                        color: AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _progress >= 1.0
                              ? '14 local data points verified'
                              : '~30 seconds remaining',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '$_completedSteps of 6 steps',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Live Finding Flash Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        size: 20, color: AppColors.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'ताज़ा मंडी खोज' : 'LIVE MARKET FINDING',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHindi
                                ? '${profile.block} मंडी में आज कच्ची सरसों ₹54/किलो पर मिल रही है (राज्य औसत से 4% सस्ती)।'
                                : 'Raw mustard seed is trading at ₹54/kg at ${profile.block} Mandi today (4% lower than state average).',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textPrimary,
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

              // Pipeline Timeline
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'अनुसंधान चरण' : 'Research Pipeline',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPipelineStep(
                      isDone: true,
                      title: isHindi ? 'व्यवसाय का पैमाना' : 'Business Scale Confirmed',
                      subtitle: '100 kg/day processing mini-mill',
                    ),
                    _buildPipelineStep(
                      isDone: true,
                      title: isHindi ? 'स्थानीय प्रतियोगी' : 'Local Competitors Mapped',
                      subtitle: '2 expeller mills operating within 7 km',
                    ),
                    _buildPipelineStep(
                      isDone: _completedSteps >= 3,
                      title: isHindi ? 'मंडी जिंस भाव' : 'Mandi Commodity Rates',
                      subtitle: 'Agmarknet recorded rate: ₹54/kg',
                    ),
                    _buildPipelineStep(
                      isDone: _completedSteps >= 4,
                      title: isHindi ? 'ग्राहक मांग अनुमान' : 'Consumer Demand Index',
                      subtitle: '82% village households prefer fresh oil',
                    ),
                    _buildPipelineStep(
                      isDone: _completedSteps >= 5,
                      title: isHindi ? 'कीमत मतभेद व अनिश्चितता' : 'Pricing Discrepancy Check',
                      subtitle: 'No critical price contradictions found',
                    ),
                    _buildPipelineStep(
                      isDone: _completedSteps >= 6,
                      title: isHindi ? 'सब्सिडी व योजना पात्रता' : 'Government Subsidy Aligned',
                      subtitle: '35% PMEGP rural subsidy confirmed',
                      isLast: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // View Dashboard Button
              PrimaryButton(
                label: isHindi
                    ? 'सत्यापन डैशबोर्ड देखें'
                    : 'View Validation Dashboard →',
                onPressed: () {
                  Navigator.pushNamed(context, '/validation-dashboard');
                },
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPipelineStep({
    required bool isDone,
    required String title,
    required String subtitle,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone ? AppColors.successBg : AppColors.surfaceVariant,
                border: Border.all(
                  color: isDone ? AppColors.success : AppColors.border,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: AppColors.success)
                  : const SizedBox(),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 28,
                color: isDone ? AppColors.success : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }
}
