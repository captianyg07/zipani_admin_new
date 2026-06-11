import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'current_profile_provider.dart';

/// Exposes the Supabase client.
final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Streams auth state changes so the router can react to sign in / sign out.
/// V1: any authenticated Supabase user is treated as the admin.
/// (Roles will be added in a later version via a profiles table.)
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseProvider).auth.onAuthStateChange;
});

/// Convenience: the current session, or null when signed out.
final sessionProvider = Provider<Session?>((ref) {
  ref.watch(authStateProvider); // rebuild on change
  return ref.watch(supabaseProvider).auth.currentSession;
});

/// Controller for sign in / sign out. UI-level only — no domain logic here.
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._client, this._ref) : super(const AsyncData(null));

  final SupabaseClient _client;
  final Ref _ref;

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
      // Force the profile to be re-resolved for the newly signed-in user.
      _ref.invalidate(currentUserProvider);
      state = const AsyncData(null);
    } on AuthException catch (e) {
      state = AsyncError(e.message, StackTrace.current);
    } catch (_) {
      state = AsyncError(
        'Could not sign in. Check your connection and try again.',
        StackTrace.current,
      );
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    // Drop any cached profile so a stale role cannot linger.
    _ref.invalidate(currentUserProvider);
    state = const AsyncData(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref.watch(supabaseProvider), ref);
});
