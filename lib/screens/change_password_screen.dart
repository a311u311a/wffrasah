import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'login_signup/widgets/snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final t = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _passwordCtrl.text.trim()),
      );

      if (!mounted) return;

      showSnackBar(
        context,
        t?.translate('password_updated') ?? 'Password updated successfully',
        isError: false,
      );

      // Navigate to Home/Login and remove all previous routes
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const BottomNavBar()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      showSnackBar(
        context,
        '${t?.translate('error_oops') ?? 'Error'}: $e',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          t?.translate('change_password') ?? 'Change Password',
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontFamily: 'Tajawal',
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Constants.primaryColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  t?.translate('enter_new_password') ??
                      'Please enter your new password',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontFamily: 'Tajawal',
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // New Password Field
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  decoration: InputDecoration(
                    labelText: t?.translate('new_password') ?? 'New Password',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon:
                        Icon(Icons.lock_outline, color: Constants.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Constants.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return t?.translate('password_required') ??
                          'Password is required';
                    }
                    if (value.length < 6) {
                      return t?.translate('password_short') ??
                          'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(fontFamily: 'Tajawal'),
                  decoration: InputDecoration(
                    labelText: t?.translate('confirm_password') ??
                        'Confirm New Password',
                    labelStyle: const TextStyle(fontFamily: 'Tajawal'),
                    prefixIcon:
                        Icon(Icons.lock_outline, color: Constants.primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirm = !_obscureConfirm);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          BorderSide(color: Constants.primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordCtrl.text) {
                      return t?.translate('passwords_not_match') ??
                          'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),

                // Submit Button
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            t?.translate('save_password') ?? 'Save Password',
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
      ),
    );
  }
}
