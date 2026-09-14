import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/network/api_endpoints.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/features/business/screens/business_confirmation_screen.dart';

void main() {
  group('Phase 3: Business Creation & Real business_id Propagation Tests', () {
    test('1. SelectedBusinessNotifier updates businessId and status correctly', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedBusinessProvider).businessId, isNull);

      container
          .read(selectedBusinessProvider.notifier)
          .setBusinessId('biz-server-uuid-001');

      expect(
        container.read(selectedBusinessProvider).businessId,
        equals('biz-server-uuid-001'),
      );

      container.read(selectedBusinessProvider.notifier).setStatus('VALIDATING');
      expect(
        container.read(selectedBusinessProvider).status,
        equals('VALIDATING'),
      );
    });

    testWidgets(
        '2. Submitting business confirmation sends payload matching BusinessCreate and captures server business_id',
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
              'id': 'biz-server-uuid-7777',
              'entrepreneur_id': 'ent-profile-real-uuid-101',
              'name': capturedPayload!['name'],
              'status': 'IDEA',
              'domain': capturedPayload!['domain'],
              'product_or_service': capturedPayload!['product_or_service'],
              'business_model': capturedPayload!['business_model'],
              'description': capturedPayload!['description'],
              'target_customer': capturedPayload!['target_customer'],
              'intended_market': capturedPayload!['intended_market'],
              'scale': capturedPayload!['scale'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            },
            'message': 'Business idea created successfully.',
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
          businessProfileProvider.overrideWith((ref) {
            final notifier = BusinessProfileNotifier();
            notifier.updateProfile(
              const BusinessProfileState(
                profileId: 'ent-profile-real-uuid-101',
                district: 'Indore',
                block: 'Sanwer',
              ),
            );
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            routes: {
              '/': (context) => const BusinessConfirmationScreen(),
              '/research-progress': (context) =>
                  const Scaffold(body: Text('Research Progress Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Confirm Your Business Idea'), findsOneWidget);
      expect(find.text('Confirm & Begin Market Research →'), findsOneWidget);

      await tester.ensureVisible(find.text('Confirm & Begin Market Research →'));
      await tester.tap(find.text('Confirm & Begin Market Research →'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify endpoint and authorization header
      expect(capturedUrl, equals(ApiEndpoints.businesses));
      expect(capturedAuth, equals('Bearer mock-user-dev-001'));
      expect(capturedPayload, isNotNull);

      // Verify request conforms to backend BusinessCreate schema
      expect(capturedPayload!['name'], equals('Cold-Press Mustard Oil Mill'));
      expect(capturedPayload!['domain'], equals('Agri-Processing & Food Products'));
      expect(capturedPayload!['product_or_service'], equals('Cold-Press Mustard Oil Mill'));
      expect(capturedPayload!['business_model'], equals('Direct retail & local haat distribution'));
      expect(capturedPayload!['scale'], equals('micro'));
      expect(capturedPayload!['target_customer'], contains('Local village households'));
      expect(capturedPayload!['intended_market'], contains('Sanwer Block, Indore'));

      // Verify server-generated business ID is stored in selectedBusinessProvider
      final selectedBiz = container.read(selectedBusinessProvider);
      expect(selectedBiz.businessId, equals('biz-server-uuid-7777'));
      expect(selectedBiz.status, equals('VALIDATING'));

      // Verify navigation occurred
      expect(find.text('Research Progress Screen'), findsOneWidget);
    });

    testWidgets(
        '3. Business creation failure displays error SnackBar and does NOT navigate',
        (WidgetTester tester) async {
      final mockHttp = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'detail': 'Database constraint violation: duplicate business name',
          }),
          400,
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(httpClient: mockHttp),
          ),
          businessProfileProvider.overrideWith((ref) {
            final notifier = BusinessProfileNotifier();
            notifier.updateProfile(
              const BusinessProfileState(
                profileId: 'ent-profile-real-uuid-101',
              ),
            );
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            routes: {
              '/': (context) => const BusinessConfirmationScreen(),
              '/research-progress': (context) =>
                  const Scaffold(body: Text('Research Progress Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm & Begin Market Research →'));
      await tester.tap(find.text('Confirm & Begin Market Research →'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify error SnackBar is displayed
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Failed to create business:'),
        findsOneWidget,
      );

      // Verify did NOT navigate and businessId remains null
      expect(find.text('Research Progress Screen'), findsNothing);
      expect(find.text('Confirm Your Business Idea'), findsOneWidget);
      expect(container.read(selectedBusinessProvider).businessId, isNull);
    });

    testWidgets(
        '4. Profile dependency: missing profileId halts creation with error and does NOT call backend',
        (WidgetTester tester) async {
      bool backendWasCalled = false;

      final mockHttp = MockClient((request) async {
        backendWasCalled = true;
        return http.Response(jsonEncode({'success': true}), 201);
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(httpClient: mockHttp),
          ),
          // Profile without profileId
          businessProfileProvider.overrideWith((ref) {
            final notifier = BusinessProfileNotifier();
            notifier.updateProfile(
              const BusinessProfileState(profileId: null),
            );
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            routes: {
              '/': (context) => const BusinessConfirmationScreen(),
              '/research-progress': (context) =>
                  const Scaffold(body: Text('Research Progress Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm & Begin Market Research →'));
      await tester.tap(find.text('Confirm & Begin Market Research →'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify profile error SnackBar shown
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Entrepreneur profile not found'),
        findsOneWidget,
      );

      // Backend must NOT have been called
      expect(backendWasCalled, isFalse);

      // No navigation
      expect(find.text('Research Progress Screen'), findsNothing);
      expect(container.read(selectedBusinessProvider).businessId, isNull);
    });

    testWidgets(
        '5. Avoid duplicate creation: existing businessId navigates without calling backend again',
        (WidgetTester tester) async {
      bool backendWasCalled = false;

      final mockHttp = MockClient((request) async {
        backendWasCalled = true;
        return http.Response(jsonEncode({'success': true}), 201);
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWith(
            (ref) => ApiClient(httpClient: mockHttp),
          ),
          businessProfileProvider.overrideWith((ref) {
            final notifier = BusinessProfileNotifier();
            notifier.updateProfile(
              const BusinessProfileState(profileId: 'ent-profile-real-uuid-101'),
            );
            return notifier;
          }),
          selectedBusinessProvider.overrideWith((ref) {
            final notifier = SelectedBusinessNotifier();
            notifier.selectBusiness(
              const SelectedBusinessState(
                businessId: 'biz-preexisting-uuid-999',
                title: 'Cold-Press Mustard Oil Mill',
              ),
            );
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            routes: {
              '/': (context) => const BusinessConfirmationScreen(),
              '/research-progress': (context) =>
                  const Scaffold(body: Text('Research Progress Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Confirm & Begin Market Research →'));
      await tester.tap(find.text('Confirm & Begin Market Research →'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Backend should NOT be called
      expect(backendWasCalled, isFalse);

      // Navigation must occur
      expect(find.text('Research Progress Screen'), findsOneWidget);

      // businessId remains the pre-existing ID
      expect(
        container.read(selectedBusinessProvider).businessId,
        equals('biz-preexisting-uuid-999'),
      );
    });
  });
}
