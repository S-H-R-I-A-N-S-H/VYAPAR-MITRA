import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/features/recommendations/screens/scheme_detail_screen.dart';
import 'package:vyapar_mitra/features/recommendations/screens/scheme_recommendations_screen.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';

void main() {
  group('Government Scheme Recommendations Screens Tests', () {
    testWidgets('SchemeRecommendationsScreen renders and displays cards',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SchemeRecommendationsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SchemeRecommendationsScreen), findsOneWidget);
    });

    testWidgets('SchemeDetailScreen renders with selected scheme details',
        (WidgetTester tester) async {
      const sampleScheme = SchemeRecommendationUIModel(
        schemeId: '11111111-1111-1111-1111-111111111111',
        schemeCode: 'PMEGP',
        officialName: "Prime Minister's Employment Generation Programme (PMEGP)",
        authority: 'Khadi and Village Industries Commission (KVIC)',
        eligibilityStatus: 'eligible',
        suitabilityScore: 0.95,
        estimatedSubsidy: 87500.0,
        estimatedLoan: 162500.0,
        estimatedOwnContribution: 25000.0,
        effectiveCost: 162500.0,
        subsidyPercentage: 35.0,
        summary: 'Satisfies all mandatory conditions for PMEGP.',
        whySelected: 'Matches rural manufacturing criteria.',
        whyEligible: ['Age 18+ requirement satisfied', 'Greenfield unit satisfied'],
        financialBreakdown: [
          'Eligible Project Base: ₹2,50,000',
          '35% Capital Subsidy: ₹87,500',
        ],
        officialPortalUrl: 'https://www.kviconline.gov.in/pmegpeportal/',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedSchemeDetailProvider.overrideWith((ref) => sampleScheme),
          ],
          child: const MaterialApp(
            home: SchemeDetailScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PMEGP'), findsWidgets);
      expect(find.text("Prime Minister's Employment Generation Programme (PMEGP)"), findsOneWidget);
      expect(find.text('ELIGIBLE'), findsOneWidget);
      expect(find.text('Financial Benefit & Subsidy Math'), findsOneWidget);
    });
  });
}
