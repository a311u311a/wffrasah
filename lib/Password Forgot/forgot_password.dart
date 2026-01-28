import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../screens/login_signup/widgets/snackbar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final t = AppLocalizations.of(context);
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      showSnackBar(
        context,
        t?.translate('email_required') ?? 'Please enter your email',
        isError: true,
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'com.rbhan.app://login-callback/',
      );
      if (!mounted) return;

      showSnackBar(
        context,
        t?.translate('password_reset_sent') ??
            'We have sent you the reset password link to your email, please check it',
        isError: false,
      );

      // Optional: Go back after success
      // Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        '${t?.translate('password_reset_failed') ?? 'Failed to send reset email'}: $e',
        isError: true,
      );
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Title
              Text(
                t?.translate('forgot_password_title') ?? 'Forgot Password?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              // Subtitle
              Text(
                t?.translate('enter_email_subtitle') ??
                    'Enter your email to receive a reset link',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontFamily: 'Tajawal',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Field
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(fontFamily: 'Tajawal'),
                decoration: InputDecoration(
                  labelText: t?.translate('email') ?? 'Email',
                  labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                  prefixIcon:
                      Icon(Icons.email_outlined, color: Constants.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        BorderSide(color: Constants.primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 30),

              // Send Button
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _sendReset,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          t?.translate('send') ?? 'Send',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Tajawal',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
