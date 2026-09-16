import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/voice_aware_text_field.dart';

class InterviewScreen extends ConsumerWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceService = ref.read(voiceServiceProvider);
    const greetingText =
        'नमस्ते! मैं आपका व्यापार सलाहकार हूँ। आप अपने इलाके में किस प्रकार का व्यापार शुरू करना चाहते हैं?';

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Business Discovery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volume_up_rounded),
            tooltip: 'Listen to advisor',
            onPressed: () {
              voiceService.speakText(greetingText, languageCode: 'hi');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  voiceService.speakText(greetingText, languageCode: 'hi');
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          greetingText,
                          style: AppTypography.bodyLarge,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.volume_up_rounded, size: 20, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const VoiceAwareTextField(
                hintText: 'उदा. मैं 10 गायों के साथ दूध संकलन केंद्र शुरू करना चाहता हूँ...',
                maxLines: 3,
                languageCode: 'hi',
              ),
              const Spacer(),
              PrimaryButton(
                label: 'Financial Modeler →',
                onPressed: () {
                  Navigator.pushNamed(context, '/finance');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
