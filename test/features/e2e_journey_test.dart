import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/app/router.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/core/theme/app_theme.dart';

void main() {
  group('Vyapar Mitra Complete E2E User Journey', () {
    testWidgets('Traverses full 10-screen flow from Welcome to Action Plan',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockHttp = MockClient((request) async {
        if (request.url.path.endsWith('/businesses')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'id': 'biz-e2e-created-001',
                'entrepreneur_id': 'ent-e2e-profile-001',
                'name': 'Cold-Press Mustard Oil Mill',
                'status': 'IDEA',
                'domain': 'Agri-Processing & Food Products',
                'product_or_service': 'Cold-Press Mustard Oil Mill',
                'scale': 'micro',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              'message': 'Business idea created successfully.',
            }),
            201,
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'ent-e2e-profile-001',
              'user_id': 'mock-user-dev-001',
              'full_name': 'Ramesh Kumar',
              'preferred_language': 'hi',
              'voice_enabled': true,
              'available_capital': 60000.0,
              'skills': ['machinery'],
              'interests': [],
              'risk_preference': 'moderate',
              'scheme_category': 'general',
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            'message': 'Profile created successfully.',
          }),
          201,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                httpClient: mockHttp,
                authToken: 'mock-user-dev-001',
              ),
            ),
          ],
          child: MaterialApp(
            title: 'Vyapar Mitra',
            theme: AppTheme.lightTheme,
            initialRoute: AppRouter.welcome,
            onGenerateRoute: AppRouter.generateRoute,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // ==========================================
      // --- 1. Welcome Screen ---
      // ==========================================
      expect(find.text('VYAPAR MITRA'), findsWidgets);
      expect(find.text('Turn Your Business Idea Into Reality'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);

      await tester.ensureVisible(find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 2. Language Selection Screen ---
      // ==========================================
      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 3. Business Profile Screen ---
      // ==========================================
      expect(find.text('BUSINESS SITUATION'), findsOneWidget);
      expect(find.text('I have a specific idea'), findsOneWidget);
      expect(find.text('Continue to AI Interview'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue to AI Interview'));
      await tester.tap(find.text('Continue to AI Interview'));
      // Handle async backend save call with fallback
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 4. Main App Home Dashboard with Persistent Navigation ---
      // ==========================================
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Analyzer'), findsOneWidget);
      expect(find.text('Finance'), findsWidgets);
      expect(find.text('Learn'), findsWidgets);
      expect(find.text('AI Interview & Opportunity Discovery'), findsOneWidget);
      expect(find.text('Continue Discovery →'), findsOneWidget);

      await tester.ensureVisible(find.text('Continue Discovery →'));
      await tester.tap(find.text('Continue Discovery →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 5. Conversational Interview Screen ---
      // ==========================================
      expect(find.text('Business Advisor AI'), findsOneWidget);
      expect(find.text('Direct farm access'), findsOneWidget);

      // Tap quick reply chip to trigger advisor response
      await tester.tap(find.text('Direct farm access'));
      await tester.pump();
      // Pump past advisor deliberation delay (900ms)
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Discover Opportunities →'), findsOneWidget);
      await tester.ensureVisible(find.text('Discover Opportunities →'));
      await tester.tap(find.text('Discover Opportunities →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 5. Curated Opportunities Screen ---
      // ==========================================
      expect(find.text('Curated Business Opportunities'), findsOneWidget);
      expect(find.text('Confirm Selected Business →'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirm Selected Business →'));
      await tester.tap(find.text('Confirm Selected Business →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 6. Business Confirmation Checkpoint ---
      // ==========================================
      expect(find.text('Confirm Your Business Idea'), findsOneWidget);
      expect(find.text('Confirm & Begin Market Research →'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirm & Begin Market Research →'));
      await tester.tap(find.text('Confirm & Begin Market Research →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 7. Research Step Progress Screen ---
      // ==========================================
      expect(find.text('LIVE MARKET FINDING'), findsOneWidget);
      expect(find.text('View Validation Dashboard →'), findsOneWidget);

      await tester.ensureVisible(find.text('View Validation Dashboard →'));
      await tester.tap(find.text('View Validation Dashboard →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 8. Validation Dashboard Screen ---
      // ==========================================
      expect(find.text('Validation Dashboard'), findsOneWidget);
      expect(find.text('6 Validation Pillars'), findsOneWidget);
      expect(find.text('Simulate Financials & What-If →'), findsOneWidget);

      await tester.ensureVisible(find.text('Simulate Financials & What-If →'));
      await tester.tap(find.text('Simulate Financials & What-If →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 9. Financial Scenario Screen ---
      // ==========================================
      expect(find.text('Financial Planning'), findsOneWidget);
      expect(find.text('NET CASH IN HAND'), findsOneWidget);
      expect(find.text('View Final Action Plan & Milestones →'), findsOneWidget);

      await tester.ensureVisible(find.text('View Final Action Plan & Milestones →'));
      await tester.tap(find.text('View Final Action Plan & Milestones →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // ==========================================
      // --- 10. Action Plan Screen ---
      // ==========================================
      expect(find.text('Validated Strategy • Green Light'), findsOneWidget);
      expect(find.text('Start with a 100 kg/day Mini-Pilot'), findsOneWidget);
      expect(find.text('4-Week Milestone Checklist'), findsOneWidget);
      expect(find.text('Back to Home'), findsOneWidget);

      // Return home
      await tester.ensureVisible(find.text('Back to Home'));
      await tester.tap(find.text('Back to Home'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Back to Welcome Screen
      expect(find.text('Turn Your Business Idea Into Reality'), findsOneWidget);
    });
  });
}
