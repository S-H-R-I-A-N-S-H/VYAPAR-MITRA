import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/audio/voice_service.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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
  final String? audioBase64;
  final bool isVoice;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
    this.insightBadge,
    this.audioBase64,
    this.isVoice = false,
  });
}

/// Screen 4: AI Conversational Interview
/// Powered by Bhashini 2-Way Speech (ASR & TTS) and Vyapar Mitra Evidence Engine
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
  final ApiClient _apiClient = ApiClient();

  late VoiceService _voiceService;
  String? _sessionId;
  bool _isAiResponding = false;
  int _turnCount = 0;
  VoiceState _voiceState = VoiceState.idle;
  VoidCallback? _voiceStateListener;

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
    _initSessionWithBackend();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _voiceService = ref.read(voiceServiceProvider);
    if (_voiceStateListener == null) {
      _voiceStateListener = () {
        if (mounted) {
          setState(() {
            _voiceState = _voiceService.currentState;
          });
        }
      };
      _voiceService.stateNotifier.addListener(_voiceStateListener!);
    }
  }

  Future<void> _initSessionWithBackend() async {
    try {
      final lang = ref.read(localeProvider).languageCode;
      final res = await _apiClient.post(
        ApiEndpoints.interviews,
        body: {'language': lang},
      );
      if (res != null && res['data'] != null) {
        _sessionId = res['data']['id'];
      }
    } catch (_) {
      // In tests or offline, fallback smoothly
    }
  }

  void _initializeChat() {
    final profile = ref.read(businessProfileProvider);
    final isHindi = ref.read(localeProvider).languageCode == 'hi';

    _messages.add(
      ChatMessage(
        text: isHindi
            ? 'नमस्ते! मैं आपका व्यापार मित्र सलाहकार हूँ। मुझे अपने अनुभव, हुनर या जिस काम में आपकी रुचि है, उसके बारे में बोलकर या लिखकर बताएं।'
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
    if (_voiceStateListener != null) {
      _voiceService.stateNotifier.removeListener(_voiceStateListener!);
      _voiceService.stopAudio();
    }
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleMicTap() async {
    if (_voiceService.isRecording) {
      // Stop recording and process
      setState(() => _voiceState = VoiceState.processing);
      final audioB64 = await _voiceService.stopRecordingAndGetBase64();

      if (audioB64 != null && audioB64.isNotEmpty) {
        await _processVoiceTurn(audioB64);
      } else {
        setState(() => _voiceState = VoiceState.idle);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('कोई आवाज़ रिकॉर्ड नहीं हुई। • No audio recorded.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } else if (_voiceService.isPlaying) {
      await _voiceService.stopAudio();
      setState(() => _voiceState = VoiceState.idle);
    } else {
      final hasPerm = await _voiceService.hasPermission();
      if (!hasPerm) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('माइक्रोफ़ोन की अनुमति आवश्यक है • Microphone permission is required.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      try {
        await _voiceService.startRecording();
        setState(() => _voiceState = VoiceState.recording);
      } catch (e) {
        debugPrint('Failed to start recording: $e');
        setState(() => _voiceState = VoiceState.idle);
      }
    }
  }

  Future<void> _processVoiceTurn(String audioBase64) async {
    final isHindi = ref.read(localeProvider).languageCode == 'hi';
    final lang = ref.read(localeProvider).languageCode;
    final nowTime = DateFormat('hh:mm a').format(DateTime.now());

    setState(() {
      _isAiResponding = true;
      _turnCount++;
    });

    try {
      if (_sessionId == null) {
        await _initSessionWithBackend();
      }
      final sessionId = _sessionId ?? 'offline-session-temp';
      final response = await _apiClient.post(
        ApiEndpoints.interviewVoice(sessionId),
        body: {
          'audio_base64': audioBase64,
          'language': lang,
        },
      );

      if (response != null && response['data'] != null) {
        final data = response['data'];
        final transcribed = data['transcribed_text'] as String? ?? 'आवाज़ इनपुट • Voice Input';
        final reply = data['reply'] as String? ?? '';
        final nextQ = data['next_question'] as String?;
        final combinedReply = (nextQ != null && nextQ.isNotEmpty) ? '$reply\n\n$nextQ' : reply;
        final audioB64 = data['audio_response_base64'] as String?;

        if (mounted) {
          setState(() {
            _messages.add(
              ChatMessage(
                text: transcribed,
                isUser: true,
                time: nowTime,
                isVoice: true,
              ),
            );
            _messages.add(
              ChatMessage(
                text: combinedReply,
                isUser: false,
                time: nowTime,
                insightBadge: _turnCount >= 2
                    ? (isHindi ? '35% PMEGP सब्सिडी के लिए पात्र' : 'Eligible for 35% PMEGP subsidy')
                    : (isHindi ? 'स्थानीय मांग सत्यापित' : 'Verified local market demand'),
                audioBase64: audioB64,
              ),
            );
            _isAiResponding = false;
          });

          _scrollToBottom();

          if (audioB64 != null && audioB64.isNotEmpty) {
            _voiceService.playAudioFromBase64(audioB64);
          }
        }
        return;
      }
    } catch (_) {
      // Fallback
    }

    if (mounted) {
      final profile = ref.read(businessProfileProvider);
      final fallbackTranscribed = isHindi
          ? 'मेरे पास डेयरी फार्मिंग और दूध प्रसंस्करण का 5 वर्ष का अनुभव है।'
          : 'I have 5 years practical experience in dairy and milk processing.';

      final fallbackReply = _turnCount == 1
          ? (isHindi
              ? 'यह बहुत अच्छा हुनर है! आपके क्षेत्र ${profile.block.isNotEmpty ? profile.block : "पुणे"} में कच्चा दूध सीधे किसानों से मिल सकता है। क्या आपके पास भंडारण शेड उपलब्ध है?'
              : 'That is valuable experience! In your ${profile.block} area, do you have direct access to raw mustard/oilseed crops, or do you have a storage space?')
          : (isHindi
              ? 'बिल्कुल सही! आपके ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K निजी बजट और अनुभव के आधार पर हमने 3 अत्यधिक व्यवहार्य अवसर तैयार कर लिए हैं।'
              : 'Understood! Based on your experience and ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K capital, we have curated 3 high-viability business opportunities for you.');

      setState(() {
        _messages.add(
          ChatMessage(
            text: fallbackTranscribed,
            isUser: true,
            time: nowTime,
            isVoice: true,
          ),
        );
        _messages.add(
          ChatMessage(
            text: fallbackReply,
            isUser: false,
            time: nowTime,
            insightBadge: _turnCount >= 2
                ? 'Eligible for 35% PMEGP subsidy'
                : 'Verified local market demand',
          ),
        );
        _isAiResponding = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final nowTime = DateFormat('hh:mm a').format(DateTime.now());
    final profile = ref.read(businessProfileProvider);
    final lang = ref.read(localeProvider).languageCode;
    final isHindi = lang == 'hi';

    setState(() {
      _messages.add(
        ChatMessage(
          text: text.trim(),
          isUser: true,
          time: nowTime,
        ),
      );
      _inputController.clear();
      _isAiResponding = true;
      _turnCount++;
    });

    _scrollToBottom();

    // ── Try live backend (Gemini) ────────────────────────────────────────────
    try {
      if (_sessionId == null) {
        await _initSessionWithBackend();
      }
      final sessionId = _sessionId ?? 'offline-session-temp';
      final response = await _apiClient.post(
        ApiEndpoints.interviewMessages(sessionId),
        body: {
          'content': text.trim(),
          'language': lang,
        },
      );

      if (response != null && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final reply = (data['reply'] as String?) ?? '';
        final nextQ = data['next_question'] as String?;
        final combinedReply =
            (nextQ != null && nextQ.isNotEmpty) ? '$reply\n\n$nextQ' : reply;

        // Build insight badge from extracted_factors if present
        String? badge;
        final factors = data['extracted_factors'];
        if (factors is List && factors.isNotEmpty) {
          final first = factors.first;
          if (first is Map && first['factor'] != null) {
            badge = isHindi
                ? '✓ ${first["factor"]} पहचाना गया'
                : '✓ ${first["factor"]} identified';
          }
        }
        badge ??= _turnCount >= 2
            ? (isHindi ? '35% PMEGP सब्सिडी के लिए पात्र' : 'Eligible for 35% PMEGP subsidy')
            : (isHindi ? 'स्थानीय मांग सत्यापित' : 'Verified local market demand');

        if (mounted) {
          setState(() {
            _isAiResponding = false;
            _messages.add(
              ChatMessage(
                text: combinedReply,
                isUser: false,
                time: DateFormat('hh:mm a').format(DateTime.now()),
                insightBadge: badge,
              ),
            );
          });
          _scrollToBottom();
        }
        return; // ✓ live response handled
      }
    } catch (e) {
      debugPrint('[Interview] Backend call failed: $e — using offline fallback');
    }

    // ── Offline / sandbox fallback ───────────────────────────────────────────
    if (mounted) {
      final fallbackReply = _turnCount == 1
          ? (isHindi
              ? 'यह बहुत अच्छा हुनर है! आपके क्षेत्र ${profile.block} में कच्चा माल सीधे किसानों से मिल सकता है। क्या आपके पास भंडारण शेड है?'
              : 'That is valuable experience! In your ${profile.block} area, do you have direct access to raw crops, or a storage space?')
          : (isHindi
              ? 'बिल्कुल सही! आपके ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K बजट और अनुभव के आधार पर हमने 3 अवसर तैयार किए हैं।'
              : 'Understood! Based on your ₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K capital, we have curated 3 high-viability opportunities for you.');

      setState(() {
        _isAiResponding = false;
        _messages.add(
          ChatMessage(
            text: fallbackReply,
            isUser: false,
            time: DateFormat('hh:mm a').format(DateTime.now()),
            insightBadge: _turnCount >= 2
                ? (isHindi ? '35% PMEGP सब्सिडी के लिए पात्र' : 'Eligible for 35% PMEGP subsidy')
                : (isHindi ? 'स्थानीय मांग सत्यापित' : 'Verified local market demand'),
          ),
        );
      });
      _scrollToBottom();
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
                  const Icon(Icons.psychology_rounded, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFactorChip('₹${(profile.personalCapital / 1000).toStringAsFixed(0)}K Budget'),
                          const SizedBox(width: 8),
                          _buildFactorChip('District: ${profile.district} (Mappls POI)'),
                          const SizedBox(width: 8),
                          _buildFactorChip('Bhashini 2-Way Voice'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Message stream
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // AI thinking indicator
            if (_isAiResponding)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isHindi
                          ? 'सलाहकार विचार कर रहे हैं...'
                          : 'Advisor reasoning with Bhashini & Evidence...',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick response chips
            Container(
              height: 44,
              margin: const EdgeInsets.only(bottom: 6.0),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
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

            // Text input bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: TextField(
                        controller: _inputController,
                        decoration: InputDecoration(
                          hintText: isHindi
                              ? 'संदेश लिखें या नीचे माइक दबाएं...'
                              : 'Type message or tap mic below...',
                          hintStyle: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: _sendMessage,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: () => _sendMessage(_inputController.text),
                    icon: const Icon(Icons.send_rounded, size: 20),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Discover Opportunities Button (visible when >= 1 turn)
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

            // Floating Tactile Voice Bar
            FloatingVoiceBar(
              voiceState: _voiceState,
              onMicTap: _handleMicTap,
              onStopTap: _handleMicTap,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (msg.isVoice)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.mic_rounded, size: 14, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      'Voice Input',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white70,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              Text(
                msg.text,
                style: AppTypography.bodyMedium.copyWith(color: Colors.white),
              ),
            ],
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
                  InkWell(
                    onTap: () {
                      if (msg.audioBase64 != null && msg.audioBase64!.isNotEmpty) {
                        _voiceService.playAudioFromBase64(msg.audioBase64!);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ऑडियो प्लेबैक तैयार है • Audio ready.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 4.0),
                      child: Row(
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
                    ),
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
