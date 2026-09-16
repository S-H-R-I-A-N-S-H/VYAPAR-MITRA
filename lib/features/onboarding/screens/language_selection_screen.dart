import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class LanguageOption {
  final String code;
  final String englishName;
  final String nativeName;
  final String audioSample;

  const LanguageOption({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.audioSample,
  });
}

/// Screen 2: Minimalist Mobile Language Selection
/// Stitch Reference: Screen fdeb0e74a24c4cc3b13115bfe68e7586
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  final List<LanguageOption> _languages = const [
    LanguageOption(
      code: 'hi',
      englishName: 'Hindi',
      nativeName: 'हिन्दी',
      audioSample: 'नमस्ते! व्यापार मित्र में आपका स्वागत है',
    ),
    LanguageOption(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
      audioSample: 'Welcome to Vyapar Mitra business companion',
    ),
    LanguageOption(
      code: 'mr',
      englishName: 'Marathi',
      nativeName: 'मराठी',
      audioSample: 'नमस्कार! व्यापार मित्र मध्ये आपले स्वागत आहे',
    ),
    LanguageOption(
      code: 'gu',
      englishName: 'Gujarati',
      nativeName: 'ગુજરાતી',
      audioSample: 'નમસ્તે! વ્યાપાર મિત્રમાં તમારું સ્વાગત છે',
    ),
  ];

  String _selectedCode = 'hi';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final code = ref.read(localeProvider).languageCode;
      final resolved =
          _languages.any((l) => l.code == code) ? code : 'hi';
      if (_selectedCode != resolved) {
        setState(() => _selectedCode = resolved);
      }
    });
  }

  void _onLanguageTap(String code) {
    setState(() => _selectedCode = code);
    ref.read(localeProvider.notifier).setLocale(code);
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = _selectedCode == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'VYAPAR MITRA',
        stepText: isHindi ? 'चरण 1 / 4' : 'Step 1 of 4',
        progress: 0.25,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC8E6C9)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded,
                        size: 14, color: AppColors.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      isHindi ? 'भाषा चयन • LANGUAGE' : 'LANGUAGE SETTINGS',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Headline & Description
              Text(
                isHindi ? 'अपनी पसंदीदा भाषा चुनें' : 'Choose Your Language',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHindi
                    ? 'आप जिस भाषा में सहज महसूस करते हैं, उसे चुनें। इसे बाद में कभी भी बदला जा सकता है।'
                    : 'Select how you want Vyapar Mitra to talk to you. You can change this anytime.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              // 2x2 Language Cards Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final lang = _languages[index];
                    final isSelected = _selectedCode == lang.code;

                    return InkWell(
                      onTap: () => _onLanguageTap(lang.code),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : AppColors.border,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.08)
                                  : AppColors.primary.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  lang.nativeName,
                                  style: AppTypography.headlineSmall.copyWith(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? AppColors.primary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  lang.englishName,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? AppColors.tertiary
                                    : AppColors.surfaceVariant,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Trust note
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded,
                        size: 18, color: AppColors.tertiary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isHindi
                            ? 'आवाज मार्गदर्शन और सरकारी योजनाएं आपकी चुनी हुई भाषा में प्रदर्शित होंगी।'
                            : 'Voice guides and government scheme details adapt to your selection.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Continue Button
              PrimaryButton(
                label: isHindi ? 'आगे बढ़ें' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  ref.read(localeProvider.notifier).setLocale(_selectedCode);
                  Navigator.pushNamed(context, '/profile');
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
