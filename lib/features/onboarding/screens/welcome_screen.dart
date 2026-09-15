import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/app_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Define the specific colors used in the design
    const Color darkBrown = Color(0xFF2C1004);
    const Color accentRed = Color(0xFF9E3A21);
    const Color bgColor = Color(0xFFF8F3ED);
    const Color cardShadow = Color(0x1A000000);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Note: To make the background pattern exact, you would typically use a 
            // DecorationImage here with a repeating subtle watermark asset.
            
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- TOP APP BAR ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Profile Icon
                      IconButton(
                        icon: const Icon(Icons.person_outline, size: 28, color: darkBrown),
                        onPressed: () => Navigator.pushNamed(context, '/profile'),
                      ),

                      // Start a Venture Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: darkBrown.withValues(alpha: 0.3), width: 1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'START A\nVENTURE',
                          textAlign: TextAlign.center,
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: 0.5,
                            color: darkBrown,
                          ),
                        ),
                      ),

                      // Language Toggle Pill
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, '/language'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: darkBrown.withValues(alpha: 0.3), width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.translate, size: 16, color: darkBrown),
                              const SizedBox(width: 4),
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

                const SizedBox(height: 30),

                // --- MAIN HEADLINE ---
                Text(
                  'START YOUR LOCAL\nBUSINESS',
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineLarge.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: darkBrown,
                    height: 1.1,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // --- CENTRAL ACTION CARD ---
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: cardShadow,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Card Subtitle
                      Text(
                        'AI BUSINESS COMPANION',
                        style: AppTypography.labelSmall.copyWith(
                          color: accentRed,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Card Headline
                      Text(
                        'PLAN. VALIDATE.\nGET FUNDED.',
                        textAlign: TextAlign.center,
                        style: AppTypography.headlineMedium.copyWith(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: darkBrown,
                          height: 1.2,
                        ),
                      ),
                      
                      const SizedBox(height: 28),

                      // Start Now Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/language'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: darkBrown,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'START NOW',
                            style: AppTypography.labelLarge.copyWith(
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
                        height: 54,
                        child: OutlinedButton(
                          onPressed: () {
                            // Add route for schemes if applicable
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: darkBrown,
                            side: const BorderSide(color: darkBrown, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: Text(
                            'EXPLORE SCHEMES',
                            style: AppTypography.labelLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Text Link
                      Text(
                        'HOW VYAPAR MITRA WORKS',
                        style: AppTypography.labelSmall.copyWith(
                          color: const Color(0xFF8B6B56),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // --- FOOTER FEATURES ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      // Top Row of features
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildFeatureItem(Icons.verified_outlined, 'Govt Mudra & PMEGP'),
                          const SizedBox(width: 16),
                          Text('•', style: TextStyle(color: darkBrown.withValues(alpha: 0.3))),
                          const SizedBox(width: 16),
                          _buildFeatureItem(Icons.bar_chart_rounded, 'Real Mandi Insights'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // List of features
                      _buildCheckListItem('Live Mandi prices & local demand trends'),
                      const SizedBox(height: 8),
                      _buildCheckListItem('Step-by-step business launch guide'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9E3A21)),
        const SizedBox(width: 6),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: const Color(0xFF5A4A42),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckListItem(String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF9E3A21)),
        const SizedBox(width: 8),
        Text(
          text,
          style: AppTypography.bodySmall.copyWith(
            color: const Color(0xFF5A4A42),
          ),
        ),
      ],
    );
  }
}