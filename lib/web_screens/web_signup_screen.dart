import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../services/authentication.dart';
import '../screens/login_signup/widgets/snackbar.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';

/// صفحة التسجيل للويب
class WebSignUpScreen extends StatefulWidget {
  const WebSignUpScreen({super.key});

  @override
  State<WebSignUpScreen> createState() => _WebSignUpScreenState();
}

class _WebSignUpScreenState extends State<WebSignUpScreen> {
  static const Color bg = Color(0xFFFAFAFF);
  static const Color panel = Color(0xFFFFFFFF);
  static const Color panelDark = Color(0xFFF2F0FF);
  static const Color stroke = Color(0xFFE2DEFF);
  static const Color ink = Color(0xFF25213B);
  static const Color orange = Color(0xFF6C63FF);
  static const Color pink = Color(0xFF8B84FF);
  static const Color yellow = Color(0xFFFF6584);
  static const Color secondary = Color(0xFF68627F);

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _showPass = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signup() async {
    final t = AppLocalizations.of(context);
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty || confirm.isEmpty) {
      showSnackBar(context,
          t?.translate('fill_all_fields') ?? 'Please fill in all fields',
          isError: true);
      return;
    }
    if (pass != confirm) {
      showSnackBar(context,
          t?.translate('passwords_do_not_match') ?? 'Passwords do not match',
          isError: true);
      return;
    }
    if (pass.length < 6) {
      showSnackBar(
          context,
          t?.translate('registration_error') ??
              'Password must be at least 6 characters',
          isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      final res = await AuthMethods().signUpWithEmail(
        email: email,
        password: pass,
        name: name,
      );

      final user = res.user;
      if (user == null) {
        if (!mounted) return;
        showSnackBar(context, t?.translate('signup_failed') ?? 'Sign up failed',
            isError: true);
        return;
      }

      // حفظ بروفايل في users
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('users').upsert({
          'id': user.id,
          'email': email,
          'name': name,
        });
      } catch (e) {
        debugPrint('Profile upsert failed but signup succeeded: $e');
      }

      if (!mounted) return;

      showSnackBar(
        context,
        t?.translate('signup_success') ?? 'Account created successfully ✅',
        isError: false,
      );

      //  التوجيه للصفحة الرئيسية
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      String msg = e.message;
      if (msg.contains('User already registered') ||
          msg.contains('already registered')) {
        msg = t?.translate('email_already_exists') ?? 'Email already exists';
      }
      showSnackBar(context, msg, isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, '${t?.translate('error_prefix') ?? 'Error: '}$e',
          isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
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
      badge: 'ابدأ التوفير اليوم',
      title: 'أنشئ حسابك واحفظ أفضل العروض',
      subtitle:
          'سجل الآن لتجميع كوبوناتك وعروضك المفضلة والوصول إليها بسرعة من أي مكان.',
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
              t?.translate('sign_up') ?? 'Sign Up',
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
              t?.translate('Sign up now..') ?? 'Join us now!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // الاسم
            _field(
              controller: _nameCtrl,
              label: t?.translate('name') ?? 'Name',
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 20),

            // البريد الإلكتروني
            _field(
              controller: _emailCtrl,
              label: t?.translate('email') ?? 'Email',
              icon: Icons.email_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // كلمة المرور
            _field(
              controller: _passCtrl,
              label: t?.translate('password') ?? 'Password',
              icon: Icons.lock_rounded,
              obscure: !_showPass,
              suffix: IconButton(
                icon: Icon(_showPass
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _showPass = !_showPass),
              ),
            ),
            const SizedBox(height: 20),

            // تأكيد كلمة المرور
            _field(
              controller: _confirmCtrl,
              label: t?.translate('confirm_password') ?? 'Confirm Password',
              icon: Icons.lock_rounded,
              obscure: !_showConfirm,
              suffix: IconButton(
                icon: Icon(_showConfirm
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded),
                onPressed: () => setState(() => _showConfirm = !_showConfirm),
              ),
            ),
            const SizedBox(height: 30),

            // زر التسجيل
            _loading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _signup,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      t?.translate('register') ?? 'Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal',
                      ),
                    ),
                  ),

            const SizedBox(height: 30),

            // رابط تسجيل الدخول
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  t?.translate('already_have_account') ??
                      'Already have an account? ',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontFamily: 'Tajawal',
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/signin'),
                  child: Text(
                    t?.translate('login_here') ?? 'Login here',
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontFamily: 'Tajawal'),
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        suffixIcon: suffix,
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
