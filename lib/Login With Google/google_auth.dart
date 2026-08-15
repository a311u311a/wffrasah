import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  final SupabaseClient _sb = Supabase.instance.client;

  static const String _mobileRedirectUrl = 'com.rbhan.app://login-callback';

  String get _webRedirectUrl => Uri.base
      .replace(
        path: '/signin',
        queryParameters: null,
        fragment: null,
      )
      .toString();

  /// Starts Google OAuth flow.
  /// NOTE: you must configure deep links / redirect URL for Android.
  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await _sb.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirectUrl,
      );
      return;
    }

    await _sb.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: _mobileRedirectUrl,
    );
  }

  Future<void> signOut() async {
    await _sb.auth.signOut();
  }
}
