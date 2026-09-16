import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';
import '../providers/research_pipeline_provider.dart';

/// Screen 7: Mobile Research Step Progress & Live Status
/// Dynamic AI & Web Grounded secondary research pipeline
class ResearchProgressScreen extends ConsumerStatefulWidget {
  const ResearchProgressScreen({super.key});

  @override
  ConsumerState<ResearchProgressScreen> createState() =>
      _ResearchProgressScreenState();
}

class _ResearchProgressScreenState extends ConsumerState<ResearchProgressScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(researchPipelineProvider.notifier).startResearch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final business = ref.watch(selectedBusinessProvider);
    final profile = ref.watch(businessProfileProvider);
    final pipelineState = ref.watch(researchPipelineProvider);

    final progress = pipelineState.progress.clamp(0.0, 1.0);
    final isDone = progress >= 1.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'VYAPAR MITRA',
        subtitle: isHindi ? 'सक्रिय बाजार अनुसंधान' : 'Live Market Research',
        showAudioButton: true,
        onAudioTap: () {
          final voiceService = ref.read(voiceServiceProvider);
          final readout = isHindi
              ? 'बाजार अनुसंधान प्रगति पर है। हम स्थानीय मंडी दरों, मांग और प्रतिस्पर्धा का विश्लेषण कर रहे हैं।'
              : 'Market research is in progress. Analyzing local mandi prices, demand, and competition.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
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
                            color: isDone
                                ? AppColors.successBg
                                : const Color(0xFFFFF5EC),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDone
                                  ? const Color(0xFFC8E6C9)
                                  : const Color(0xFFFCD7C0),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? AppColors.success
                                      : AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isHindi
                                    ? '${profile.block} मंडी सक्रिय जांच'
                                    : 'Analyzing ${profile.block} Market',
                                style: AppTypography.labelSmall.copyWith(
                                  color: isDone
                                      ? AppColors.success
                                      : AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Text(
                      isDone
                          ? (isHindi
                              ? 'बाजार विश्लेषण पूर्ण हुआ!'
                              : 'Market Analysis Completed!')
                          : (isHindi
                              ? '${business.title} हेतु मंडी व प्रतियोगी जांच जारी...'
                              : 'Evaluating trade dynamics for ${business.title}...'),
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
                        value: progress,
                        minHeight: 8,
                        backgroundColor: AppColors.surfaceContainerLow,
                        color: isDone ? AppColors.success : AppColors.secondary,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isDone
                              ? '${pipelineState.synthesisResult?.dataPointsCollected ?? 14} local data points verified'
                              : '~15 seconds remaining',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${pipelineState.completedSteps} of ${pipelineState.steps.length} steps',
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

              // Live Finding Flash Card (Tailored to active business)
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
                            isHindi ? 'ताज़ा जमीनी खोज' : 'LIVE MARKET FINDING',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.warning,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isHindi
                                ? (pipelineState.liveFindingHi.isNotEmpty
                                    ? pipelineState.liveFindingHi
                                    : '${profile.block} में ${business.title} के लिए बाजार संकेत सकारात्मक हैं।')
                                : (pipelineState.liveFindingEn.isNotEmpty
                                    ? pipelineState.liveFindingEn
                                    : 'Market conditions in ${profile.block} indicate viable unit economics for ${business.title}.'),
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

              // Web Grounding Citations Banner
              if (pipelineState.synthesisResult?.groundingSources.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.travel_explore_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isHindi
                              ? 'गूगल सर्च ग्राउंडिंग व मंडी बुलेटिन द्वारा सत्यापित'
                              : 'Grounded in live search & APMC Mandi data',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.successBg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Verified',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.success,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Dynamic Pipeline Timeline
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isHindi ? 'अनुसंधान चरण' : 'Research Pipeline',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (!isDone)
                          Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isHindi ? 'खोज जारी...' : 'Scanning...',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(pipelineState.steps.length, (idx) {
                      final step = pipelineState.steps[idx];
                      final isLast = idx == pipelineState.steps.length - 1;
                      return _buildPipelineStep(
                        isDone: step.isDone,
                        inProgress: step.inProgress,
                        title: isHindi ? step.titleHi : step.titleEn,
                        subtitle: isHindi ? step.subtitleHi : step.subtitleEn,
                        actionLabel: isHindi ? step.actionLabelHi : step.actionLabelEn,
                        onTap: step.actionRoute != null
                            ? () => Navigator.pushNamed(context, step.actionRoute!)
                            : null,
                        isLast: isLast,
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Refresh or View Dashboard Buttons
              Row(
                children: [
                  if (isDone) ...[
                    IconButton.filledTonal(
                      icon: const Icon(Icons.refresh_rounded),
                      tooltip: isHindi ? 'पुनः जांचें' : 'Rescan',
                      onPressed: () {
                        ref
                            .read(researchPipelineProvider.notifier)
                            .startResearch(forceRefresh: true);
                      },
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label: isHindi
                          ? 'सत्यापन डैशबोर्ड देखें'
                          : 'View Validation Dashboard →',
                      onPressed: () {
                        Navigator.pushNamed(context, '/validation-dashboard');
                      },
                    ),
                  ),
                ],
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
    bool inProgress = false,
    required String title,
    required String subtitle,
    bool isLast = false,
    VoidCallback? onTap,
    String? actionLabel,
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
                color: isDone
                    ? AppColors.successBg
                    : inProgress
                        ? const Color(0xFFFFF5EC)
                        : AppColors.surfaceVariant,
                border: Border.all(
                  color: isDone
                      ? AppColors.success
                      : inProgress
                          ? AppColors.secondary
                          : AppColors.border,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check, size: 14, color: AppColors.success)
                  : inProgress
                      ? const Center(
                          child: SizedBox(
                            width: 10,
                            height: 10,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          ),
                        )
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (onTap != null && actionLabel != null)
                    GestureDetector(
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.secondary.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          actionLabel,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
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
