import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../services/authentication.dart';
import '../widgets/bottom_navigation_bar.dart';
import '../Login Signup/Widget/button.dart';
import '../Login Signup/Widget/snackbar.dart';
import '../localization/app_localizations.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
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
      showSnackBar(context, 'رجاءً اكملي كل الحقول', isError: true);
      return;
    }
    if (pass != confirm) {
      showSnackBar(context, 'كلمة المرور غير متطابقة', isError: true);
      return;
    }
    if (pass.length < 6) {
      showSnackBar(context, 'كلمة المرور لازم 6 أحرف على الأقل', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // 1) إنشاء حساب Auth
      final res = await AuthMethods().signUpWithEmail(
        email: email,
        password: pass,
        name: name,
      );

      final user = res.user;
      if (user == null) {
        if (!mounted) return;
        showSnackBar(context, 'فشل إنشاء الحساب', isError: true);
        return;
      }

      // 2) محاولة حفظ بروفايل في public.users (بدون created_at)
      // ✅ حتى لو فشل، لا نوقف التسجيل
      try {
        final supabase = Supabase.instance.client;
        await supabase.from('public.users').upsert({
          'id': user.id,
          'email': email,
          'name': name,
          // لا ترسلي created_at هنا
          // إذا عندك أعمدة أخرى مثل phone / is_admin أضيفيها حسب جدولك
        });
      } catch (e) {
        debugPrint('Profile upsert failed but signup succeeded: $e');
      }

      if (!mounted) return;

      showSnackBar(
        context,
        t?.translate('signup_success') ?? 'تم إنشاء الحساب ✅',
        isError: false,
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const BottomNavBar()),
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'خطأ: ${e.message}', isError: true);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: Constants.primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Column(
            children: [
              Image.asset(
                t?.locale.languageCode == 'ar'
                    ? 'assets/image/signup.png'
                    : 'assets/image/signupe.png',
                height: 220,
              ),
              const SizedBox(height: 20),
              _field(
                controller: _nameCtrl,
                label: t?.translate('name') ?? 'Name',
                icon: Icons.person,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _emailCtrl,
                label: t?.translate('email') ?? 'Email',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _field(
                controller: _passCtrl,
                label: t?.translate('password') ?? 'Password',
                icon: Icons.lock,
                obscure: !_showPass,
                suffix: IconButton(
                  icon:
                      Icon(_showPass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showPass = !_showPass),
                ),
              ),
              const SizedBox(height: 14),
              _field(
                controller: _confirmCtrl,
                label: t?.translate('confirm_password') ?? 'Confirm Password',
                icon: Icons.lock,
                obscure: !_showConfirm,
                suffix: IconButton(
                  icon: Icon(
                      _showConfirm ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                ),
              ),
              const SizedBox(height: 22),
              _loading
                  ? const CircularProgressIndicator()
                  : MyButtons(
                      onTap: _signup,
                      text: t?.translate('sign_up') ?? 'Sign Up',
                    ),
            ],
          ),
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
        prefixIcon: Icon(icon, color: Constants.primaryColor),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
