import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
// import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class LanguageOption {
  final String code;
  final String displayName;
  final String audioSample;
  final String playText;

  const LanguageOption({
    required this.code,
    required this.displayName,
    required this.audioSample,
    required this.playText,
  });
}

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen> {
  // Updated list matching the image exactly
  final List<LanguageOption> _languages = const [
    LanguageOption(
      code: 'hi',
      displayName: 'हिन्दी (Hindi)',
      audioSample: '"नमस्ते, मैं आपका व्यापार मित्र हूँ"',
      playText: 'सुनें',
    ),
    LanguageOption(
      code: 'en',
      displayName: 'English',
      audioSample: '"Hello, I am your Vyapar Mitra"',
      playText: 'Play',
    ),
    LanguageOption(
      code: 'mr',
      displayName: 'मराठी (Marathi)',
      audioSample: '"नमस्कार, मी व्यापार मित्र आहे"',
      playText: 'Play',
    ),
    LanguageOption(
      code: 'gu',
      displayName: 'ગુજરાતી (Gujarati)',
      audioSample: '"નમસ્તે, હું વ્યાપાર મિત્ર છું"',
      playText: 'Play',
    ),
    LanguageOption(
      code: 'bn',
      displayName: 'বাংলা (Bengali)',
      audioSample: '"নমস্কার, আমি ব্যাপার মিত্র"',
      playText: 'Play',
    ),
    LanguageOption(
      code: 'ta',
      displayName: 'தமிழ் (Tamil)',
      audioSample: '"வணக்கம், நான் வியாபார மித்ரா"',
      playText: 'Play',
    ),
    LanguageOption(
      code: 'te',
      displayName: 'తెలుగు (Telugu)',
      audioSample: '"నమస్కారం, నేను వ్యాపార మిత్రను"',
      playText: 'Play',
    ),
  ];

  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = ref.read(localeProvider).languageCode;
    if (!_languages.any((l) => l.code == _selectedCode)) {
      _selectedCode = 'hi';
    }
  }

  void _onLanguageTap(String code) {
    setState(() => _selectedCode = code);
    ref.read(localeProvider.notifier).setLocale(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Light cream background
      appBar: const VyaparTopAppBar(
        title: 'VYAPAR MITRA',
        stepText: 'चरण • 1 of 4',
        progress: 0.25,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EFE8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 8, color: Color(0xFF2E6C45)),
                    const SizedBox(width: 8),
                    Text(
                      'LOCAL LANGUAGE SELECTION • भाषा चयन',
                      style: AppTypography.labelSmall.copyWith(
                        color: const Color(0xFF2E6C45),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Headlines
              Text(
                'Choose Your Language',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w900,
                  fontSize: 26,
                  color: const Color(0xFF23140C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'अपनी पसंदीदा भाषा चुनें',
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFC04F27),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'The AI business companion will speak, explain local mandi rates, and verify government schemes in your preferred language.',
                style: AppTypography.bodyMedium.copyWith(
                  color: const Color(0xFF6B635E),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 24),

              // Tap & Speak Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7F2),
                  border: Border.all(color: const Color(0xFFF4D4C4), width: 1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEA6634),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mic, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'आवाज़ से बताएं / Tap & Speak',
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF23140C),
                            ),
                          ),
                          Text(
                            '"व्यापार मित्र, हिंदी में बात करो"',
                            style: AppTypography.bodySmall.copyWith(
                              color: const Color(0xFF6B635E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF23140C),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Mic',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.circle, size: 6, color: Color(0xFFEA6634)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Language List
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _languages.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  final isSelected = _selectedCode == lang.code;

                  return GestureDetector(
                    onTap: () => _onLanguageTap(lang.code),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFFFF9F5) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? const Color(0xFF23140C) : const Color(0xFFE5E0DA),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? const Color(0xFF23140C) : const Color(0xFFC4BDB7),
                            size: 24,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      lang.displayName,
                                      style: AppTypography.bodyMedium.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF23140C),
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF4D4C4),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'डिफ़ॉल्ट / SELECTED',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: const Color(0xFFC04F27),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lang.audioSample,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: const Color(0xFF6B635E),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFDF0E9) : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? const Color(0xFFF4D4C4) : const Color(0xFFE5E0DA),
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.volume_up_outlined, // Closer to image than play arrow
                                  size: 16,
                                  color: isSelected ? const Color(0xFFC04F27) : const Color(0xFF6B635E),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  lang.playText,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: isSelected ? const Color(0xFFC04F27) : const Color(0xFF6B635E),
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
                },
              ),

              const SizedBox(height: 16),

              // Trust Note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFECE8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 20, color: Color(0xFF4A6B53)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '100% Vernacular AI: Voice guides and government scheme details adapt automatically to your selection. Change anytime.',
                        style: AppTypography.bodySmall.copyWith(
                          color: const Color(0xFF6B635E),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Retained Action Button from original snippet
              PrimaryButton(
                label: _selectedCode == 'hi' ? 'आगे बढ़ें' : 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () {
                  ref.read(localeProvider.notifier).setLocale(_selectedCode);
                  Navigator.pushNamed(context, '/profile');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}