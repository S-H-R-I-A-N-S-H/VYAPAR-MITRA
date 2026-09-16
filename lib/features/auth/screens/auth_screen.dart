import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/tactile_card.dart';
import '../../../shared/widgets/vyapar_top_app_bar.dart';

/// Screen: Multi-Method Authentication (Phone OTP & Email)
/// Adheres strictly to the "Empowered Enterprise" design system tokens.
class AuthScreen extends ConsumerStatefulWidget {
  final String? redirectRoute;

  const AuthScreen({super.key, this.redirectRoute});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Phone OTP controllers
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _otpSent = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  // Email controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    setState(() => _resendCountdown = 45);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  void _onAuthSuccess() {
    if (!mounted) return;
    final target = widget.redirectRoute ?? '/profile';
    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      Navigator.pushReplacementNamed(context, target);
    }
  }

  Future<void> _handleSendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length < 10) {
      setState(() {
        _errorMessage = 'कृपया 10 अंकों का मोबाइल नंबर दर्ज करें (Please enter a valid 10-digit phone number)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).signInWithPhone(rawPhone);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        _startCountdown();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP आपके मोबाइल पर भेज दिया गया है (OTP has been sent)'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final errStr = e.toString().replaceFirst('Exception: ', '');
        final isPhoneDisabled = errStr.contains('phone_provider_disabled') ||
            errStr.contains('Unsupported phone provider');
        final isHindi = ref.read(localeProvider).languageCode == 'hi';
        setState(() {
          _isLoading = false;
          _errorMessage = isPhoneDisabled
              ? (isHindi
                  ? 'एसएमएस सेवा (SMS Gateway) इस प्रोजेक्ट में सक्रिय नहीं है। कृपया ईमेल/पासवर्ड टैब या त्वरित डेवलपर लॉगिन का उपयोग करें।'
                  : 'SMS Gateway is not configured on this Supabase instance. Please use the Email / Password tab or Quick Dev Login below.')
              : errStr;
        });
      }
    }
  }

  Future<void> _handleVerifyOtp() async {
    final rawPhone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length < 6) {
      setState(() {
        _errorMessage = 'कृपया 6 अंकों का OTP दर्ज करें (Please enter the 6-digit OTP)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).verifyPhoneOtp(rawPhone, otp);
      if (mounted) {
        setState(() => _isLoading = false);
        _onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (!email.contains('@') || !email.contains('.')) {
      setState(() {
        _errorMessage = 'कृपया वैध ईमेल पता दर्ज करें (Please enter a valid email)';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        _errorMessage = 'पासवर्ड कम से कम 6 अक्षरों का होना चाहिए (Password must be at least 6 characters)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isSignUp) {
        await ref.read(authProvider.notifier).signUpWithEmail(email, password);
      } else {
        await ref.read(authProvider.notifier).signInWithEmail(email, password);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _onAuthSuccess();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  Future<void> _handleDevMockLogin() async {
    setState(() => _isLoading = true);
    await ref.read(authProvider.notifier).signInWithDevMock('dev-001');
    if (mounted) {
      setState(() => _isLoading = false);
      _onAuthSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: VyaparTopAppBar(
        title: AppConstants.appName,
        subtitle: isHindi ? 'उद्यमी प्रमाणीकरण' : 'Entrepreneur Sign In',
        showAudioButton: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Security Header Card
              TactileCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.verified_user_rounded,
                          size: 26,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'सुरक्षित एवं व्यक्तिगत खाता' : 'Secure Personalized Account',
                            style: AppTypography.headlineSmall.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isHindi
                                ? 'आपका व्यवसाय डेटा, सब्सिडी योजना और शोध सुरक्षित रहते हैं।'
                                : 'Your business data, scheme applications and research stay protected.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Tab Selector (Phone OTP vs Email)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: AppTypography.labelMedium.copyWith(fontWeight: FontWeight.bold),
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.phone_android_rounded, size: 18),
                      text: isHindi ? 'मोबाइल OTP (अनुशंसित)' : 'Mobile OTP',
                    ),
                    Tab(
                      icon: const Icon(Icons.mail_outline_rounded, size: 18),
                      text: isHindi ? 'ईमेल / पासवर्ड' : 'Email / Password',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Error Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Tab Views Container
              SizedBox(
                height: 320,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Phone OTP
                    _buildPhoneOtpTab(isHindi),
                    // Tab 2: Email & Password
                    _buildEmailTab(isHindi),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Developer Sandbox Mode Card (for local dev/offline tests)
              TactileCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.code_rounded, size: 20, color: AppColors.secondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHindi ? 'स्थानीय परीक्षण मोड' : 'Local Sandbox Mode',
                            style: AppTypography.labelMedium.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'mock-user-dev-001 (Zero SMS)',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _isLoading ? null : _handleDevMockLogin,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: AppColors.secondary.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        isHindi ? 'लॉगिन करें →' : 'Quick Dev Login →',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneOtpTab(bool isHindi) {
    return TactileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? '10-अंकों का मोबाइल नंबर' : '10-Digit Mobile Number',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    '+91',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Container(width: 1, height: 28, color: AppColors.border),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    enabled: !_otpSent && !_isLoading,
                    decoration: InputDecoration(
                      hintText: isHindi ? '9876543210' : 'Mobile Number',
                      border: InputBorder.none,
                      hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
                if (_otpSent)
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: AppColors.secondary),
                    onPressed: () => setState(() => _otpSent = false),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (!_otpSent) ...[
            const Spacer(),
            PrimaryButton(
              label: isHindi ? 'ओटीपी भेजें (Send OTP)' : 'Send Verification OTP',
              icon: Icons.sms_rounded,
              isLoading: _isLoading,
              onPressed: _handleSendOtp,
            ),
          ] else ...[
            Text(
              isHindi ? 'प्राप्त 6-अंकों का OTP दर्ज करें' : 'Enter 6-Digit OTP',
              style: AppTypography.labelMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.secondary),
              ),
              child: TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                enabled: !_isLoading,
                decoration: const InputDecoration(
                  hintText: '••••••',
                  border: InputBorder.none,
                ),
                style: AppTypography.headlineSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_resendCountdown > 0)
                  Text(
                    isHindi ? 'पुनः भेजें: $_resendCountdown से' : 'Resend in: ${_resendCountdown}s',
                    style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
                  )
                else
                  TextButton(
                    onPressed: _isLoading ? null : _handleSendOtp,
                    child: Text(
                      isHindi ? 'पुनः OTP भेजें' : 'Resend OTP',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const Spacer(),
            PrimaryButton(
              label: isHindi ? 'सत्यापित करें एवं आगे बढ़ें' : 'Verify & Continue',
              icon: Icons.check_circle_rounded,
              isLoading: _isLoading,
              onPressed: _handleVerifyOtp,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmailTab(bool isHindi) {
    return TactileCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isHindi ? 'ईमेल पता' : 'Email Address',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: 'entrepreneur@vyapar.in',
                border: InputBorder.none,
                hintStyle: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            isHindi ? 'पासवर्ड (कम से कम 6 अक्षर)' : 'Password (min 6 chars)',
            style: AppTypography.labelMedium.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: '••••••••',
                border: InputBorder.none,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => setState(() => _isSignUp = !_isSignUp),
                child: Text(
                  _isSignUp
                      ? (isHindi ? 'पहले से खाता है? लॉगिन करें' : 'Have an account? Sign In')
                      : (isHindi ? 'नया खाता बनाएं (Sign Up)' : 'Need an account? Sign Up'),
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          PrimaryButton(
            label: _isSignUp
                ? (isHindi ? 'खाता बनाएं एवं जारी रखें' : 'Sign Up & Continue')
                : (isHindi ? 'लॉगिन करें' : 'Sign In'),
            icon: Icons.login_rounded,
            isLoading: _isLoading,
            onPressed: _handleEmailAuth,
          ),
        ],
      ),
    );
  }
}
