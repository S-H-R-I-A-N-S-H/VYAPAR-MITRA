import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyapar_mitra/core/auth/auth_notifier.dart';
import 'package:vyapar_mitra/core/providers/app_providers.dart';
import 'package:vyapar_mitra/features/auth/screens/auth_screen.dart';

// In-memory fake secure storage for test isolation
class FakeSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _data[key] = value;
    } else {
      _data.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.clear();
  }
}

void main() {
  group('Task 2: Supabase Real Authorization Flow Unit & Widget Tests', () {
    test('1. AuthNotifier saves session to secure storage upon signInWithDevMock', () async {
      final fakeStorage = FakeSecureStorage();
      final notifier = AuthNotifier(secureStorage: fakeStorage);

      await notifier.signInWithDevMock('test-user-999');

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.userId, equals('test-user-999'));
      expect(notifier.state.token, equals('mock-user-test-user-999'));

      final storedToken = await fakeStorage.read(key: 'vm_supabase_token');
      expect(storedToken, equals('mock-user-test-user-999'));
      final storedUserId = await fakeStorage.read(key: 'vm_supabase_user_id');
      expect(storedUserId, equals('test-user-999'));
    });

    test('2. AuthNotifier restores cached session from secure storage', () async {
      final fakeStorage = FakeSecureStorage();
      await fakeStorage.write(key: 'vm_supabase_token', value: 'cached-jwt-token-456');
      await fakeStorage.write(key: 'vm_supabase_user_id', value: 'cached-user-id');
      await fakeStorage.write(key: 'vm_supabase_phone', value: '+919876543210');

      final notifier = AuthNotifier(secureStorage: fakeStorage);
      // Allow async initialize to run
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.state.isAuthenticated, isTrue);
      expect(notifier.state.token, equals('cached-jwt-token-456'));
      expect(notifier.state.userId, equals('cached-user-id'));
      expect(notifier.state.phone, equals('+919876543210'));
    });

    test('3. AuthNotifier signOut clears secure storage and resets state', () async {
      final fakeStorage = FakeSecureStorage();
      final notifier = AuthNotifier(secureStorage: fakeStorage);
      await notifier.signInWithDevMock('user-logout-test');

      expect(notifier.state.isAuthenticated, isTrue);

      await notifier.signOut();

      expect(notifier.state.isAuthenticated, isFalse);
      expect(notifier.state.token, isNull);

      final tokenAfter = await fakeStorage.read(key: 'vm_supabase_token');
      expect(tokenAfter, isNull);
    });

    testWidgets('4. AuthScreen renders Phone OTP tab, Email tab, and Dev Login',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check header and tabs
      expect(find.text('VYAPAR MITRA'), findsOneWidget);
      expect(find.textContaining('Mobile OTP'), findsOneWidget);
      expect(find.textContaining('Email / Password'), findsOneWidget);

      // Check phone input field
      expect(find.text('+91'), findsOneWidget);
      expect(find.textContaining('Send Verification OTP'), findsOneWidget);

      // Check Dev Sandbox mode card
      expect(find.textContaining('Local Sandbox Mode'), findsOneWidget);
      expect(find.textContaining('Quick Dev Login'), findsOneWidget);
    });

    testWidgets('5. AuthScreen displays error on entering short phone number',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter short number
      final textField = find.byType(TextField).first;
      await tester.enterText(textField, '12345');
      await tester.pump();

      // Tap Send OTP
      final sendOtpBtn = find.textContaining('Send Verification OTP');
      await tester.tap(sendOtpBtn);
      await tester.pumpAndSettle();

      // Error message should appear
      expect(find.textContaining('10 अंकों का मोबाइल नंबर'), findsOneWidget);
    });

    testWidgets('6. AuthScreen Quick Dev Login button authenticates session',
        (tester) async {
      final fakeStorage = FakeSecureStorage();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authProvider.overrideWith((ref) => AuthNotifier(secureStorage: fakeStorage)),
          ],
          child: MaterialApp(
            home: const AuthScreen(),
            routes: {
              '/profile': (_) => const Scaffold(body: Text('Profile Target Screen')),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Scroll to and tap Quick Dev Login
      final devLoginBtn = find.textContaining('Quick Dev Login');
      await tester.ensureVisible(devLoginBtn);
      await tester.pumpAndSettle();
      await tester.tap(devLoginBtn);
      await tester.pumpAndSettle();

      final storedToken = await fakeStorage.read(key: 'vm_supabase_token');
      expect(storedToken, startsWith('mock-user-'));
    });
  });
}
