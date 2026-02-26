import 'package:wffrasah/constants.dart';
import 'package:wffrasah/localization/app_localizations.dart';
import 'package:wffrasah/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'snackbar.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String _gender = 'male';
  String _countryCode = '+966';
  String? _imgUrl;

  final Map<String, String> _countryCodes = {
    '+966': 'SA',
  };

  SupabaseClient get _sb => Supabase.instance.client;

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = _sb.auth.currentUser;
    if (user == null) return;

    try {
      // Query explicit columns instead of JSONB
      final row = await _sb
          .from('users')
          .select('name, email, id, gender, phone, country_code, img_url')
          .eq('id', user.id)
          .maybeSingle();

      if (!mounted) return;

      setState(() {
        _nameController.text = (row?['name'] ??
                user.userMetadata?['name'] ??
                user.userMetadata?['full_name'] ??
                '')
            .toString();

        _emailController.text = (row?['email'] ?? user.email ?? '').toString();

        // Load explicit columns
        _gender = (row?['gender'] ?? 'male').toString().trim();
        if (_gender != 'male' && _gender != 'female') _gender = 'male';

        final cc = (row?['country_code'] ?? '+966').toString().trim();
        _countryCode = _countryCodes.containsKey(cc) ? cc : '+966';

        _phoneController.text = (row?['phone'] ?? '').toString().trim();

        _imgUrl = (row?['img_url'] ??
                user.userMetadata?['avatar_url'] ??
                user.userMetadata?['picture'])
            ?.toString();
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _sb.auth.currentUser;
    if (user == null) {
      showSnackBar(context, 'يجب تسجيل الدخول أولاً', isError: true);
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ تحديث Auth metadata (اختياري لكنه مفيد)
      await _sb.auth.updateUser(
        UserAttributes(
          data: {
            'name': _nameController.text.trim(),
            'gender': _gender,
            'countryCode': _countryCode,
            'phone': _phoneController.text.trim(),
          },
        ),
      );

      // Log payload for debugging
      final payload = {
        'id': user.id,
        'name': _nameController.text.trim(),
        'email': user.email,
        'gender': _gender,
        'country_code': _countryCode,
        'phone': _phoneController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint(
          'EditProfilePage: Attempting to update user profile (Explicit Columns)...');
      debugPrint('EditProfilePage: Payload: $payload');

      // Update explicit columns
      await _sb.from('users').upsert(payload);

      debugPrint('EditProfilePage: Profile updated successfully!');

      if (!mounted) return;

      showSnackBar(
        context,
        AppLocalizations.of(context)!.translate('profile_updated'),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('EditProfilePage: Error updating profile: $e');
      if (!mounted) return;
      showSnackBar(context, 'خطأ: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _buildInputDecoration(
    String label,
    IconData icon, {
    bool readOnly = false,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.black54,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(icon, color: Constants.primaryColor, size: 20),
      filled: true,
      fillColor: readOnly ? Colors.grey[200] : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Constants.primaryColor, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          appLocalizations.translate('edit_profile'),
          style: TextStyle(
            color: Constants.primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 10,
                          )
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor:
                            Constants.primaryColor.withValues(alpha: 0.1),
                        backgroundImage:
                            (_imgUrl != null && _imgUrl!.isNotEmpty)
                                ? NetworkImage(_imgUrl!)
                                : null,
                        child: (_imgUrl == null || _imgUrl!.isEmpty)
                            ? Icon(Icons.person,
                                size: 60, color: Constants.primaryColor)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.normal,
                ),
                controller: _nameController,
                decoration: _buildInputDecoration(
                  appLocalizations.translate('full_name'),
                  Icons.person_outline,
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'هذا الحقل مطلوب';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.normal,
                ),
                controller: _emailController,
                readOnly: true,
                decoration: _buildInputDecoration(
                  appLocalizations.translate('email'),
                  Icons.email_outlined,
                  readOnly: true,
                ),
              ),
              const SizedBox(height: 20),
              _buildPhoneField(appLocalizations),
              const SizedBox(height: 30),
              _buildGenderSelector(appLocalizations),
              const SizedBox(height: 50),
              SizedBox(
                width: screenWidth,
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Constants.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          appLocalizations.translate('apply_changes'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _deleteAccountDialog,
                child: Text(
                  appLocalizations.translate('delete_account'),
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField(AppLocalizations appLocalizations) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _countryCode,
              items: _countryCodes.entries
                  .map(
                    (e) => DropdownMenuItem(
                      value: e.key,
                      child: Text(e.key),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _countryCode = v ?? '+966'),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextFormField(
            style: const TextStyle(
              color: Colors.black54,
              fontWeight: FontWeight.normal,
            ),
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: _buildInputDecoration(
              appLocalizations.translate('phone_number'),
              Icons.phone,
            ).copyWith(prefixIcon: null),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(AppLocalizations appLocalizations) {
    return Row(
      children: [
        _genderOption(appLocalizations.translate('male'), 'male'),
        const SizedBox(width: 15),
        _genderOption(appLocalizations.translate('female'), 'female'),
      ],
    );
  }

  Widget _genderOption(String label, String value) {
    final isSelected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? Constants.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isSelected
                  ? Constants.primaryColor
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _deleteAccountDialog() {
    final appLocalizations = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(appLocalizations.translate('delete_account')),
        content: Text(appLocalizations.translate('delete_account_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(appLocalizations.translate('cancel')),
          ),
          TextButton(
            onPressed: _deleteAccount,
            child: Text(
              appLocalizations.translate('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    // Hide the dialog
    Navigator.pop(context);

    setState(() => _loading = true);

    try {
      // 1. Call the RPC function to delete the user from the database
      await _sb.rpc('delete_user');

      // 2. Sign out from Supabase Auth
      await _sb.auth.signOut();

      if (!mounted) return;

      // 3. Show success message
      showSnackBar(
        context,
        AppLocalizations.of(context)!.translate('account_deleted'),
      );

      // 4. Navigate to the initial screen (Restart app flow)
      // Removing all routes ensures the user can't go back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        showSnackBar(context, 'فشل حذف الحساب: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
