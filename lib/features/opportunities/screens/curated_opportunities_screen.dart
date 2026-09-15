import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_typography.dart';

class BusinessAdvisorScreen extends ConsumerStatefulWidget {
  const BusinessAdvisorScreen({super.key});

  @override
  ConsumerState<BusinessAdvisorScreen> createState() =>
      _BusinessAdvisorScreenState();
}

class _BusinessAdvisorScreenState extends ConsumerState<BusinessAdvisorScreen> {
  final TextEditingController _chatController = TextEditingController();

  // Colors based on the UI design
  final Color _bgColor = const Color(0xFFF9F4EE);
  final Color _darkBrown = const Color(0xFF2C1004);
  final Color _orangeAccent = const Color(0xFFC14D24);
  final Color _userBubble = const Color(0xFF132A40); // Dark navy blue
  final Color _textMuted = const Color(0xFF8B7F76);

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM APP BAR ---
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E0DA), width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Avatar with Online Dot
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://i.pravatar.cc/150?img=11',
                        ), // Placeholder for advisor image
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981), // Emerald green
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),

                  // Titles
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Advisor AI',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'VYAPAR MITRA • Discovery Step 2 of 4',
                          style: AppTypography.labelSmall.copyWith(
                            color: _textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Global Listen Button
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFF0D5C9)),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.volume_up_outlined,
                          size: 16,
                          color: _orangeAccent,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Listen',
                          style: AppTypography.labelSmall.copyWith(
                            color: _darkBrown,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Orange Progress Strip
            Container(
              height: 3,
              width: double.infinity,
              color: const Color(0xFFE5E0DA),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: 0.5, // Step 2 of 4
                child: Container(color: _orangeAccent),
              ),
            ),

            // --- CHAT HISTORY AREA ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                children: [
                  // Date Pill
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E0DA)),
                      ),
                      child: Text(
                        'Today, 10:42 AM',
                        style: AppTypography.labelSmall.copyWith(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AI Message 1
                  _buildAiMessage(
                    text: 'Tell me about your practical skills or what kind of work you enjoy most.',
                    bottomWidget: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.only(top: 12),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFF3EFEA)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.graphic_eq,
                                size: 14,
                                color: _orangeAccent,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Listen (0:12)',
                                style: AppTypography.labelSmall.copyWith(
                                  color: _orangeAccent,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Voice note ready',
                            style: AppTypography.labelSmall.copyWith(
                              color: _textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // User Message
                  _buildUserMessage(
                    text: 'I have 4 years of experience with agricultural crops and farm machinery.',
                  ),
                  const SizedBox(height: 4),

                  // Sent Status
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '10:43 AM • Sent',
                          style: AppTypography.labelSmall.copyWith(
                            color: _textMuted,
                            fontSize: 10,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.done_all,
                          size: 14,
                          color: Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // AI Message 2
                  _buildAiMessage(
                    text: 'That is valuable. In your Sanwer area, do you have direct access to raw mustard or oilseed crops, or a storage shed?',
                    bottomWidget: Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF9F1), // Soft green
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC1E1C5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: Color(0xFF166534),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Aligned with Mini Cold-Press Oil Mill potential',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF166534),
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- BOTTOM INPUT AREA ---
            Container(
              decoration: const BoxDecoration(
                color: Color(0xFFFDFBF8), // Slightly lighter bottom area
                border: Border(top: BorderSide(color: Color(0xFFE5E0DA))),
              ),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK TAP RESPONSE:',
                    style: AppTypography.labelSmall.copyWith(
                      color: _textMuted,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Suggestion Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickResponseChip(
                        Icons.agriculture_outlined,
                        'Direct farm access',
                      ),
                      _buildQuickResponseChip(
                        Icons.storefront_outlined,
                        'Have storage space',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Big Orange Voice Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orangeAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const SizedBox(width: 24), // Balance spacing
                          Text(
                            'Tap to Speak (Voice Answer)',
                            style: AppTypography.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic_none,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Text Input Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFE5E0DA)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _chatController,
                                  decoration: InputDecoration(
                                    hintText: 'Type your answer...',
                                    hintStyle: AppTypography.bodyMedium
                                        .copyWith(
                                          color: const Color(0xFFB3AAA1),
                                        ),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.mic_none,
                                color: Color(0xFFB3AAA1),
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Send Button
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _userBubble,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_upward_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Skip Link
                  Center(
                    child: InkWell(
                      onTap: () {},
                      child: Text(
                        'Skip for now',
                        style: AppTypography.labelSmall.copyWith(
                          color: _darkBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  // Helper for AI Messages (Left side)
  Widget _buildAiMessage({required String text, Widget? bottomWidget}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(right: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4), // Pointy corner
          ),
          border: Border.all(color: const Color(0xFFE5E0DA), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: _darkBrown,
                height: 1.4,
                fontSize: 14,
              ),
            ),
            if (bottomWidget != null) bottomWidget,
          ],
        ),
      ),
    );
  }

  // Helper for User Messages (Right side)
  Widget _buildUserMessage({required String text}) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(left: 40),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _userBubble,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4), // Pointy corner
          ),
        ),
        child: Text(
          text,
          style: AppTypography.bodyMedium.copyWith(
            color: Colors.white,
            height: 1.4,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  // Helper for Quick Response Chips
  Widget _buildQuickResponseChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E0DA)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _orangeAccent),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTypography.labelMedium.copyWith(
              color: _darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

typedef CuratedOpportunitiesScreen = BusinessAdvisorScreen;
