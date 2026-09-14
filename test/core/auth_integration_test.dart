import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:vyapar_mitra/core/auth/auth_notifier.dart';
import 'package:vyapar_mitra/core/auth/auth_state.dart';
import 'package:vyapar_mitra/core/network/api_client.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';

void main() {
  group('Phase 1: Frontend Authentication & Token Propagation Tests', () {
    test('1. Unauthenticated session produces no token in ApiClient', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.state = AuthState.unauthenticated();
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final auth = container.read(authProvider);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.token, isNull);

      final client = container.read(apiClientProvider);
      expect(client.authToken, isNull);
    });

    test('2. Authenticated session propagates access token to ApiClient', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) {
            final notifier = AuthNotifier();
            notifier.setToken(
              'test-supabase-jwt-abc123xyz',
              userId: 'user-patil-456',
              email: 'ramesh@vyapar.in',
            );
            return notifier;
          }),
        ],
      );
      addTearDown(container.dispose);

      final auth = container.read(authProvider);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.token, equals('test-supabase-jwt-abc123xyz'));
      expect(auth.userId, equals('user-patil-456'));

      final client = container.read(apiClientProvider);
      expect(client.authToken, equals('test-supabase-jwt-abc123xyz'));
    });

    test('3. Authenticated request sends "Authorization: Bearer <token>" header',
        () async {
      String? capturedAuthHeader;
      String? capturedContentType;

      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        capturedContentType = request.headers['Content-Type'];
        return http.Response(
          jsonEncode({'success': true, 'data': {'status': 'ok'}}),
          200,
        );
      });

      final client = ApiClient(
        httpClient: mockHttp,
        authToken: 'mock-user-local-123',
      );

      final response = await client.get('http://127.0.0.1:8000/api/v1/health');

      expect(response, isNotNull);
      expect(capturedAuthHeader, equals('Bearer mock-user-local-123'));
      expect(capturedContentType, equals('application/json'));
    });

    test('4. Unauthenticated request omits "Authorization" header entirely',
        () async {
      String? capturedAuthHeader;

      final mockHttp = MockClient((request) async {
        capturedAuthHeader = request.headers['Authorization'];
        return http.Response(
          jsonEncode({'success': true, 'data': {}}),
          200,
        );
      });

      final client = ApiClient(httpClient: mockHttp);
      await client.get('http://127.0.0.1:8000/api/v1/health');

      expect(capturedAuthHeader, isNull);
    });

    test('5. Sign out / logout clears token from ApiClient', () async {
      final notifier = AuthNotifier();
      notifier.setToken(
        'active-session-token',
        userId: 'user-active',
      );

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => notifier),
        ],
      );
      addTearDown(container.dispose);

      // Initial state is authenticated
      expect(container.read(authProvider).isAuthenticated, isTrue);
      expect(container.read(apiClientProvider).authToken,
          equals('active-session-token'));

      // Perform sign out
      await notifier.signOut();

      // State is cleared
      expect(container.read(authProvider).isAuthenticated, isFalse);
      expect(container.read(authProvider).token, isNull);
      expect(container.read(apiClientProvider).authToken, isNull);
    });

    test('6. Auth state change dynamically updates ApiClient token', () {
      final notifier = AuthNotifier();
      notifier.state = AuthState.unauthenticated();

      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => notifier),
        ],
      );
      addTearDown(container.dispose);

      // Initially no token
      expect(container.read(apiClientProvider).authToken, isNull);

      // User logs in with token 1
      notifier.setToken('jwt-token-1', userId: 'user-1');
      expect(container.read(apiClientProvider).authToken, equals('jwt-token-1'));

      // Token refreshes to token 2
      notifier.setToken('jwt-token-2-refreshed', userId: 'user-1');
      expect(container.read(apiClientProvider).authToken,
          equals('jwt-token-2-refreshed'));
    });

    test('7. Default development session initializes with backend-compatible mock token', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final auth = container.read(authProvider);
      // In development mode when Supabase is not initialized,
      // AuthNotifier defaults to the backend-supported dev token format (mock-user-<id>)
      expect(auth.isAuthenticated, isTrue);
      expect(auth.token, startsWith('mock-user-'));
      expect(container.read(apiClientProvider).authToken, startsWith('mock-user-'));
    });
  });
}
