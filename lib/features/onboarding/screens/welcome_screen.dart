import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Colors matching the UI design exactly
    const Color darkBrown = Color(0xFF2C1004);
    const Color accentRed = Color(0xFF9E3A21);
    const Color bgColor = Color(0xFFF8F3ED);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // --- TOP APP BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Profile Icon
                    IconButton(
                      icon: const Icon(
                        Icons.person_outline,
                        size: 28,
                        color: darkBrown,
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                    ),

                    // Start a Venture Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: darkBrown.withValues(alpha: 0.2),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.storefront_outlined,
                            size: 16,
                            color: darkBrown,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'START A\nVENTURE',
                            textAlign: TextAlign.center,
                            style: AppTypography.labelSmall.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: darkBrown,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Language Toggle Pill
                    InkWell(
                      onTap: () => Navigator.pushNamed(context, '/language'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: darkBrown.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.translate,
                              size: 16,
                              color: darkBrown,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'EN /\nहि',
                              textAlign: TextAlign.center,
                              style: AppTypography.labelSmall.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: darkBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // --- MAIN HEADLINE ---
              Text(
                'START YOUR\nLOCAL BUSINESS',
                textAlign: TextAlign.center,
                style: AppTypography.headlineLarge.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  color: darkBrown,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),

              const SizedBox(height: 32),

              // --- CENTRAL CARD ---
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 36,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Subtitle
                    Text(
                      'AI BUSINESS COMPANION',
                      style: AppTypography.labelSmall.copyWith(
                        color: accentRed,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card Title
                    Text(
                      'PLAN. VALIDATE.\nGET FUNDED.',
                      textAlign: TextAlign.center,
                      style: AppTypography.headlineMedium.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: darkBrown,
                        height: 1.15,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Start Now Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/language'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: darkBrown, // Dark brown background
                          foregroundColor: Colors.white, // Splash/ripple color
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'START NOW',
                          style: AppTypography.labelLarge.copyWith(
                            color: Colors.white, // Explicitly overriding theme color to white
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Explore Schemes Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: () {
                          // TODO: Add route for exploring schemes
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkBrown,
                          side: const BorderSide(color: darkBrown, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'EXPLORE SCHEMES',
                          style: AppTypography.labelLarge.copyWith(
                            color: darkBrown, // Ensuring this stays brown
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- FOOTER LIST ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    _buildCheckListItem(
                      'Live Mandi prices & local demand trends',
                      accentRed,
                      darkBrown,
                    ),
                    const SizedBox(height: 12),
                    _buildCheckListItem(
                      'Step-by-step business launch guide',
                      accentRed,
                      darkBrown,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckListItem(String text, Color iconColor, Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.check_circle_outline, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: textColor.withValues(alpha: 0.65),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
