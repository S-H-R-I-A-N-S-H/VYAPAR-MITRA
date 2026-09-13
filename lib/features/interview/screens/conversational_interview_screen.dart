import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/floating_voice_bar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final String time;
  final String? insightBadge;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.insightBadge,
  });
}

/// Screen 4: AI Conversational Interview
/// Stitch Reference: Screen aab79a0eb1444362a5c0749d0cf0f375
class ConversationalInterviewScreen extends ConsumerStatefulWidget {
  const ConversationalInterviewScreen({super.key});

  @override
  ConsumerState<ConversationalInterviewScreen> createState() =>
      _ConversationalInterviewScreenState();
}

class _ConversationalInterviewScreenState
    extends ConsumerState<ConversationalInterviewScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAiResponding = false;
  int _turnCount = 0;

  final List<String> _quickChips = [
    'Direct farm access',
    'Have storage shed',
    'Starting from scratch',
    'Experience in sales',
  ];

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    final profile = ref.read(businessProfileProvider);
    final isHindi = ref.read(localeProvider).languageCode == 'hi';

    _messages.add(
      ChatMessage(
        text: isHindi
            ? 'नमस्ते! मैं आपका व्यापार मित्र सलाहकार हूँ। मुझे अपने अनुभव, हुनर या जिस काम में आपकी रुचि है, उसके बारे में बताएं।'
            : 'Welcome! I am your Vyapar Mitra business advisor. Tell me about your practical skills, experience, or what kind of work you enjoy most.',
        isUser: false,
        time: '10:42 AM',
        insightBadge: profile.businessIdea.isNotEmpty
            ? 'Aligned with ${profile.businessIdea} potential'
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(
          text: text.trim(),
          isUser: true,
          time: '10:43 AM',
        ),
      );
      _inputController.clear();
      _isAiResponding = true;
      _turnCount++;
    });

    _scrollToBottom();

    // Send turn to backend API (or sandbox fallback)
    try {
      final profile = ref.read(businessProfileProvider);
      final isHindi = ref.read(localeProvider).languageCode == 'hi';

      await Future.delayed(const Duration(milliseconds: 900));

      final aiReply = _turnCount == 1
          ? (isHindi
              ? 'यह बहुत अच्छा हुनर है! आपके क्षेत्र ${profile.block} में कच्चा माल (जैसे सरसों या तिलहन) सीधे किसानों से मिल सकता है या आपके पास भंडारण शेड उपलब्ध है?'
              : 'That is valuable experience! In your ${profile.block} area, do you have direct access to raw mustard/oilseed crops, or do you have a storage space?')
          : (isHindi
              ? 'बिल्कुल सही! आपके ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K निजी बजट और अनुभव के आधार पर हमने 3 अत्यधिक व्यवहार्य अवसर तैयार कर लिए हैं।'
              : 'Understood! Based on your experience and ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K capital, we have curated 3 high-viability business opportunities for you.');

      if (mounted) {
        setState(() {
          _isAiResponding = false;
          _messages.add(
            ChatMessage(
              text: aiReply,
              isUser: false,
              time: '10:44 AM',
              insightBadge: _turnCount >= 2
                  ? 'Eligible for 35% PMEGP subsidy'
                  : 'Verified local market demand',
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAiResponding = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final profile = ref.watch(businessProfileProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: 'Business Advisor AI',
        subtitle: 'VYAPAR MITRA',
        stepText: isHindi ? 'चरण 2 / 4' : 'Step 2 of 4',
        progress: 0.6,
        showAudioButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Extracted Factors Live Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: AppColors.surface,
              child: Row(
                children: [
                  const Icon(Icons.psychology_rounded,
                      size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFactorChip('₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K Budget'),
                          const SizedBox(width: 6),
                          _buildFactorChip('${profile.block}, ${profile.district}'),
                          const SizedBox(width: 6),
                          _buildFactorChip(profile.businessIdea),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Message Stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            if (_isAiResponding)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHindi ? 'सलाहकार विचार कर रहा है...' : 'Advisor is analyzing...',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Tap Chips
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _quickChips.map((chip) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ActionChip(
                        label: Text(chip),
                        labelStyle: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: AppColors.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(color: AppColors.border),
                        ),
                        onPressed: () => _sendMessage(chip),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // Complete / View Opportunities Button (visible when >= 2 turns)
            if (_turnCount >= 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: PrimaryButton(
                  label: isHindi
                      ? 'अवसर खोजें • View Opportunities'
                      : 'Discover Opportunities →',
                  onPressed: () {
                    Navigator.pushNamed(context, '/opportunities');
                  },
                ),
              ),

            // Floating Mic Voice Bar
            FloatingVoiceBar(
              onMicTap: () {
                _sendMessage('I have agricultural experience and raw crop access');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFactorChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12.0, left: 40.0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(4),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: Text(
            msg.text,
            style: AppTypography.bodyMedium.copyWith(color: Colors.white),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14.0, right: 30.0),
        child: TactileCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                msg.text,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.45,
                ),
              ),
              if (msg.insightBadge != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.infoBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFC6DAEE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          size: 14, color: AppColors.tertiary),
                      const SizedBox(width: 4),
                      Text(
                        msg.insightBadge!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up_rounded,
                          size: 16, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Listen',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    msg.time,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
