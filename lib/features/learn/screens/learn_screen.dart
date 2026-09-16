import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/tactile_card.dart';

/// Screen: Learn (Practical Business Knowledge Hub)
/// Conforms to SIH 26091 App UI Specification (Section 7.1)
/// Practical, localized business education feed tailored to entrepreneur domain and stage.
class LearnScreen extends ConsumerStatefulWidget {
  const LearnScreen({super.key});

  @override
  ConsumerState<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends ConsumerState<LearnScreen> {
  String _selectedCategory = 'all';

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final profile = ref.watch(businessProfileProvider);

    final categories = [
      {'key': 'all', 'label': isHindi ? 'सभी' : 'All'},
      {'key': 'tips', 'label': isHindi ? 'व्यापार टिप्स' : 'Business Tips'},
      {'key': 'schemes', 'label': isHindi ? 'सरकारी योजनाएं' : 'Schemes'},
      {'key': 'audio', 'label': isHindi ? 'ऑडियो / पॉडकास्ट' : 'Audio Guides'},
      {'key': 'stories', 'label': isHindi ? 'सफलता की कहानियां' : 'Case Studies'},
      {'key': 'compliance', 'label': isHindi ? 'नियम व लाइसेंस' : 'Compliance'},
    ];

    final articles = [
      {
        'category': 'tips',
        'title': isHindi
            ? 'सरसों बीज खरीद में 18% लागत कैसे बचाएं?'
            : 'How to save 18% on raw mustard procurement?',
        'summary': isHindi
            ? 'सांवेर व देवास मंडी के बीच सीधे किसान समूहों (FPO) से अनुबंध करके बिचौलियों का कमीशन घटाएं।'
            : 'Contract directly with FPOs between Sanwer and Dewas mandis to eliminate commission layers.',
        'duration': '3 min read',
        'isAudio': false,
        'tag': isHindi ? 'लागत नियंत्रण' : 'Cost Saving',
      },
      {
        'category': 'schemes',
        'title': isHindi
            ? 'PMEGP 35% सब्सिडी: आवेदन से स्वीकृति तक के 5 चरण'
            : 'PMEGP 35% Subsidy: 5 Steps from application to bank sanction',
        'summary': isHindi
            ? 'आवश्यक दस्तावेज: आधार, निवास, परियोजना रिपोर्ट (DPR), जाति प्रमाण पत्र व बैंक खाता विवरण।'
            : 'Key documents checklist: Aadhaar, Residence, DPR, Caste certificate, and 6-month statement.',
        'duration': '5 min read',
        'isAudio': false,
        'tag': isHindi ? 'सब्सिडी गाइड' : 'Subsidy Guide',
      },
      {
        'category': 'audio',
        'title': isHindi
            ? 'ऑडियो गाइड: छोटी तेल मिल के लिए FSSAI व बिजली कनेक्शन'
            : 'Audio Guide: FSSAI and Industrial Power for Mini Oil Mills',
        'summary': isHindi
            ? 'स्थानीय विद्युत विभाग से 10 HP वाणिज्यिक कनेक्शन लेने और बुनियादी स्वच्छता पंजीकरण की सरल प्रक्रिया।'
            : 'Step-by-step audio walkthrough for commercial power application and basic food safety registry.',
        'duration': '4 min listen',
        'isAudio': true,
        'tag': isHindi ? 'ऑडियो गाइड' : 'Audio Guide',
      },
      {
        'category': 'stories',
        'title': isHindi
            ? 'केस स्टडी: देवास के किसान ने कैसे शुरू की 120 किलो/दिन की मिनी मिल'
            : 'Case Study: How a farmer in Dewas scaled a 120 kg/day cold-press mill',
        'summary': isHindi
            ? '₹1.5 लाख की निजी पूंजी और मुद्रा ऋण से शुरू कर 8 महीने में ₹45,000 मासिक शुद्ध लाभ अर्जित किया।'
            : 'Started with ₹1.5L capital and Mudra loan, reaching ₹45,000 monthly net profit in 8 months.',
        'duration': '4 min read',
        'isAudio': false,
        'tag': isHindi ? 'प्रेरणा' : 'Inspiring',
      },
      {
        'category': 'compliance',
        'title': isHindi
            ? 'उद्यम आधार (Udyam Aadhaar) निःशुल्क 10 मिनट में कैसे बनाएं?'
            : 'How to register Udyam Aadhaar online for free in 10 minutes',
        'summary': isHindi
            ? 'सरकारी ऋण व ब्याज छूट प्राप्त करने के लिए सबसे पहला और अनिवार्य आधिकारिक पंजीकरण।'
            : 'The essential first step to access collateral-free priority sector bank loans.',
        'duration': '2 min read',
        'isAudio': false,
        'tag': isHindi ? 'अनिवार्य' : 'Mandatory',
      },
    ];

    final filteredArticles = (_selectedCategory == 'all')
        ? articles
        : articles.where((a) => a['category'] == _selectedCategory).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isHindi ? 'व्यापार ज्ञान एवं शिक्षा' : 'Business Knowledge Hub',
                    style: AppTypography.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isHindi
                        ? '${profile.block} व मध्य प्रदेश के ग्रामीण उद्यमियों के लिए व्यावहारिक मार्गदर्शन।'
                        : 'Practical, localized business education tailored to your region.',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // ── Filter Pills Bar ────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selectedCategory == cat['key'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat['label']!),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategory = cat['key']!),
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 12,
                      ),
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Content Feed ────────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                itemCount: filteredArticles.length,
                itemBuilder: (context, index) {
                  final item = filteredArticles[index];
                  final isAudio = item['isAudio'] as bool;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: TactileCard(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAudio ? AppColors.warningBg : AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAudio ? Icons.headphones_rounded : Icons.article_rounded,
                                      size: 12,
                                      color: isAudio ? AppColors.secondary : AppColors.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      item['tag'] as String,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: isAudio ? AppColors.secondary : AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                item['duration'] as String,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['title'] as String,
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            item['summary'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: isAudio ? AppColors.secondary : AppColors.primary,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                ),
                                icon: Icon(
                                  isAudio ? Icons.play_circle_fill_rounded : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  isAudio
                                      ? (isHindi ? 'ऑडियो सुनें' : 'Listen Now')
                                      : (isHindi ? 'पूरा पढ़ें' : 'Read Guide'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isAudio
                                            ? (isHindi ? 'ऑडियो मार्गदर्शिका चल रही है...' : 'Playing audio guide...')
                                            : (isHindi ? 'मार्गदर्शिका लोड हो रही है...' : 'Opening guide...'),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
