import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

/// Screen 3: Mobile Business Situation & Profile Setup
/// Stitch Reference: Screen bda550f78a554ad3a5e78c52c9c7effa
class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  String _startingPosition = 'specific_idea'; // specific_idea, general_domain, explore
  late TextEditingController _ideaController;
  late TextEditingController _nameController;
  double _capital = 60000;
  String _district = 'Indore';
  String _block = 'Sanwer';
  String _socialCategory = 'general';
  bool _isLoading = false;

  final List<double> _capitalPresets = [25000, 50000, 100000, 200000];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(businessProfileProvider);
    _startingPosition = profile.startingPosition;
    _ideaController = TextEditingController(text: profile.businessIdea);
    _nameController = TextEditingController(text: profile.fullName ?? 'Ramesh Kumar');
    _capital = profile.personalCapital;
    _district = profile.district;
    _block = profile.block;
    _socialCategory = profile.socialCategory;
  }

  @override
  void dispose() {
    _ideaController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveAndContinue() async {
    setState(() => _isLoading = true);

    // Update Riverpod state optimistically with form selections
    final updatedProfile = ref.read(businessProfileProvider).copyWith(
          fullName: _nameController.text.trim(),
          startingPosition: _startingPosition,
          businessIdea: _ideaController.text.trim(),
          personalCapital: _capital,
          district: _district,
          block: _block,
          socialCategory: _socialCategory,
        );
    ref.read(businessProfileProvider.notifier).updateProfile(updatedProfile);

    // Save profile to backend via ApiClient matching EntrepreneurProfileCreate contract
    try {
      final apiClient = ref.read(apiClientProvider);
      final payload = {
        'full_name': _nameController.text.trim(),
        'preferred_language': ref.read(localeProvider).languageCode,
        'voice_enabled': true,
        'location': {
          'state': 'Madhya Pradesh',
          'district': _district,
          'town_or_village': _block,
        },
        'available_capital': _capital,
        'skills': <String>['machinery'],
        'interests': <String>[],
        'risk_preference': 'moderate',
        'scheme_category': _socialCategory,
        'consent_recorded': true,
      };

      final res = await apiClient.post(
        ApiEndpoints.profile,
        body: payload,
      );

      // Extract server-assigned entrepreneur profile UUID and persist in Riverpod
      if (res != null && res is Map && res['data'] != null && res['data']['id'] != null) {
        final profileId = res['data']['id'].toString();
        ref.read(businessProfileProvider.notifier).setProfileId(profileId);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushNamed(context, '/interview');
      }
    } catch (e) {
      debugPrint('Profile creation failed: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'VYAPAR MITRA',
        stepText: isHindi ? 'चरण 2 / 4' : 'Step 2 of 4',
        progress: 0.5,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      isHindi ? 'व्यवसाय प्रोफ़ाइल' : 'BUSINESS SITUATION',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Title
              Text(
                isHindi
                    ? 'क्या आपके पास व्यवसाय का कोई विचार है?'
                    : 'Do you have a business idea?',
                style: AppTypography.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isHindi
                    ? 'अपनी मौजूदा स्थिति चुनें ताकि हम सटीक मार्गदर्शन कर सकें।'
                    : 'Select where you are starting from today.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 20),

              // Option 1: Specific Idea
              _buildOptionCard(
                positionKey: 'specific_idea',
                title: isHindi ? 'मेरे पास निश्चित विचार है' : 'I have a specific idea',
                subtitle: isHindi
                    ? 'जैसे तेल मिल, किराना स्टोर, वर्कशॉप'
                    : 'e.g. Cold-Press Oil Mill, Agro Shop',
                icon: Icons.check_circle_rounded,
                child: _startingPosition == 'specific_idea'
                    ? Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: TextField(
                          controller: _ideaController,
                          decoration: InputDecoration(
                            hintText: isHindi ? 'व्यवसाय का नाम लिखें' : 'Enter your business idea',
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.mic_rounded, color: AppColors.secondary),
                              onPressed: () {},
                            ),
                          ),
                        ),
                      )
                    : null,
              ),

              const SizedBox(height: 12),

              // Option 2: General Domain
              _buildOptionCard(
                positionKey: 'general_domain',
                title: isHindi ? 'मुझे कार्य का क्षेत्र पता है' : 'I have a general domain',
                subtitle: isHindi
                    ? 'कृषि प्रसंस्करण, खुदरा व्यापार, स्थानीय सेवाएं'
                    : 'Agri-processing, Rural Retail, Village Services',
                icon: Icons.category_rounded,
              ),

              const SizedBox(height: 12),

              // Option 3: Explore
              _buildOptionCard(
                positionKey: 'explore',
                title: isHindi ? 'मुझे कोई विचार नहीं है (मदद करें)' : 'I don\'t have an idea yet',
                subtitle: isHindi
                    ? 'मेरे बजट और मंडी मांग के आधार पर सुझाव दें'
                    : 'Recommend viable ideas matching my budget and local market',
                icon: Icons.explore_rounded,
              ),

              const SizedBox(height: 24),

              // Capital Selection Section
              Text(
                isHindi ? 'उपलब्ध निजी पूंजी (बजट)' : 'Available Personal Capital',
                style: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                isHindi
                    ? 'वह राशि जो आप स्वयं लगा सकते हैं (बाकी बैंक ऋण द्वारा)'
                    : 'Funds you can personally invest (remaining via bank subsidy loan)',
                style: AppTypography.bodySmall,
              ),

              const SizedBox(height: 12),

              // Preset Capital Chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _capitalPresets.map((amt) {
                  final isSelected = _capital == amt;
                  return ChoiceChip(
                    label: Text(
                      '₹${(amt / 1000).toStringAsFixed(0)}K',
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected ? Colors.white : AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _capital = amt);
                    },
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),

              // Location Section
              TactileCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.infoBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, color: AppColors.info),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'कार्यक्षेत्र (ब्लॉक व जिला)' : 'Target Location',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '$_block, $_district (M.P.)',
                            style: AppTypography.labelLarge.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_location_alt_rounded,
                          color: AppColors.secondary),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit & Continue CTA
              PrimaryButton(
                label: isHindi ? 'एआई सलाहकार से बात करें' : 'Continue to AI Interview',
                icon: Icons.arrow_forward_rounded,
                isLoading: _isLoading,
                onPressed: _handleSaveAndContinue,
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required String positionKey,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? child,
  }) {
    final isSelected = _startingPosition == positionKey;

    return TactileCard(
      onTap: () => setState(() => _startingPosition = positionKey),
      border: Border.all(
        color: isSelected ? AppColors.primary : AppColors.border,
        width: isSelected ? 2.0 : 1.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.tertiary : AppColors.surfaceVariant,
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 18, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.labelLarge.copyWith(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ?child,
        ],
      ),
    );
  }
}
