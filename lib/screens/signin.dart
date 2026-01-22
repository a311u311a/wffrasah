import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../Login Signup/Widget/button.dart';
import '../Login Signup/Widget/snackbar.dart';
import '../Password Forgot/forgot_password.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../screens/admin_screen.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../services/authentication.dart';
import 'signup.dart';

class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final AuthMethod _auth;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool _isPasswordVisible = false;

  StreamSubscription<AuthState>? _authSub;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _auth = AuthMethod(_supabase);

    _authSub = _supabase.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null && !_navigated) {
        _navigated = true;
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

  /// ✅ التأكد من استخدام id بدلاً من uid
  Future<void> _ensureUserRow() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'name':
          (user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? '')
              .toString(),
      'img_url': (user.userMetadata?['avatar_url'] ??
              user.userMetadata?['picture'] ??
              '')
          .toString(),
    };

    try {
      await _supabase.from('users').upsert(
            payload,
            onConflict: 'id',
          );
    } catch (e) {
      debugPrint('ensureUserRow failed (ignored): $e');
    }
  }

  Future<void> _navigateByRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _ensureUserRow();

    bool admin = false;
    try {
      // ✅ التحقق باستخدام id و is_admin
      // Query admins table instead of users to be consistent with other parts of the app
      final res = await _supabase
          .from('admins')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      admin = res != null;
    } catch (e) {
      debugPrint('isAdmin check failed: $e');
    }

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
      final res = await _auth.signIn(email: email, password: pass);

      if (res.user != null) {
        if (!_navigated) {
          _navigated = true;
          await _navigateByRole();
        }
      } else {
        if (!mounted) return;
        showSnackBar(context, 'فشل تسجيل الدخول', isError: true);
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
      await _auth.signInWithGoogle();
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
