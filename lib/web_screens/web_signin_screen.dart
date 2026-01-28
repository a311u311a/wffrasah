import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../constants.dart';
import '../services/authentication.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../localization/app_localizations.dart';

/// صفحة تسجيل الدخول للويب
class WebSignInScreen extends StatefulWidget {
  const WebSignInScreen({super.key});

  @override
  State<WebSignInScreen> createState() => _WebSignInScreenState();
}

class _WebSignInScreenState extends State<WebSignInScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final AuthMethod _auth;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool isGoogleLoading = false;
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
        await _navigateToHome();
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

  Future<void> _ensureUserRow() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

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

  Future<void> _navigateToHome() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      return;
    }

    await _ensureUserRow();

    bool admin = false;
    try {
      final res = await _supabase
          .from('admins')
          .select('user_id')
          .eq('user_id', user.id)
          .maybeSingle();

      admin = res != null;
    } catch (e) {
      debugPrint('isAdmin check failed: $e');
    }

    if (!mounted) {
      return;
    }

    // للويب: نوجه للصفحة المناسبة
    Navigator.pushNamedAndRemoveUntil(
      context,
      admin ? '/admin' : '/',
      (_) => false,
    );
  }

  Future<void> loginUser() async {
    final t = AppLocalizations.of(context);
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      showSnackBar(
        context,
        t?.translate('fill_all_fields') ?? "Please fill in all fields",
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
          await _navigateToHome();
        }
      } else {
        if (!mounted) {
          return;
        }
        showSnackBar(context, t?.translate('login_failed') ?? 'Login failed',
            isError: true);
      }
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      String msg = e.message;
      if (msg.contains('Invalid login credentials')) {
        msg = t?.translate('login_error') ?? 'Invalid email or password';
      }
      showSnackBar(context, msg, isError: true);
    } catch (e) {
      if (!mounted) {
        return;
      }
      showSnackBar(context, 'فشل تسجيل الدخول: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> signInWithGoogle() async {
    final t = AppLocalizations.of(context);
    // على الويب، لا نستخدم isLoading الرئيسي لأنه سيتم إعادة توجيه الصفحة
    // استخدام متغير منفصل لعرض مؤشر التحميل على الزر فقط
    setState(() => isGoogleLoading = true);

    try {
      await _auth.signInWithGoogle();

      // ملاحظة: على الويب، سيتم إعادة التوجيه إلى صفحة Google OAuth
      // وعند العودة، سيتم التعامل مع الجلسة من خلال _authSub في initState
      // لذلك لا نحتاج إلى التنقل هنا
    } on AuthException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isGoogleLoading = false);
      showSnackBar(
        context,
        '${t?.translate('google_signin_failed')}: ${e.message}',
        isError: true,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => isGoogleLoading = false);
      showSnackBar(
        context,
        t?.translate('google_signin_error_generic') ??
            'An error occurred during Google Sign-In',
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildContent(),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final t = AppLocalizations.of(context);
    return Container(
      padding: ResponsivePadding.page(context),
      constraints: const BoxConstraints(maxWidth: 500),
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.isDesktop(context) ? 20 : 0,
        vertical: 40,
      ),
      child: Center(
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // العنوان
                Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Constants.primaryColor,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  t?.translate('welcome') ?? 'Welcome',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // البريد الإلكتروني
                _buildTextField(
                  emailController,
                  t?.translate('email') ?? 'Email',
                  Icons.email_rounded,
                ),
                const SizedBox(height: 20),

                // كلمة المرور
                _buildTextField(
                  passwordController,
                  t?.translate('password') ?? 'Password',
                  Icons.lock_rounded,
                  isPassword: true,
                ),
                const SizedBox(height: 12),

                // نسيت كلمة المرور
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('استعادة كلمة المرور قريباً')),
                      );
                    },
                    child: Text(
                      t?.translate('forgot_password') ?? 'Forgot Password?',
                      style: TextStyle(
                        color: Constants.primaryColor,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // زر تسجيل الدخول
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Constants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          t?.translate('sign_in') ?? 'Sign In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                      ),

                const SizedBox(height: 20),

                //  تسجيل الدخول بـ Google
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  onPressed:
                      (isLoading || isGoogleLoading) ? null : signInWithGoogle,
                  icon: isGoogleLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Image.asset('assets/image/google.png', height: 24),
                  label: Text(
                    isGoogleLoading
                        ? (t?.translate('loading') ?? 'Loading...')
                        : (t?.translate('sign_in_google') ??
                            'Sign in with Google'),
                    style: const TextStyle(
                      fontFamily: 'Tajawal',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // رابط التسجيل
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      t?.translate('dont_have_account') ??
                          "Don't have an account? ",
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontFamily: 'Tajawal',
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/signup'),
                      child: Text(
                        t?.translate('sign_up') ?? 'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Constants.primaryColor,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                ),
                onPressed: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Constants.primaryColor, width: 2),
        ),
      ),
      style: const TextStyle(fontFamily: 'Tajawal'),
    );
  }
}
