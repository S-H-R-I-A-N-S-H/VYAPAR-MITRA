import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/network/api_endpoints.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/features/profile/screens/business_profile_screen.dart';

void main() {
  group('Phase 2: Profile Contract Alignment & Persistence Tests', () {
    test('1. BusinessProfileNotifier updates profileId correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(businessProfileProvider).profileId, isNull);

      container
          .read(businessProfileProvider.notifier)
          .setProfileId('ent-server-uuid-001');

      expect(
        container.read(businessProfileProvider).profileId,
        equals('ent-server-uuid-001'),
      );
    });

    testWidgets(
        '2. Submitting profile sends payload exactly matching EntrepreneurProfileCreate contract',
        (WidgetTester tester) async {
      Map<String, dynamic>? capturedPayload;
      String? capturedUrl;
      String? capturedAuth;

      final mockHttp = MockClient((request) async {
        capturedUrl = request.url.toString();
        capturedAuth = request.headers['Authorization'];
        capturedPayload = jsonDecode(request.body) as Map<String, dynamic>;

        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'ent-profile-uuid-8888',
              'user_id': 'mock-user-dev-001',
              'full_name': capturedPayload!['full_name'],
              'preferred_language': capturedPayload!['preferred_language'],
              'voice_enabled': capturedPayload!['voice_enabled'],
              'location_id': 'loc-uuid-1111',
              'available_capital': capturedPayload!['available_capital'],
              'skills': capturedPayload!['skills'],
              'interests': capturedPayload!['interests'],
              'risk_preference': capturedPayload!['risk_preference'],
              'scheme_category': capturedPayload!['scheme_category'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            'message': 'Profile created successfully.',
          }),
          201,
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(
              httpClient: mockHttp,
              authToken: 'mock-user-dev-001',
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            routes: {
              '/': (context) => const BusinessProfileScreen(),
              '/home': (context) =>
                  const Scaffold(body: Text('Home Screen')),
              '/interview': (context) =>
                  const Scaffold(body: Text('Interview Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify form is rendered
      expect(find.text('Continue to AI Interview'), findsOneWidget);

      // Tap submit button
      await tester.ensureVisible(find.text('Continue to AI Interview'));
      await tester.tap(find.text('Continue to AI Interview'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify request destination and headers
      expect(capturedUrl, equals(ApiEndpoints.profile));
      expect(capturedAuth, equals('Bearer mock-user-dev-001'));
      expect(capturedPayload, isNotNull);

      // Verify contract fields match backend EntrepreneurProfileCreate
      expect(capturedPayload!['full_name'], equals('Ramesh Kumar'));
      expect(capturedPayload!['preferred_language'], equals('en'));
      expect(capturedPayload!['voice_enabled'], isTrue);
      expect(capturedPayload!['available_capital'], equals(60000.0));
      expect(capturedPayload!['skills'], equals(['machinery']));
      expect(capturedPayload!['interests'], isEmpty);
      expect(capturedPayload!['risk_preference'], equals('moderate'));
      expect(capturedPayload!['scheme_category'], equals('general'));
      expect(capturedPayload!['consent_recorded'], isTrue);

      // Verify nested LocationCreate
      expect(capturedPayload!['location'], isA<Map<String, dynamic>>());
      final location = capturedPayload!['location'] as Map<String, dynamic>;
      expect(location['state'], equals('Madhya Pradesh'));
      expect(location['district'], equals('Indore'));
      expect(location['town_or_village'], equals('Sanwer'));

      // Verify legacy dropped fields are NOT present
      expect(capturedPayload!.containsKey('phone_number'), isFalse);
      expect(capturedPayload!.containsKey('education_level'), isFalse);
      expect(capturedPayload!.containsKey('primary_skill'), isFalse);
      expect(capturedPayload!.containsKey('primary_language'), isFalse);

      // Verify server-returned entrepreneur profile ID is persisted in Riverpod
      expect(
        container.read(businessProfileProvider).profileId,
        equals('ent-profile-uuid-8888'),
      );

      // Verify navigation succeeded to /home
      expect(find.text('Home Screen'), findsOneWidget);
    });

    testWidgets(
        '3. Backend failure displays error SnackBar and does NOT navigate',
        (WidgetTester tester) async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': 'Database connection failed',
          }),
          500,
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(httpClient: mockHttp),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            routes: {
              '/': (context) => const BusinessProfileScreen(),
              '/interview': (context) =>
                  const Scaffold(body: Text('Interview Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue to AI Interview'));
      await tester.tap(find.text('Continue to AI Interview'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify error SnackBar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Failed to save profile:'),
        findsOneWidget,
      );

      // Verify screen did NOT navigate to /interview
      expect(find.text('Interview Screen'), findsNothing);
      expect(find.text('Continue to AI Interview'), findsOneWidget);

      // Profile ID should still be null
      expect(container.read(businessProfileProvider).profileId, isNull);
    });
  });
}
