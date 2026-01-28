import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';

/// Web version of Menu/Account Screen
class WebMenuScreen extends StatelessWidget {
  const WebMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            if (user != null) _buildUserSection(context, user),
            if (user == null) _buildGuestSection(context),
            _buildMenuSections(context, user),
            const SizedBox(height: 60),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: ResponsivePadding.page(context),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Constants.primaryColor.withValues(alpha: 0.08),
            Constants.primaryColor.withValues(alpha: 0.02),
            Colors.white,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 40),
          Text(
            'حسابي',
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'إدارة حسابك والإعدادات',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildUserSection(BuildContext context, User user) {
    return Container(
      margin: ResponsivePadding.page(context).copyWith(top: 20, bottom: 30),
      constraints: const BoxConstraints(maxWidth: 800),
      child: FutureBuilder<Map<String, dynamic>?>(
        future: Supabase.instance.client
            .from('users')
            .select()
            .eq('uid', user.id)
            .maybeSingle(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: CircularProgressIndicator(color: Constants.primaryColor),
              ),
            );
          }

          final userData = snapshot.data;
          final userName =
              userData?['name'] ?? user.userMetadata?['full_name'] ?? 'مستخدم';
          final userEmail = user.email ?? '';

          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Constants.primaryColor.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Constants.primaryColor.withValues(alpha: 0.08),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar
                    Container(
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
                      child: user.userMetadata?['avatar_url'] != null
                          ? ClipOval(
                              child: Image.network(
                                user.userMetadata?['avatar_url'],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Constants.primaryColor,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 50,
                              color: Constants.primaryColor,
                            ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildActionButton(
                      context,
                      icon: Icons.edit_rounded,
                      label: 'تعديل الملف الشخصي',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/edit-profile'),
                      isPrimary: true,
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.lock_rounded,
                      label: 'تغيير كلمة المرور',
                      onPressed: () =>
                          Navigator.pushNamed(context, '/change-password'),
                      isPrimary: false,
                    ),
                    _buildActionButton(
                      context,
                      icon: Icons.logout_rounded,
                      label: 'تسجيل الخروج',
                      onPressed: () async {
                        await Supabase.instance.client.auth.signOut();
                        if (context.mounted) {
                          Navigator.pushReplacementNamed(context, '/');
                        }
                      },
                      isPrimary: false,
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isDestructive = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Tajawal',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive
            ? Colors.red[50]
            : isPrimary
                ? Constants.primaryColor
                : Colors.grey[100],
        foregroundColor: isDestructive
            ? Colors.red
            : isPrimary
                ? Colors.white
                : Colors.black87,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 0,
      ),
    );
  }

  Widget _buildGuestSection(BuildContext context) {
    return Container(
      margin: ResponsivePadding.page(context).copyWith(top: 20, bottom: 30),
      constraints: const BoxConstraints(maxWidth: 600),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Constants.primaryColor,
            Constants.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.account_circle_rounded,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          const Text(
            'مرحباً بك!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              fontFamily: 'Tajawal',
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'سجل الدخول للحصول على تجربة شخصية',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              fontFamily: 'Tajawal',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/signin'),
                icon: const Icon(Icons.login_rounded),
                label: const Text(
                  'تسجيل الدخول',
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Constants.primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text(
                  'إنشاء حساب',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Tajawal',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections(BuildContext context, User? user) {
    return Container(
      margin: ResponsivePadding.page(context),
      constraints: const BoxConstraints(maxWidth: 800),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (user != null) ...[
            _buildMenuSection(
              context,
              title: 'الحساب',
              items: [
                _MenuItem(
                  icon: Icons.notifications_rounded,
                  title: 'الإشعارات',
                  onTap: () => Navigator.pushNamed(context, '/notifications'),
                ),
                _MenuItem(
                  icon: Icons.delete_forever_rounded,
                  title: 'حذف الحساب',
                  onTap: () => Navigator.pushNamed(context, '/delete-account'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer<UserProvider>(
              builder: (context, userProvider, child) {
                if (userProvider.isAdmin) {
                  return Column(
                    children: [
                      _buildMenuSection(
                        context,
                        title: 'الإدارة',
                        items: [
                          _MenuItem(
                            icon: Icons.admin_panel_settings_rounded,
                            title: 'لوحة التحكم',
                            onTap: () => Navigator.pushNamed(context, '/admin'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          _buildMenuSection(
            context,
            title: 'المساعدة والدعم',
            items: [
              _MenuItem(
                icon: Icons.email_rounded,
                title: 'اتصل بنا',
                onTap: () => Navigator.pushNamed(context, '/contact'),
              ),
              _MenuItem(
                icon: Icons.quiz_rounded,
                title: 'الأسئلة الشائعة',
                onTap: () => Navigator.pushNamed(context, '/faq'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildMenuSection(
            context,
            title: 'حول التطبيق',
            items: [
              _MenuItem(
                icon: Icons.description_rounded,
                title: 'الشروط والأحكام',
                onTap: () => Navigator.pushNamed(context, '/terms'),
              ),
              _MenuItem(
                icon: Icons.privacy_tip_rounded,
                title: 'سياسة الخصوصية',
                onTap: () => Navigator.pushNamed(context, '/privacy'),
              ),
              _MenuItem(
                icon: Icons.info_rounded,
                title: 'عن التطبيق',
                onTap: () => Navigator.pushNamed(context, '/about'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildLanguageSwitcher(context),
        ],
      ),
    );
  }

  Widget _buildMenuSection(
    BuildContext context, {
    required String title,
    required List<_MenuItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.grey[600],
                fontFamily: 'Tajawal',
                letterSpacing: 0.5,
              ),
            ),
          ),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                if (index > 0)
                  Divider(
                    height: 1,
                    indent: 60,
                    color: Colors.grey[100],
                  ),
                _buildMenuItem(
                  context: context,
                  icon: item.icon,
                  title: item.title,
                  onTap: item.onTap,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Constants.primaryColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageSwitcher(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        final isAr = provider.locale.languageCode == 'ar';
        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Row(
              children: [
                _buildLanguageButton(
                  'English',
                  !isAr,
                  () => provider.setLocale(const Locale('en')),
                ),
                _buildLanguageButton(
                  'العربية',
                  isAr,
                  () => provider.setLocale(const Locale('ar')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isActive ? Constants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: isActive ? Colors.white : Colors.grey[600],
              fontFamily: isActive ? 'Tajawal' : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}
