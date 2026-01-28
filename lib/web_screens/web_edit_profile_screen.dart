import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// Web version of Edit Profile Screen
class WebEditProfileScreen extends StatefulWidget {
  const WebEditProfileScreen({super.key});

  @override
  State<WebEditProfileScreen> createState() => _WebEditProfileScreenState();
}

class _WebEditProfileScreenState extends State<WebEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) Navigator.pop(context);
      return;
    }

    _currentUserId = user.id;

    try {
      final userData = await Supabase.instance.client
          .from('users')
          .select()
          .eq('uid', user.id)
          .maybeSingle();

      if (mounted && userData != null) {
        setState(() {
          _nameController.text = userData['name'] ?? '';
          _emailController.text = user.email ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Update name in users table
      await Supabase.instance.client.from('users').update({
        'name': _nameController.text.trim(),
      }).eq('uid', _currentUserId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حفظ التعديلات بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            _buildForm(),
            const SizedBox(height: 60),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withValues(alpha: 0.08),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: Constants.primaryColor,
              ),
              const SizedBox(width: 12),
              Text(
                'تعديل الملف الشخصي',
                style: TextStyle(
                  fontSize: ResponsiveLayout.isDesktop(context) ? 36 : 28,
                  fontWeight: FontWeight.w900,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(right: 56),
            child: Text(
              'قم بتحديث معلوماتك الشخصية',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                fontFamily: 'Tajawal',
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: ResponsivePadding.page(context).copyWith(top: 30),
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar placeholder
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Constants.primaryColor.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  size: 50,
                  color: Constants.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 32),
            TextFormField(
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'الرجاء إدخال الاسم';
                }
                return null;
              },
              style: const TextStyle(
                fontSize: 16,
                fontFamily: 'Tajawal',
              ),
              decoration: InputDecoration(
                labelText: 'الاسم',
                labelStyle: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.grey[600],
                ),
                prefixIcon:
                    Icon(Icons.person_rounded, color: Constants.primaryColor),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: Constants.primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _emailController,
              enabled: false,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Tajawal',
                color: Colors.grey[600],
              ),
              decoration: InputDecoration(
                labelText: 'البريد الإلكتروني',
                labelStyle: TextStyle(
                  fontFamily: 'Tajawal',
                  color: Colors.grey[600],
                ),
                prefixIcon: Icon(Icons.email_rounded, color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[200]!),
                ),
                helperText: 'لا يمكن تغيير البريد الإلكتروني',
                helperStyle: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 12,
                  color: Colors.grey[500],
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveProfile,
              icon: const Icon(Icons.save_rounded, size: 20),
              label: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'حفظ التعديلات',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Tajawal',
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Constants.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
