import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

/// Screen 6: Mobile Business Confirmation Checkpoint
/// Stitch Reference: Screen f8dba77a7ba9476eb463d64e2e751e9a
class BusinessConfirmationScreen extends ConsumerStatefulWidget {
  const BusinessConfirmationScreen({super.key});

  @override
  ConsumerState<BusinessConfirmationScreen> createState() =>
      _BusinessConfirmationScreenState();
}

class _BusinessConfirmationScreenState
    extends ConsumerState<BusinessConfirmationScreen> {
  bool _isLoading = false;

  Future<void> _handleConfirmAndProceed() async {
    if (_isLoading) return;

    final business = ref.read(selectedBusinessProvider);
    final profile = ref.read(businessProfileProvider);

    // If business is already created and has real server businessId, avoid duplicate creation
    if (business.businessId != null && business.businessId!.isNotEmpty) {
      ref.read(selectedBusinessProvider.notifier).setStatus('VALIDATING');
      Navigator.pushNamed(context, '/research-progress');
      return;
    }

    // Guard: Verify profile dependency from Phase 2
    if (profile.profileId == null || profile.profileId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Entrepreneur profile not found. Please complete profile setup first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final isHindi = ref.read(localeProvider).languageCode == 'hi';

    try {
      final apiClient = ref.read(apiClientProvider);
      final payload = {
        'name': business.title,
        'domain': business.domain,
        'product_or_service': business.title,
        'business_model': 'Direct retail & local haat distribution',
        'description':
            '${business.title} located in ${profile.block}, ${profile.district}',
        'target_customer': isHindi
            ? 'गाँव के परिवार, साप्ताहिक हाट और ग्रामीण किराना स्टोर'
            : 'Local village households, weekly haat vendors & grocery stores',
        'intended_market':
            '${profile.block} Block, ${profile.district} (~10 km radius)',
        'scale': 'micro',
      };

      final res = await apiClient.post(
        ApiEndpoints.businesses,
        body: payload,
      );

      // Extract server-generated business ID and persist in Riverpod
      if (res != null &&
          res is Map &&
          res['data'] != null &&
          res['data']['id'] != null) {
        final serverBusinessId = res['data']['id'].toString();
        ref.read(selectedBusinessProvider.notifier).setBusinessId(serverBusinessId);
        ref.read(selectedBusinessProvider.notifier).setStatus('VALIDATING');

        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, '/research-progress');
        }
      } else {
        throw Exception('Invalid response structure from server.');
      }
    } catch (e) {
      debugPrint('Business creation failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create business: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
        stepText: isHindi ? 'पुष्टि चरण • 100% तैयार' : 'Checkpoint • Ready',
        showAudioButton: true,
        onAudioTap: () {
          final voiceService = ref.read(voiceServiceProvider);
          final readout = isHindi
              ? 'व्यवसाय योजना की पुष्टि: ${business.title} के लिए सभी विवरण तैयार हैं।'
              : 'Business confirmation: All details for ${business.title} are ready to proceed.';
          voiceService.speakText(readout, languageCode: isHindi ? 'hi' : 'en');
        },
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title & Description
              Text(
                isHindi
                    ? 'व्यवसाय योजना की पुष्टि करें'
                    : 'Confirm Your Business Idea',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHindi
                    ? 'बाजार सत्यापन और वित्तीय योजना शुरू करने से पहले विवरण की पुष्टि करें।'
                    : 'Review the details below before we begin local market research.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 16),

              // Central Summary Card
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF2E8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFCD7C0)),
                          ),
                          child: Text(
                            isHindi ? 'चयनित अवसर' : 'Selected Opportunity',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.successBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded,
                                  size: 14, color: AppColors.success),
                              const SizedBox(width: 4),
                              Text(
                                isHindi ? 'सत्यापन योग्य' : 'Validated',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Business Title & Domain
                    Text(
                      business.title,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      business.domain,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const Divider(height: 24, color: AppColors.border),

                    // Key Parameters
                    _buildParameterRow(
                      icon: Icons.groups_rounded,
                      label: isHindi ? 'लक्षित ग्राहक' : 'Target Customers',
                      value: isHindi
                          ? 'गाँव के परिवार, साप्ताहिक हाट और ग्रामीण किराना स्टोर'
                          : 'Local village households, weekly haat vendors & grocery stores',
                    ),

                    const SizedBox(height: 12),

                    _buildParameterRow(
                      icon: Icons.location_on_rounded,
                      label: isHindi ? 'लक्षित क्षेत्र' : 'Target Area',
                      value: '${profile.block} Block, ${profile.district} (~10 km radius)',
                    ),

                    const SizedBox(height: 12),

                    _buildParameterRow(
                      icon: Icons.precision_manufacturing_rounded,
                      label: isHindi ? 'दैनिक उत्पादन क्षमता' : 'Operating Scale',
                      value: '100 kg/day raw seed processing',
                    ),

                    const SizedBox(height: 12),

                    _buildParameterRow(
                      icon: Icons.account_balance_wallet_rounded,
                      label: isHindi ? 'कुल अनुमानित पूंजी' : 'Capital Required',
                      value: '₹${(business.estimatedCapital / 100000).toStringAsFixed(2)} Lakh (Self: ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K + Loan/Subsidy)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Upcoming Steps Roadmap Card
              TactileCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isHindi ? 'आगे क्या होगा?' : 'What Happens Next',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildRoadmapStep('1', isHindi ? 'स्थानीय बाजार अनुसंधान' : 'Local Market Research', isHindi ? 'मंडी भाव व प्रतियोगी विश्लेषण' : 'Mandi prices & local competitor signals'),
                    const SizedBox(height: 8),
                    _buildRoadmapStep('2', isHindi ? 'वित्तीय तनाव परीक्षण' : 'Financial Cash Flow Model', isHindi ? 'ऋण किस्त (EMI) व मासिक बचत' : 'Loan EMI & stress-testing lower sales'),
                    const SizedBox(height: 8),
                    _buildRoadmapStep('3', isHindi ? 'सरकारी योजना सहायता' : 'Government Sanction Plan', isHindi ? '35% PMEGP सब्सिडी आवेदन' : '35% subsidy checklist & milestones'),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Primary CTA: Confirm and Begin Research
              PrimaryButton(
                label: isHindi
                    ? 'पुष्टि करें और बाजार जांच शुरू करें'
                    : 'Confirm & Begin Market Research →',
                isLoading: _isLoading,
                onPressed: _handleConfirmAndProceed,
              ),

              const SizedBox(height: 10),

              // Change Selection Outline Button
              SizedBox(
                height: 48,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    isHindi ? 'वापस जाएं व दूसरा अवसर चुनें' : 'Change Selection',
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

  Widget _buildParameterRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRoadmapStep(String num, String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              num,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
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
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
