import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
// import '../../../shared/widgets/vyapar_top_app_bar.dart';

class BusinessProfileScreen extends ConsumerStatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  ConsumerState<BusinessProfileScreen> createState() =>
      _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends ConsumerState<BusinessProfileScreen> {
  String _startingPosition = 'specific_idea'; // specific_idea, rough_idea, explore
  late TextEditingController _ideaController;
  late TextEditingController _nameController;
  double _capital = 60000;
  String _district = '';
  String _block = '';
  String _socialCategory = 'general';
  bool _isLoading = false;

  final List<String> _suggestions = const [
    'Spice Grinding',
    'Dairy Farm',
    'Flour Mill',
  ];

  static const List<String> _mpDistricts = [
    'Agar Malwa', 'Alirajpur', 'Anuppur', 'Ashoknagar', 'Balaghat',
    'Barwani', 'Betul', 'Bhind', 'Bhopal', 'Burhanpur',
    'Chhatarpur', 'Chhindwara', 'Damoh', 'Datia', 'Dewas',
    'Dhar', 'Dindori', 'Guna', 'Gwalior', 'Harda',
    'Hoshangabad', 'Indore', 'Jabalpur', 'Jhabua', 'Katni',
    'Khandwa', 'Khargone', 'Mandla', 'Mandsaur', 'Morena',
    'Narsinghpur', 'Neemuch', 'Panna', 'Raisen', 'Rajgarh',
    'Ratlam', 'Rewa', 'Sagar', 'Satna', 'Sehore',
    'Seoni', 'Shahdol', 'Shajapur', 'Sheopur', 'Shivpuri',
    'Sidhi', 'Singrauli', 'Tikamgarh', 'Ujjain', 'Umaria',
    'Vidisha',
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(businessProfileProvider);
    _startingPosition = profile.startingPosition.isNotEmpty
        ? profile.startingPosition
        : 'specific_idea';
    _ideaController = TextEditingController(
      text: profile.businessIdea.isNotEmpty
          ? profile.businessIdea
          : 'Cold-Press Oil Mill',
    );
    _nameController =
        TextEditingController(text: profile.fullName ?? 'Ramesh Kumar');
    _capital = profile.personalCapital;
    final hasValidDistrict = profile.district.isNotEmpty &&
        _mpDistricts.contains(profile.district);
    _district = hasValidDistrict ? profile.district : _mpDistricts.firstWhere(
          (district) => district == 'Indore',
          orElse: () => _mpDistricts.first,
        );
    _block = profile.block.isNotEmpty ? profile.block : 'Sanwer';
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

      if (res != null &&
          res is Map &&
          res['data'] != null &&
          res['data']['id'] != null) {
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
    const Color darkBrown = Color(0xFF2C1004);
    const Color orangeAccent = Color(0xFFC85A32);
    const Color bgColor = Color(0xFFFAF7F2);
    const Color cardBg = Colors.white;
    const Color borderColor = Color(0xFFEFE8DF);
    const Color textMuted = Color(0xFF736A63);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  // Back Button Circle
                  InkWell(
                    onTap: () => Navigator.maybePop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2ECE4),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: darkBrown,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Text(
                    'VYAPAR MITRA',
                    style: AppTypography.bodyMedium.copyWith(
                
      
                      fontWeight: FontWeight.w900,
                      color: darkBrown,
                      letterSpacing: 0.5,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  // Step Pill
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2ECE4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'Step 2 of\n4',
                      textAlign: TextAlign.center,
                      style: AppTypography.labelSmall.copyWith(
                        color: darkBrown,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Language Pill
                  InkWell(
                    onTap: () => Navigator.pushNamed(context, '/language'),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2ECE4),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'EN / हि',
                        style: AppTypography.labelSmall.copyWith(
                          color: darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Orange Progress Indicator
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFFF2ECE4),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5, // 50% for Step 2 of 4
                child: Container(
                  color: orangeAccent,
                ),
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business Profile Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6EDE2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.storefront_outlined,
                              size: 14, color: orangeAccent),
                          const SizedBox(width: 6),
                          Text(
                            'BUSINESS\nPROFILE',
                            style: AppTypography.labelSmall.copyWith(
                              color: darkBrown,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              height: 1.05,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Headline
                    Text(
                      'Do you have a business\nidea?',
                      style: AppTypography.headlineLarge.copyWith(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                        color: darkBrown,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    Text(
                      'Select where you are starting from today.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: textMuted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Option 1: Specific Idea (Selected card)
                    _buildSpecificIdeaCard(darkBrown, orangeAccent),

                    const SizedBox(height: 12),

                    // Option 2: Rough Idea
                    _buildRadioCard(
                      keyName: 'rough_idea',
                      title: 'I have a rough idea',
                      subtitle:
                          'We will help you narrow down products and machinery.',
                      icon: Icons.lightbulb_outline_rounded,
                      iconBg: const Color(0xFFFDEEE7),
                      iconColor: orangeAccent,
                      darkBrown: darkBrown,
                      textMuted: textMuted,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 12),

                    // Option 3: Help me find an idea
                    _buildRadioCard(
                      keyName: 'explore',
                      title: 'Help me find an idea',
                      subtitle:
                          'Discover high-demand opportunities tailored to your area.',
                      icon: Icons.explore_outlined,
                      iconBg: const Color(0xFFF3ECE6),
                      iconColor: darkBrown,
                      darkBrown: darkBrown,
                      textMuted: textMuted,
                      borderColor: borderColor,
                    ),

                    const SizedBox(height: 20),

                    // Government Scheme Benefit Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8EDE5),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.verified_user_outlined,
                            size: 18,
                            color: orangeAccent,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTypography.bodySmall.copyWith(
                                  color: const Color(0xFF5A4A42),
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                                children: const [
                                  TextSpan(text: 'Eligible for '),
                                  TextSpan(
                                    text: 'PMEGP & Mudra Scheme ',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  TextSpan(
                                    text: 'financial subsidies up to 35%.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Actions Strip
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: const BoxDecoration(
                color: bgColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tap to Speak Your Idea Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.mic_none_rounded,
                          size: 18, color: orangeAccent),
                      label: Text(
                        'Tap to Speak Your Idea',
                        style: AppTypography.labelMedium.copyWith(
                          color: darkBrown,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: cardBg,
                        side: const BorderSide(color: Color(0xFFE2D8CC)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSaveAndContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: darkBrown,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue',
                                  style: AppTypography.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sub-caption next step
                  RichText(
                    text: TextSpan(
                      style: AppTypography.labelSmall.copyWith(
                        fontSize: 11,
                        color: textMuted,
                      ),
                      children: const [
                        TextSpan(text: 'Next: '),
                        TextSpan(
                          text: 'Step 3: Location & Hyperlocal Market',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: darkBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecificIdeaCard(Color darkBrown, Color orangeAccent) {
    final isSelected = _startingPosition == 'specific_idea';

    return GestureDetector(
      onTap: () => setState(() => _startingPosition = 'specific_idea'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? darkBrown : const Color(0xFFEFE8DF),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Header: Checkmark, Title, Selected Tag
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD7F0DB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 16,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'I have a specific idea',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: darkBrown,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: darkBrown,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'SELECTED',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Input Box with mic icon inside
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF7F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE6DFD7)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ideaController,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: darkBrown,
                        fontSize: 15,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        hintText: 'e.g. Cold-Press Oil Mill',
                      ),
                    ),
                  ),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: orangeAccent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.mic, color: Colors.white, size: 20),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Suggestions row
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Text(
                  'Suggestions:',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF8B7F76),
                    fontSize: 12,
                  ),
                ),
                ..._suggestions.map((suggestion) {
                  return InkWell(
                    onTap: () {
                      setState(() {
                        _ideaController.text = suggestion;
                        _startingPosition = 'specific_idea';
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3ECE4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        suggestion,
                        style: AppTypography.bodySmall.copyWith(
                          color: darkBrown,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioCard({
    required String keyName,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color darkBrown,
    required Color textMuted,
    required Color borderColor,
  }) {
    final isSelected = _startingPosition == keyName;

    return GestureDetector(
      onTap: () => setState(() => _startingPosition = keyName),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? darkBrown : borderColor,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: darkBrown,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: textMuted,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? darkBrown : const Color(0xFFD4CDC5),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: darkBrown,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}