import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';

part 'auth_provider.g.dart';

// ─── Supabase client singleton provider ──────────────────────────────────────
@riverpod
SupabaseClient supabaseClient(SupabaseClientRef ref) {
  return Supabase.instance.client;
}

// ─── Auth state stream ────────────────────────────────────────────────────────
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}

// ─── Current session ──────────────────────────────────────────────────────────
@riverpod
Session? currentSession(CurrentSessionRef ref) {
  return Supabase.instance.client.auth.currentSession;
}

// ─── Current user ID ──────────────────────────────────────────────────────────
@riverpod
String? currentUserId(CurrentUserIdRef ref) {
  return Supabase.instance.client.auth.currentUser?.id;
}

// ─── Auth notifier for login / signup / logout actions ───────────────────────
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AsyncValue<User?> build() {
    final user = Supabase.instance.client.auth.currentUser;
    return AsyncValue.data(user);
  }

  SupabaseClient get _client => Supabase.instance.client;

  // ── Sign in with email + password ──────────────────────────────────────────
  Future<AuthResponse> signInWithPassword(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
      return response;
    } on AuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ── Sign up with email + password ──────────────────────────────────────────
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName ?? ''},
      );
      state = AsyncValue.data(response.user);
      return response;
    } on AuthException catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ── OAuth: Google / Apple ──────────────────────────────────────────────────
  Future<void> signInWithOAuth(OAuthProvider provider) async {
    await _client.auth.signInWithOAuth(
      provider,
      redirectTo: Uri.base.origin,
    );
  }

  // ── Password reset email ───────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email,
      redirectTo: '${Uri.base.origin}/auth/reset-password',
    );
  }

  // ── Sign out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _client.auth.signOut();
    // Clear per-user Hive caches so a subsequent login on the same device
    // (especially a shared browser) can't see the prior user's data.
    // User prefs are intentionally preserved across sessions.
    await _clearUserScopedHiveBoxes();
    state = const AsyncValue.data(null);
  }

  Future<void> _clearUserScopedHiveBoxes() async {
    const boxes = [
      AppConstants.hiveBoxNavCache,
      AppConstants.hiveBoxFundList,
      AppConstants.hiveBoxPortfolioSnapshot,
      AppConstants.hiveBoxPendingTransactions,
    ];
    for (final name in boxes) {
      try {
        if (Hive.isBoxOpen(name)) {
          await Hive.box(name).clear();
        } else {
          final box = await Hive.openBox(name);
          await box.clear();
        }
      } catch (_) {
        // Best effort — never block sign-out on cache cleanup.
      }
    }
  }

  // ── MFA: enroll TOTP ──────────────────────────────────────────────────────
  Future<AuthMFAEnrollResponse> enrollMfa() async {
    return _client.auth.mfa.enroll(factorType: FactorType.totp);
  }

  // ── MFA: verify challenge ─────────────────────────────────────────────────
  Future<AuthMFAVerifyResponse> verifyMfaChallenge({
    required String factorId,
    required String code,
  }) async {
    final challenge = await _client.auth.mfa.challenge(factorId: factorId);
    return _client.auth.mfa.verify(
      factorId: factorId,
      challengeId: challenge.id,
      code: code,
    );
  }

  // ── MFA: list enrolled factors ────────────────────────────────────────────
  Future<AuthMFAListFactorsResponse> listMfaFactors() async {
    return _client.auth.mfa.listFactors();
  }
}
