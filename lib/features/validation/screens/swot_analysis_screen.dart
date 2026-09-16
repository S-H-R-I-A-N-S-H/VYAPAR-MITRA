import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/voice_mic_button.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class SwotItem {
  final String title;
  final String detail;
  final String badge;

  const SwotItem({
    required this.title,
    required this.detail,
    required this.badge,
  });
}

/// Screen 9: Hyperlocal SWOT & Feasibility Matrix
/// Stitch Reference: Screen 7580cc32aa4c475f87930bb95e6bf79c
class SwotAnalysisScreen extends ConsumerStatefulWidget {
  const SwotAnalysisScreen({super.key});

  @override
  ConsumerState<SwotAnalysisScreen> createState() => _SwotAnalysisScreenState();
}

class _SwotAnalysisScreenState extends ConsumerState<SwotAnalysisScreen> {
  int _selectedQuadrant = 0; // 0: All, 1: S, 2: W, 3: O, 4: T

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final business = ref.watch(selectedBusinessProvider);
    final profile = ref.watch(businessProfileProvider);
    final voiceService = ref.read(voiceServiceProvider);

    final swotData = _generateDynamicSwot(
      businessTitle: business.title,
      domain: business.domain,
      district: profile.district,
      block: profile.block,
      capital: profile.personalCapital,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: isHindi ? 'व्यापार सामर्थ्य विश्लेषण' : 'SWOT Analysis',
        subtitle: '${business.title} • ${profile.block}',
        showAudioButton: true,
        onAudioTap: () {
          final readout = isHindi
              ? '${business.title} के लिए समग्र सामर्थ्य अनुकूल है। स्थानीय मांग मजबूत है और सरकारी योजना सहायता उपलब्ध है।'
              : 'Overall risk-reward for ${business.title} in ${profile.block} is favorable. Strong local demand backed by government scheme support.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            top: 12.0,
            bottom: 24.0,
          ),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overall Risk-Reward Hero Banner
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
                                        ? 'जोखिम-प्रतिफल: अनुकूल'
                                        : 'Risk-Reward: Favorable',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isHindi ? 'व्यवहार्यता 84%' : 'Feasibility 84%',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isHindi
                              ? 'प्रचुर स्थानीय मांग और उच्च लाभ मार्जिन, मौसमी कार्यशील पूंजी प्रबंधन आवश्यक।'
                              : 'High local catchment demand and viable operating margin, requires planned working capital reserves.',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isHindi
                              ? '${profile.block} क्षेत्र में ${business.title} को स्थापित करने हेतु सामर्थ्य व जोखिमों का विवरण:'
                              : 'Detailed breakdown of enterprise strengths, constraints, opportunities, and competitive risks for ${profile.block}:',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips (All, Strengths, Weaknesses, Opportunities, Threats)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterPill('All / सब', 0),
                        _buildFilterPill('Strengths (ताकत)', 1, color: AppColors.success),
                        _buildFilterPill('Weaknesses (कमजोरी)', 2, color: AppColors.warning),
                        _buildFilterPill('Opportunities (अवसर)', 3, color: const Color(0xFF2563EB)),
                        _buildFilterPill('Threats (जोखिम)', 4, color: const Color(0xFFDC2626)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // 1. Strengths (Green)
                  if (_selectedQuadrant == 0 || _selectedQuadrant == 1) ...[
                    _buildQuadrantSection(
                      title: isHindi ? 'ताकत (Strengths)' : 'Enterprise Strengths',
                      icon: Icons.trending_up_rounded,
                      headerColor: AppColors.success,
                      bgColor: const Color(0xFFF0FDF4),
                      borderColor: const Color(0xFFBBF7D0),
                      items: swotData['strengths']!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 2. Weaknesses (Amber)
                  if (_selectedQuadrant == 0 || _selectedQuadrant == 2) ...[
                    _buildQuadrantSection(
                      title: isHindi ? 'कमजोरी (Weaknesses)' : 'Operational Constraints',
                      icon: Icons.warning_amber_rounded,
                      headerColor: AppColors.warning,
                      bgColor: const Color(0xFFFEF3C7).withValues(alpha: 0.6),
                      borderColor: const Color(0xFFFDE68A),
                      items: swotData['weaknesses']!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 3. Opportunities (Blue)
                  if (_selectedQuadrant == 0 || _selectedQuadrant == 3) ...[
                    _buildQuadrantSection(
                      title: isHindi ? 'अवसर (Opportunities)' : 'Market Opportunities',
                      icon: Icons.lightbulb_rounded,
                      headerColor: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFEFF6FF),
                      borderColor: const Color(0xFFBFDBFE),
                      items: swotData['opportunities']!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. Threats (Red)
                  if (_selectedQuadrant == 0 || _selectedQuadrant == 4) ...[
                    _buildQuadrantSection(
                      title: isHindi ? 'जोखिम (Threats)' : 'External Market Threats',
                      icon: Icons.shield_outlined,
                      headerColor: const Color(0xFFDC2626),
                      bgColor: const Color(0xFFFEF2F2),
                      borderColor: const Color(0xFFFECACA),
                      items: swotData['threats']!,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Strategic Action Mitigations Card
                  TactileCard(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: const Color(0xFFFDFBF7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.psychology_alt_rounded,
                                size: 20, color: AppColors.secondary),
                            const SizedBox(width: 8),
                            Text(
                              isHindi ? 'रणनीतिक समाधान एवं सुझाव' : 'Recommended Risk Mitigations',
                              style: AppTypography.labelLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildMitigationPoint(
                          title: isHindi ? 'थोक कच्चा माल बफर' : 'Raw Procurement Buffer',
                          desc: isHindi
                              ? 'कटाई के समय 45 दिन का भंडार सीधे मंडी से सुरक्षित करें।'
                              : 'Secure a 45-day raw material reserve directly during peak harvest window.',
                        ),
                        _buildMitigationPoint(
                          title: isHindi ? 'पीएमईजीपी पूंजी सब्सिडी' : '35% PMEGP Capital Subsidy',
                          desc: isHindi
                              ? 'सब्सिडी अनुदान से मशीनरी लागत घटाकर मासिक ईएमआई का बोझ कम करें।'
                              : 'Utilize 35% capital subsidy grant to minimize debt service requirements.',
                        ),
                        _buildMitigationPoint(
                          title: isHindi ? 'गुणवत्ता आश्वासन' : 'Branded Purity Packaging',
                          desc: isHindi
                              ? 'स्थानीय मिलावट के मुकाबले शुद्धता व स्वच्छता से ग्राहक विश्वास जीतें।'
                              : 'Compete against adulterated loose products using transparent tamper-proof packaging.',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Proceed to Financial Modeler
                  PrimaryButton(
                    label: isHindi
                        ? 'वित्तीय मॉडलर व लाभ विश्लेषण →'
                        : 'Simulate Financials & What-If →',
                    onPressed: () {
                      Navigator.pushNamed(context, '/finance-modeler');
                    },
                  ),
                ],
              ),
            ),
      ),
      floatingActionButton: VoiceMicButton(
        size: 52,
        hasElevation: true,
        tooltip: isHindi ? 'SWOT विश्लेषण सुनें' : 'Listen to SWOT Summary',
        onTap: () {
          voiceService.speakText(
            isHindi
                ? '${business.title} के सामर्थ्य, कमज़ोरियों और अवसरों का विश्लेषण तैयार है।'
                : 'Here is your SWOT analysis and feasibility summary for ${business.title}.',
            languageCode: isHindi ? 'hi' : 'en',
          );
        },
      ),
    );
  }

  Widget _buildFilterPill(String label, int index, {Color? color}) {
    final isSelected = _selectedQuadrant == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: InkWell(
        onTap: () => setState(() => _selectedQuadrant = index),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? (color ?? AppColors.primary)
                : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: isSelected ? Colors.white : AppColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuadrantSection({
    required String title,
    required IconData icon,
    required Color headerColor,
    required Color bgColor,
    required Color borderColor,
    required List<SwotItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: headerColor),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTypography.labelLarge.copyWith(
                  color: headerColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor.withValues(alpha: 0.7)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: AppTypography.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.badge,
                            style: AppTypography.labelSmall.copyWith(
                              color: headerColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.detail,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMitigationPoint({
    required String title,
    required String desc,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0.0 : 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: AppColors.success),
          const SizedBox(width: 8),
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
                  desc,
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
  }

  Map<String, List<SwotItem>> _generateDynamicSwot({
    required String businessTitle,
    required String domain,
    required String district,
    required String block,
    required double capital,
  }) {
    final titleLower = businessTitle.toLowerCase();

    if (titleLower.contains('bamboo') || titleLower.contains('handicraft')) {
      return {
        'strengths': [
          const SwotItem(
            title: 'Abundant Raw Culm Stands',
            detail: 'Natural forest bamboo available directly within 15 km transport radius.',
            badge: 'High Advantage',
          ),
          const SwotItem(
            title: '42% Value-Add Margin Spread',
            detail: 'Low unit raw material cost converted into premium finished home decor.',
            badge: 'Strong Economics',
          ),
        ],
        'weaknesses': [
          const SwotItem(
            title: 'Seasoning & Weathering Moisture',
            detail: 'Requires covered drying sheds during monsoon season to avoid fungal staining.',
            badge: 'Operational',
          ),
        ],
        'opportunities': [
          const SwotItem(
            title: 'Eco-Tourism & Urban Lifestyle Demand',
            detail: 'Growing regional hotel and lifestyle gift demand for sustainable crafts.',
            badge: 'Expanding Catchment',
          ),
          const SwotItem(
            title: 'PM Vishwakarma Toolkit & PMEGP',
            detail: 'Eligible for artisan stipend, toolkit support, and 35% capital subsidy.',
            badge: 'Government Backed',
          ),
        ],
        'threats': [
          const SwotItem(
            title: 'Plastic & Cheap Synthetic Alternatives',
            detail: 'Plastic utility containers competing on low price points in weekly bazaars.',
            badge: 'Competitive Risk',
          ),
        ],
      };
    }

    if (titleLower.contains('dairy') || titleLower.contains('milk')) {
      return {
        'strengths': [
          const SwotItem(
            title: 'Perennial Daily Cash Inflow',
            detail: 'Daily liquid consumption creates immediate positive working cash cycle.',
            badge: 'High Liquidity',
          ),
          SwotItem(
            title: 'Direct Farmer Procurement Network',
            detail: 'Sourcing pure milk directly from 15+ village cattle owners in $block.',
            badge: 'Cost Leadership',
          ),
        ],
        'weaknesses': [
          const SwotItem(
            title: 'Perishable Cold-Chain Sensitivity',
            detail: 'Requires backup power or chilled storage within 4 hours of morning milking.',
            badge: 'Critical Quality',
          ),
        ],
        'opportunities': [
          const SwotItem(
            title: 'High-Margin Fresh Paneer & Ghee',
            detail: 'Converting surplus milk into paneer (₹360/kg) increases gross margins by 28%.',
            badge: 'Value Addition',
          ),
        ],
        'threats': [
          const SwotItem(
            title: 'Cattle Feed Price Fluctuations',
            detail: 'Spikes in dry fodder prices can squeeze producer purchase terms.',
            badge: 'Supply Volatility',
          ),
        ],
      };
    }

    // Default / Agro-Processing (e.g. Mustard Oil Mill)
    return {
      'strengths': [
        SwotItem(
          title: 'Direct Mandi Seed Procurement',
          detail: '$district APMC Mandi ensures continuous seed supply without middlemen.',
          badge: 'Verified Supply',
        ),
        const SwotItem(
          title: '₹65/L Gross Operating Margin',
          detail: 'Cold-pressed extraction yields profitable margins over commercial blends.',
          badge: 'High Spread',
        ),
      ],
      'weaknesses': [
        const SwotItem(
          title: 'Harvest Working Capital Crunch',
          detail: 'Requires upfront capital reserve during peak mustard harvest months (Feb-April).',
          badge: 'Working Capital',
        ),
      ],
      'opportunities': [
        SwotItem(
          title: 'Untapped Village Haat Demand',
          detail: '4 neighboring weekly markets in $block lack fresh cold-pressed oil stalls.',
          badge: 'Growth Potential',
        ),
        const SwotItem(
          title: '35% Rural PMEGP Subsidy Sanction',
          detail: 'Qualifies for ₹63,000 non-repayable capital subsidy for rural entrepreneurs.',
          badge: 'Subsidy Aligned',
        ),
      ],
      'threats': [
        const SwotItem(
          title: 'Crop Harvest & Rainfall Fluctuations',
          detail: 'Unseasonal rains can trigger brief APMC price spikes for raw seeds.',
          badge: 'Commodity Risk',
        ),
        const SwotItem(
          title: 'Competitor Capacity Expansion',
          detail: 'Existing expeller mills may lower conversion rates to preserve local volume.',
          badge: 'Competition',
        ),
      ],
    };
  }
}
