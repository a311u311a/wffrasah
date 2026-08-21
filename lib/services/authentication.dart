import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

bool get _usesNativeAppleSignIn {
  return !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}

Future<AuthResponse> _signInWithNativeApple(SupabaseClient supabase) async {
  final rawNonce = supabase.auth.generateRawNonce();
  final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

  final credential = await SignInWithApple.getAppleIDCredential(
    scopes: [
      AppleIDAuthorizationScopes.email,
      AppleIDAuthorizationScopes.fullName,
    ],
    nonce: hashedNonce,
  );

  final idToken = credential.identityToken;
  if (idToken == null) {
    throw const AuthException('Apple did not return an identity token.');
  }

  final response = await supabase.auth.signInWithIdToken(
    provider: OAuthProvider.apple,
    idToken: idToken,
    nonce: rawNonce,
  );

  final fullName = [
    credential.givenName,
    credential.familyName,
  ].where((part) => part != null && part.trim().isNotEmpty).join(' ').trim();

  if (fullName.isNotEmpty && response.user != null) {
    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'name': fullName,
            'full_name': fullName,
          },
        ),
      );

      await supabase.from('users').upsert({
        'id': response.user!.id,
        'uid': response.user!.id,
        'email': response.user!.email,
        'name': fullName,
      }, onConflict: 'id');
    } catch (e) {
      debugPrint('Apple profile name update failed (ignored): $e');
    }
  }

  return response;
}

class AuthMethod {
  AuthMethod(this._supabase);
  final SupabaseClient _supabase;

  static const String mobileRedirectUrl = 'com.rbhan.app://login-callback/';

  String get _webRedirectUrl => Uri.base
      .replace(
        path: '/signin',
        queryParameters: null,
        fragment: null,
      )
      .toString();

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
      // على الويب: يجب تحديد رابط العودة لضمان العمل بشكل صحيح
      // نستخدم Uri.base.origin للعودة إلى الصفحة الرئيسية
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirectUrl,
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

  Future<void> signInWithApple() async {
    if (_usesNativeAppleSignIn) {
      await _signInWithNativeApple(_supabase);
      return;
    }

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? _webRedirectUrl : mobileRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
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

  String get _webRedirectUrl => Uri.base
      .replace(
        path: '/signin',
        queryParameters: null,
        fragment: null,
      )
      .toString();

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
      // على الويب: يجب تحديد رابط العودة لضمان العمل بشكل صحيح
      // نستخدم Uri.base.origin للعودة إلى الصفحة الرئيسية
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _webRedirectUrl,
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

  Future<void> signInWithApple() async {
    if (_usesNativeAppleSignIn) {
      await _signInWithNativeApple(_supabase);
      return;
    }

    await _supabase.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? _webRedirectUrl : _mobileRedirectUrl,
      authScreenLaunchMode:
          kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
    );
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
