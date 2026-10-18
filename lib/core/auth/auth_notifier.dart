import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'auth_state.dart';

/// Manages authentication session lifecycle, secure token storage, and auth state changes.
/// Supports Supabase Phone OTP, Email/Password, and local development fallback.
class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  StreamSubscription<sb.AuthState>? _supabaseAuthSubscription;

  static const String _keyToken = 'vm_supabase_token';
  static const String _keyUserId = 'vm_supabase_user_id';
  static const String _keyEmail = 'vm_supabase_email';
  static const String _keyPhone = 'vm_supabase_phone';

  AuthNotifier({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        super(AuthState.initial()) {
    _initializeSync();
    _restoreCachedSession();
  }

  void _initializeSync() {
    // 1. Check synchronous Supabase currentSession if initialized and NOT expired
    try {
      final supabaseClient = sb.Supabase.instance.client;
      final currentSession = supabaseClient.auth.currentSession;
      if (currentSession != null && !currentSession.isExpired) {
        state = AuthState.authenticated(
          token: currentSession.accessToken,
          userId: currentSession.user.id,
          email: currentSession.user.email,
          phone: currentSession.user.phone,
        );
        return;
      }
    } catch (_) {
      // Supabase not initialized or unreachable
    }

    // 2. Synchronous local development fallback (mock-user-<id>)
    const disableDevAuth =
        bool.fromEnvironment('DISABLE_DEV_AUTH', defaultValue: false);
    const devUserId =
        String.fromEnvironment('DEV_USER_ID', defaultValue: 'dev-001');

    if (!disableDevAuth) {
      state = AuthState.authenticated(
        token: 'mock-user-$devUserId',
        userId: devUserId,
        email: '$devUserId@vyaparmitra.dev',
      );
    } else {
      state = AuthState.unauthenticated();
    }
  }

  Future<void> _restoreCachedSession() async {
    // Only restore cached token if Supabase currently has an active, unexpired session.
    // If there is no live unexpired Supabase session, any cached JWT is stale and must be cleared
    // so that the dev-mock fallback token is used instead (avoids 401 on profile creation).
    try {
      final supabaseClient = sb.Supabase.instance.client;
      final currentSession = supabaseClient.auth.currentSession;
      if (currentSession != null && !currentSession.isExpired) {
        // Valid live session — persist and use it
        await _saveSessionToStorage(
          token: currentSession.accessToken,
          userId: currentSession.user.id,
          email: currentSession.user.email,
          phone: currentSession.user.phone,
        );
        state = AuthState.authenticated(
          token: currentSession.accessToken,
          userId: currentSession.user.id,
          email: currentSession.user.email,
          phone: currentSession.user.phone,
        );
        return;
      } else {
        // Live Supabase is initialized but session is expired/null — clear stale cache
        await _clearSessionFromStorage();
      }
    } catch (_) {
      // Supabase is uninitialized (e.g. test environment / offline): restore from secure storage
      try {
        final cachedToken = await _secureStorage.read(key: _keyToken);
        final cachedUserId = await _secureStorage.read(key: _keyUserId);
        final cachedEmail = await _secureStorage.read(key: _keyEmail);
        final cachedPhone = await _secureStorage.read(key: _keyPhone);
        if (cachedToken != null && cachedToken.isNotEmpty && cachedUserId != null) {
          state = AuthState.authenticated(
            token: cachedToken,
            userId: cachedUserId,
            email: cachedEmail,
            phone: cachedPhone,
          );
          return;
        }
      } catch (_) {}
    }


    // Listen for runtime auth changes (login, logout, token refresh)
    try {
      final supabaseClient = sb.Supabase.instance.client;
      _supabaseAuthSubscription =
          supabaseClient.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        if (session != null && !session.isExpired) {
          await _saveSessionToStorage(
            token: session.accessToken,
            userId: session.user.id,
            email: session.user.email,
            phone: session.user.phone,
          );
          state = AuthState.authenticated(
            token: session.accessToken,
            userId: session.user.id,
            email: session.user.email,
            phone: session.user.phone,
          );
        } else {
          await _clearSessionFromStorage();
          const disableDevAuth =
              bool.fromEnvironment('DISABLE_DEV_AUTH', defaultValue: false);
          const devUserId =
              String.fromEnvironment('DEV_USER_ID', defaultValue: 'dev-001');

          if (!disableDevAuth) {
            state = AuthState.authenticated(
              token: 'mock-user-$devUserId',
              userId: devUserId,
              email: '$devUserId@vyaparmitra.dev',
            );
          } else {
            state = AuthState.unauthenticated();
          }
        }
      });
    } catch (_) {}
  }

  Future<void> _saveSessionToStorage({
    required String token,
    required String userId,
    String? email,
    String? phone,
  }) async {
    try {
      await _secureStorage.write(key: _keyToken, value: token);
      await _secureStorage.write(key: _keyUserId, value: userId);
      if (email != null) await _secureStorage.write(key: _keyEmail, value: email);
      if (phone != null) await _secureStorage.write(key: _keyPhone, value: phone);
    } catch (_) {}
  }

  Future<void> _clearSessionFromStorage() async {
    try {
      await _secureStorage.delete(key: _keyToken);
      await _secureStorage.delete(key: _keyUserId);
      await _secureStorage.delete(key: _keyEmail);
      await _secureStorage.delete(key: _keyPhone);
    } catch (_) {}
  }

  /// Sends an SMS OTP to the provided phone number. Formats standard 10-digit numbers to +91.
  Future<void> signInWithPhone(String rawPhone) async {
    final cleaned = rawPhone.replaceAll(RegExp(r'\s+|-'), '');
    final formatted = cleaned.startsWith('+91')
        ? cleaned
        : cleaned.length == 10
            ? '+91$cleaned'
            : cleaned;

    state = AuthState.loading();
    try {
      final supabaseClient = sb.Supabase.instance.client;
      await supabaseClient.auth.signInWithOtp(phone: formatted);
      // Wait for OTP input from user
      state = AuthState.unauthenticated();
    } on sb.AuthException catch (e) {
      state = AuthState.error(e.message);
      rethrow;
    } catch (e) {
      state = AuthState.error('Failed to send OTP: $e');
      rethrow;
    }
  }

  /// Verifies the OTP code sent to the given phone number.
  Future<void> verifyPhoneOtp(String rawPhone, String otp) async {
    final cleaned = rawPhone.replaceAll(RegExp(r'\s+|-'), '');
    final formatted = cleaned.startsWith('+91')
        ? cleaned
        : cleaned.length == 10
            ? '+91$cleaned'
            : cleaned;

    state = AuthState.loading();
    try {
      final supabaseClient = sb.Supabase.instance.client;
      final res = await supabaseClient.auth.verifyOTP(
        phone: formatted,
        token: otp.trim(),
        type: sb.OtpType.sms,
      );

      final session = res.session;
      if (session != null) {
        await _saveSessionToStorage(
          token: session.accessToken,
          userId: session.user.id,
          email: session.user.email,
          phone: session.user.phone,
        );
        state = AuthState.authenticated(
          token: session.accessToken,
          userId: session.user.id,
          email: session.user.email,
          phone: session.user.phone,
        );
      } else {
        state = AuthState.error('OTP verification failed to create session.');
      }
    } on sb.AuthException catch (e) {
      state = AuthState.error(e.message);
      rethrow;
    } catch (e) {
      state = AuthState.error('OTP verification error: $e');
      rethrow;
    }
  }

  /// Signs in using Email and Password.
  Future<void> signInWithEmail(String email, String password) async {
    state = AuthState.loading();
    try {
      final supabaseClient = sb.Supabase.instance.client;
      final res = await supabaseClient.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final session = res.session;
      if (session != null) {
        await _saveSessionToStorage(
          token: session.accessToken,
          userId: session.user.id,
          email: session.user.email,
          phone: session.user.phone,
        );
        state = AuthState.authenticated(
          token: session.accessToken,
          userId: session.user.id,
          email: session.user.email,
          phone: session.user.phone,
        );
      }
    } on sb.AuthException catch (e) {
      state = AuthState.error(e.message);
      rethrow;
    } catch (e) {
      state = AuthState.error('Login error: $e');
      rethrow;
    }
  }

  /// Registers a new user using Email and Password.
  Future<void> signUpWithEmail(String email, String password) async {
    state = AuthState.loading();
    try {
      final supabaseClient = sb.Supabase.instance.client;
      final res = await supabaseClient.auth.signUp(
        email: email.trim(),
        password: password,
      );
      final session = res.session;
      if (session != null) {
        await _saveSessionToStorage(
          token: session.accessToken,
          userId: session.user.id,
          email: session.user.email,
          phone: session.user.phone,
        );
        state = AuthState.authenticated(
          token: session.accessToken,
          userId: session.user.id,
          email: session.user.email,
          phone: session.user.phone,
        );
      } else {
        state = AuthState.unauthenticated();
      }
    } on sb.AuthException catch (e) {
      state = AuthState.error(e.message);
      rethrow;
    } catch (e) {
      state = AuthState.error('Registration error: $e');
      rethrow;
    }
  }

  /// Sets an explicit token and user session (e.g. for testing or custom auth providers).
  void setToken(String token, {required String userId, String? email, String? phone}) {
    state = AuthState.authenticated(
      token: token,
      userId: userId,
      email: email,
      phone: phone,
    );
  }

  /// Switches the active development user ID (sandbox mode).
  void setDevUser(String userId) {
    state = AuthState.authenticated(
      token: 'mock-user-$userId',
      userId: userId,
      email: '$userId@vyaparmitra.dev',
    );
  }

  /// Signs in with local development mock token.
  Future<void> signInWithDevMock([String devId = 'dev-001']) async {
    await _saveSessionToStorage(
      token: 'mock-user-$devId',
      userId: devId,
      email: '$devId@vyaparmitra.dev',
    );
    state = AuthState.authenticated(
      token: 'mock-user-$devId',
      userId: devId,
      email: '$devId@vyaparmitra.dev',
    );
  }

  /// Logs out the user, signing out from Supabase, clearing secure storage, and resetting state.
  Future<void> signOut() async {
    try {
      await sb.Supabase.instance.client.auth.signOut();
    } catch (_) {}
    await _clearSessionFromStorage();
    state = AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }
}

