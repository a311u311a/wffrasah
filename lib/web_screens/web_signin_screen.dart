import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../constants.dart';
import '../services/authentication.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/web_i18n.dart';

/// صفحة تسجيل الدخول للويب
class WebSignInScreen extends StatefulWidget {
  const WebSignInScreen({super.key});

  @override
  State<WebSignInScreen> createState() => _WebSignInScreenState();
}

class _WebSignInScreenState extends State<WebSignInScreen> {
  static const Color bg = Color(0xFFFAFAFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFF2F0FF);
  static const Color stroke = Color(0xFFE2DEFF);
  static const Color ink = Color(0xFF25213B);
  static const Color orange = Color(0xFF6C63FF);
  static const Color pink = Color(0xFF8B84FF);
  static const Color yellow = Color(0xFFFF6584);
  static const Color secondary = Color(0xFF68627F);

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
      await _handleSignedInSession(session);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleSignedInSession(_supabase.auth.currentSession);
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

  Future<void> _handleSignedInSession(Session? session) async {
    if (session == null || _navigated) {
      return;
    }

    _navigated = true;
    await _navigateToHome();
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
      showSnackBar(context,
          webText(context, 'فشل تسجيل الدخول: $e', 'Sign in failed: $e'),
          isError: true);
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
    final theme = Theme.of(context);
    final isArabic =
        Provider.of<LocaleProvider>(context).locale.languageCode == 'ar';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Theme(
        data: theme.copyWith(
          scaffoldBackgroundColor: bg,
          textTheme: GoogleFonts.cairoTextTheme(theme.textTheme),
        ),
        child: Scaffold(
          backgroundColor: bg,
          appBar: const WebNavigationBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1440),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                      child: _buildContent(),
                    ),
                  ),
                ),
                const WebFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final t = AppLocalizations.of(context);
    final isDesktop = ResponsiveLayout.isDesktop(context);
    final welcomePanel = _buildWelcomePanel(
      badge: webText(context, 'عودتك تهمنا', 'Good to see you again'),
      title: webText(context, 'سجل دخولك وتابع كوبوناتك',
          'Sign in and keep your coupons close'),
      subtitle: webText(
          context,
          'ادخل إلى حسابك لحفظ المفضلة واستخدام الكوبونات والعروض بسرعة من كل أجهزتك.',
          'Access your account to save favorites and use coupons and offers quickly from all your devices.'),
    );
    final formCard = _buildFormCard(t);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isDesktop ? 28 : 18),
      decoration: BoxDecoration(
        color: panelDark,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: stroke),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(flex: 5, child: welcomePanel),
                    const SizedBox(width: 28),
                    Expanded(flex: 4, child: formCard),
                  ],
                )
              : Column(
                  children: [
                    welcomePanel,
                    const SizedBox(height: 24),
                    formCard,
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildWelcomePanel({
    required String badge,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: panel,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: stroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0EEFF),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0xFFD8D4FF)),
            ),
            child: Text(
              badge,
              style: GoogleFonts.cairo(
                color: ink,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 22),
          ShaderMask(
            shaderCallback: (bounds) =>
                const LinearGradient(colors: [orange, yellow, pink])
                    .createShader(bounds),
            child: Text(
              title,
              style: GoogleFonts.cairo(
                color: Colors.white,
                fontSize: ResponsiveLayout.isDesktop(context) ? 34 : 28,
                height: 1.25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: GoogleFonts.cairo(
              color: secondary,
              fontSize: 16,
              height: 1.9,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(AppLocalizations? t) {
    return Card(
      elevation: 0,
      color: panel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // العنوان
            Text(
              t?.translate('sign_in') ?? 'Sign In',
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
                    SnackBar(
                        content: Text(webText(
                            context,
                            'استعادة كلمة المرور قريباً',
                            'Password recovery is coming soon'))),
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
                    : (t?.translate('sign_in_google') ?? 'Sign in with Google'),
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
