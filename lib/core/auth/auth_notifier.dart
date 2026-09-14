import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'auth_state.dart';

/// Manages authentication session lifecycle, token propagation, and auth state changes.
/// Bridges real Supabase sessions when configured, and supports the backend's
/// native development authentication mode (`mock-user-<id>`) when running locally.
class AuthNotifier extends StateNotifier<AuthState> {
  StreamSubscription<sb.AuthState>? _supabaseAuthSubscription;

  AuthNotifier() : super(AuthState.initial()) {
    _initialize();
  }

  void _initialize() {
    state = AuthState.loading();

    // 1. Attempt connection to Supabase Auth if initialized
    try {
      final supabaseClient = sb.Supabase.instance.client;
      final currentSession = supabaseClient.auth.currentSession;

      if (currentSession != null) {
        state = AuthState.authenticated(
          token: currentSession.accessToken,
          userId: currentSession.user.id,
          email: currentSession.user.email,
        );
      } else {
        state = AuthState.unauthenticated();
      }

      // Listen for runtime auth changes (login, logout, token refresh)
      _supabaseAuthSubscription =
          supabaseClient.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null) {
          state = AuthState.authenticated(
            token: session.accessToken,
            userId: session.user.id,
            email: session.user.email,
          );
        } else {
          state = AuthState.unauthenticated();
        }
      });
      return;
    } catch (_) {
      // Supabase is not initialized or unreachable in this environment.
    }

    // 2. Local development fallback
    // Uses the backend's intentionally supported development auth format:
    // "mock-user-<id>" verified in backend/app/core/security.py (L31-L40)
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

  /// Sets an explicit token and user session (e.g. for testing or custom auth providers).
  void setToken(String token, {required String userId, String? email}) {
    state = AuthState.authenticated(
      token: token,
      userId: userId,
      email: email,
    );
  }

  /// Switches the active development user ID.
  void setDevUser(String userId) {
    state = AuthState.authenticated(
      token: 'mock-user-$userId',
      userId: userId,
      email: '$userId@vyaparmitra.dev',
    );
  }

  /// Logs out the user, signing out from Supabase if available, and clearing state.
  Future<void> signOut() async {
    try {
      await sb.Supabase.instance.client.auth.signOut();
    } catch (_) {}
    state = AuthState.unauthenticated();
  }

  @override
  void dispose() {
    _supabaseAuthSubscription?.cancel();
    super.dispose();
  }
}
