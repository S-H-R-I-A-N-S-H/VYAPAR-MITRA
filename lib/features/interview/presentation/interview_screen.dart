import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';

class InterviewScreen extends StatelessWidget {
  const InterviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Business Discovery'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
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
                        'नमस्ते! मैं आपका व्यापार सलाहकार हूँ। आप अपने इलाके में किस प्रकार का व्यापार शुरू करना चाहते हैं?',
                        style: AppTypography.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                decoration: InputDecoration(
                  hintText: 'उदा. मैं 10 गायों के साथ दूध संकलन केंद्र शुरू करना चाहता हूँ...',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.mic, color: AppColors.primary),
                    onPressed: () {},
                  ),
                ),
                maxLines: 3,
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
