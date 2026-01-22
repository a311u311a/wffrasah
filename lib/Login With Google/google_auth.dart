import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final SupabaseClient _sb = Supabase.instance.client;

  /// Starts Google OAuth flow.
  /// NOTE: you must configure deep links / redirect URL for Android.
  Future<void> signInWithGoogle() async {
    await _sb.auth.signInWithOAuth(
      OAuthProvider.google,
      // You can remove redirectTo to use default, but better to set it.
      // Make sure it matches your Android intent-filter.
      redirectTo: 'com.example.coupon://login-callback',
    );
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }
}
