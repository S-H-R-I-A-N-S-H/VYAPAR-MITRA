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
  group('Vyapar Mitra Hindi E2E User Journey Test', () {
    testWidgets('Traverses full user flow in Hindi without crashes or missing handlers',
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
                'id': 'biz-e2e-hindi-001',
                'entrepreneur_id': 'ent-e2e-profile-hindi',
                'name': 'कोल्ड-प्रेस सरसों तेल मिल',
                'status': 'IDEA',
                'domain': 'Agri-Processing & Food Products',
                'product_or_service': 'कोल्ड-प्रेस सरसों तेल मिल',
                'scale': 'micro',
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              },
              'message': 'Business idea created successfully.',
            }),
            201,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        }

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'ent-e2e-profile-hindi',
              'user_id': 'mock-user-hindi-001',
              'full_name': 'रमेश कुमार',
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
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            apiClientProvider.overrideWith(
              (ref) => ApiClient(
                httpClient: mockHttp,
                authToken: 'mock-user-hindi-001',
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

      // --- 1. Welcome Screen ---
      expect(find.text('VYAPAR MITRA'), findsWidgets);
      expect(find.text('Get Started'), findsOneWidget);
      await tester.ensureVisible(find.text('Get Started'));
      await tester.tap(find.text('Get Started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 2. Language Selection Screen ---
      expect(find.text('Choose Your Language'), findsOneWidget);
      expect(find.text('हिन्दी'), findsOneWidget);

      // Tap Hindi option
      await tester.tap(find.text('हिन्दी'));
      await tester.pumpAndSettle();

      // In Hindi, button is 'आगे बढ़ें'
      expect(find.text('आगे बढ़ें'), findsOneWidget);
      await tester.ensureVisible(find.text('आगे बढ़ें'));
      await tester.tap(find.text('आगे बढ़ें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 3. Business Profile Screen (in Hindi) ---
      expect(find.text('व्यवसाय प्रोफ़ाइल'), findsOneWidget);
      expect(find.text('मेरे पास निश्चित विचार है'), findsOneWidget);
      expect(find.text('एआई सलाहकार से बात करें'), findsOneWidget);

      await tester.ensureVisible(find.text('एआई सलाहकार से बात करें'));
      await tester.tap(find.text('एआई सलाहकार से बात करें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));

      // --- 4. Main App Home Dashboard with Persistent Navigation (in Hindi) ---
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('होम'), findsWidgets);
      expect(find.text('विश्लेषक'), findsOneWidget);
      expect(find.text('वित्त'), findsOneWidget);
      expect(find.text('ज्ञान'), findsOneWidget);
      expect(find.text('एआई सलाहकार से बात करें व अवसर खोजें'), findsOneWidget);
      expect(find.text('खोज जारी रखें • AI साक्षात्कार →'), findsOneWidget);

      await tester.ensureVisible(find.text('खोज जारी रखें • AI साक्षात्कार →'));
      await tester.tap(find.text('खोज जारी रखें • AI साक्षात्कार →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 5. Conversational Interview Screen (in Hindi) ---
      expect(find.text('बिजनेस एडवाइजर एआई'), findsOneWidget);
      
      // Tap quick reply chip
      expect(find.text('Direct farm access'), findsOneWidget);
      await tester.tap(find.text('Direct farm access'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('अवसर खोजें • View Opportunities'), findsOneWidget);
      await tester.ensureVisible(find.text('अवसर खोजें • View Opportunities'));
      await tester.tap(find.text('अवसर खोजें • View Opportunities'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 5. Curated Opportunities Screen (in Hindi) ---
      expect(find.text('व्यवसाय के श्रेष्ठ अवसर'), findsOneWidget);
      expect(find.text('यह अवसर चुनें और पुष्टि करें'), findsOneWidget);

      await tester.ensureVisible(find.text('यह अवसर चुनें और पुष्टि करें'));
      await tester.tap(find.text('यह अवसर चुनें और पुष्टि करें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 6. Business Confirmation Checkpoint (in Hindi) ---
      expect(find.text('व्यवसाय योजना की पुष्टि करें'), findsOneWidget);
      expect(find.text('पुष्टि करें और बाजार जांच शुरू करें'), findsOneWidget);

      await tester.ensureVisible(find.text('पुष्टि करें और बाजार जांच शुरू करें'));
      await tester.tap(find.text('पुष्टि करें और बाजार जांच शुरू करें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 7. Research Step Progress Screen (in Hindi) ---
      expect(find.text('ताज़ा जमीनी खोज'), findsOneWidget);
      expect(find.text('सत्यापन डैशबोर्ड देखें'), findsOneWidget);

      await tester.ensureVisible(find.text('सत्यापन डैशबोर्ड देखें'));
      await tester.tap(find.text('सत्यापन डैशबोर्ड देखें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 8. Validation Dashboard Screen (in Hindi) ---
      expect(find.text('सत्यापन डैशबोर्ड'), findsOneWidget);
      expect(find.text('सत्यापन के 6 आधार स्तंभ'), findsOneWidget);
      expect(find.text('वित्तीय योजना व लाभ देखें →'), findsOneWidget);

      await tester.ensureVisible(find.text('वित्तीय योजना व लाभ देखें →'));
      await tester.tap(find.text('वित्तीय योजना व लाभ देखें →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 9. Financial Scenario Screen (in Hindi) ---
      expect(find.text('स्थापना पूंजी व बैंक ऋण'), findsOneWidget);
      expect(find.text('हाथ में शुद्ध बचत'), findsOneWidget);
      expect(find.text('अंतिम कार्ययोजना व सिफारिशें देखें →'), findsOneWidget);

      await tester.ensureVisible(find.text('अंतिम कार्ययोजना व सिफारिशें देखें →'));
      await tester.tap(find.text('अंतिम कार्ययोजना व सिफारिशें देखें →'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // --- 10. Action Plan Screen (in Hindi) ---
      expect(find.text('सत्यापित रणनीति • हरी झंडी (GREEN LIGHT)'), findsOneWidget);
      expect(find.text('मुख्य पृष्ठ पर लौटें'), findsOneWidget);

      await tester.ensureVisible(find.text('मुख्य पृष्ठ पर लौटें'));
      await tester.tap(find.text('मुख्य पृष्ठ पर लौटें'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Back to Welcome Screen
      expect(find.text('शुरुआत करें'), findsOneWidget);
    });
  });
}
