import 'package:flutter/foundation.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class AuthMethod {
  AuthMethod(this._supabase);
  final SupabaseClient _supabase;

  static const String mobileRedirectUrl = 'com.rbhan.app://login-callback/';

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) {
    return _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // على الويب: استخدام الإعدادات الافتراضية
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } else {
      // على التطبيق: استخدام inAppWebView للبقاء داخل التطبيق
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: mobileRedirectUrl,
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );
    }
  }

  Future<void> signOut() => _supabase.auth.signOut();

  /// ✅ استخدام id و is_admin
  Future<bool> isAdmin(String userId) async {
    try {
      final row = await _supabase
          .from('admins')
          .select('user_id')
          .eq('user_id', userId)
          .maybeSingle();

      return row != null;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
}

class AuthMethods {
  AuthMethods();

  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _mobileRedirectUrl = 'com.rbhan.app://login-callback/';

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    final res = await _supabase.auth.signUp(
      email: email.trim(),
      password: password.trim(),
      data: {'full_name': name.trim()},
    );

    final user = res.user;
    if (user != null) {
      try {
        await _supabase.from('users').upsert({
          'id': user.id,
          'email': user.email,
          'name': name.trim(),
          'is_admin': false,
        });
      } catch (e) {
        debugPrint('Profile upsert failed (ignored): $e');
      }
    }
    return res;
  }

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password.trim(),
    );
    return res;
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      // على الويب: استخدام الإعدادات الافتراضية
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
      );
    } else {
      // على التطبيق: استخدام inAppWebView للبقاء داخل التطبيق
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _mobileRedirectUrl,
        authScreenLaunchMode: LaunchMode.inAppWebView,
      );
    }
  }

  Future<void> signOut() => _supabase.auth.signOut();

  /// ✅ استخدام id و is_admin
  Future<bool> isAdmin(String authUserId) async {
    try {
      final row = await _supabase
          .from('admins')
          .select('user_id')
          .eq('user_id', authUserId)
          .maybeSingle();

      return row != null;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }
}
