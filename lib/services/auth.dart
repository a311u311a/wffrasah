import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:coupon/screens/signup.dart';
import '../Login Signup/Widget/button.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../screens/admin_screen.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../Login Signup/Widget/snackbar.dart';
import '../Password Forgot/forgot_password.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final _supabase = Supabase.instance.client;

  // ✅ لازم يطابق: package + AndroidManifest intent-filter + Supabase Redirect URLs
  // غيّري com.example.coupon لباكيج تطبيقك الحقيقي
  static const String _mobileRedirectUrl =
      'com.example.coupon://login-callback/';

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _isPasswordVisible = false;

  StreamSubscription<AuthState>? _authSub;

  @override
  void initState() {
    super.initState();

    // ✅ لما يرجع من Google OAuth ويصير فيه Session
    _authSub = _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        // ✅ تأكد من ملف المستخدم في public.users (بدون كسر التطبيق لو فشل)
        await _ensurePublicUserRow(session.user);
        await _navigateByRole();
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ✅ يحفظ صف في جدول public.users إن لم يكن موجود (Upsert)
  // مهم: استخدمنا created_at بدل createdAt
  Future<void> _ensurePublicUserRow(User user) async {
    try {
      await _supabase.from('users').upsert({
        'id': user.id,
        'email': user.email,
        'name': (user.userMetadata?['name'] ?? user.userMetadata?['full_name'] ?? '').toString(),
        // لو عندك default now() في DB ممكن تشيلي created_at من هنا
        'created_at': DateTime.now().toIso8601String(),
        'is_admin': false,
      });
    } catch (e) {
      // ✅ لا نعرض خطأ للمستخدم لأن التسجيل نفسه ناجح
      debugPrint('ensurePublicUserRow failed: $e');
    }
  }

  Future<bool> _isAdmin(String userId) async {
    final row = await _supabase
        .from('admins')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();
    return row != null;
  }

  Future<void> _navigateByRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final admin = await _isAdmin(user.id);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => admin ? const AdminScreen() : const BottomNavBar(),
      ),
          (_) => false,
    );
  }

  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showSnackBar(
        context,
        "يرجى إدخال البريد الإلكتروني وكلمة المرور",
        isError: true,
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final res =
      await _supabase.auth.signInWithPassword(email: email, password: pass);

      if (res.user != null) {
        // ✅ تأكد من public.users
        await _ensurePublicUserRow(res.user!);
        await _navigateByRole();
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      showSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'فشل تسجيل الدخول: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() => isLoading = true);
    try {
      // ✅ للويب: خليها null (Supabase يتولى الـ redirect)
      // ✅ للجوال: deep link (عشان نتجنب file:///)
      final String? redirectTo = kIsWeb ? null : _mobileRedirectUrl;

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      // ✅ لا نعمل navigate هنا، لأن Google يرجع عن طريق onAuthStateChange
    } on AuthException catch (e) {
      if (!mounted) return;
      showSnackBar(context, e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'Google Sign-In failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _goBackToMenu() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const BottomNavBar(initialIndex: 4)),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor, size: 30),
          onPressed: _goBackToMenu,
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              SizedBox(
                height: height / 3.3,
                child: Image.asset(
                  t?.locale.languageCode == 'ar'
                      ? 'assets/image/login.png'
                      : 'assets/image/logine.png',
                ),
              ),
              const SizedBox(height: 20),

              _buildTextField(
                emailController,
                t?.translate('email') ?? 'Email',
                Icons.email,
              ),
              const SizedBox(height: 20),

              _buildTextField(
                passwordController,
                t?.translate('password') ?? 'Password',
                Icons.lock,
                isPassword: true,
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen(),
                      ),
                    );
                  },
                  child: Text(
                    t?.translate('forgot_password') ?? 'Forgot password?',
                  ),
                ),
              ),

              const SizedBox(height: 10),

              isLoading
                  ? const CircularProgressIndicator()
                  : MyButtons(
                onTap: loginUser,
                text: t?.translate('sign_in') ?? 'Sign In',
              ),

              const SizedBox(height: 20),

              // Google Sign In
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
                onPressed: isLoading ? null : signInWithGoogle,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/image/google.png', height: 24),
                    const SizedBox(width: 12),
                    Text(
                      t?.translate('sign_in_google') ?? 'Sign in with Google',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    t?.translate('dont_have_account') ??
                        "Don't have an account? ",
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const Signup()),
                    ),
                    child: Text(
                      t?.translate('sign_up') ?? 'Sign Up',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Constants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController ctrl,
      String label,
      IconData icon, {
        bool isPassword = false,
      }) {
    return TextField(
      controller: ctrl,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () =>
              setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
