import 'package:coupon/screens/signin.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:app_settings/app_settings.dart';
import '../Login Signup/Widget/edit_profile_page.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'about_app_screen.dart';
import 'contact_us.dart';
import 'admin_screen.dart';
import 'terms_screen.dart';
import 'privacy_screen.dart';
import 'faq_screen.dart';
import 'notifications_history_screen.dart';

import 'package:permission_handler/permission_handler.dart'; // ✅ Re-added for Permission check

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with WidgetsBindingObserver {
  bool _isCheckingPermission = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkNotificationPermission();
        }
      });
    }
  }

  Future<void> _checkNotificationPermission() async {
    // منع الاستدعاءات المتزامنة
    if (_isCheckingPermission) return;
    _isCheckingPermission = true;

    try {
      // التحقق من حالة الإذن الحالية في النظام
      final status = await Permission.notification.status;

      // فحص mounted بعد العملية غير المتزامنة
      if (!mounted) return;

      final isGranted = status.isGranted;
      final provider =
          Provider.of<NotificationProvider>(context, listen: false);

      // إذا كانت الحالة في النظام مختلفة عن الحالة في التطبيق، نقوم بتحديثها
      if (provider.isNotificationsEnabled != isGranted) {
        await provider.toggleNotifications(isGranted);
      }
    } catch (e) {
      debugPrint('❌ Error checking notification permission: $e');
    } finally {
      _isCheckingPermission = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        toolbarHeight: 80,
        title: Text(localizations?.translate('account') ?? 'Account',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 20,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
            )),
        foregroundColor: Constants.primaryColor,
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withOpacity(0.1),
              Colors.white,
            ],
            stops: const [0.0, 0.3],
          ),
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 90),
                  child: Column(
                    children: [
                      if (user == null)
                        _buildGuestCard(context, localizations)
                      else
                        _buildUserCard(context, user, localizations),
                      const SizedBox(height: 10),
                      _buildLanguageSwitcher(context),
                      const SizedBox(height: 10),
                      _buildNotificationCenterTile(context),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (user != null) ...[
                                _buildDivider(),
                                Consumer<UserProvider>(
                                  builder: (context, userProvider, child) {
                                    if (userProvider.isLoading)
                                      return const SizedBox.shrink();
                                    if (!userProvider.isAdmin)
                                      return const SizedBox.shrink();

                                    return _buildMenuTile(
                                      icon: Icons.admin_panel_settings,
                                      title: localizations
                                              ?.translate('admin_panel') ??
                                          'Admin Panel',
                                      onTap: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    const AdminScreen()));
                                      },
                                    );
                                  },
                                ),
                              ],
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.email,
                                title: localizations?.translate('contact_us') ??
                                    'Contact Us',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const ContactUsScreen())),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.star_rounded,
                                title: localizations?.translate('rate_app') ??
                                    'Rate App',
                                onTap: () {},
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.share_rounded,
                                title: localizations?.translate('share_app') ??
                                    'Share App',
                                onTap: () {
                                  const String appLink =
                                      "https://play.google.com/store/apps/details?id=com.yourapp.package";
                                  Share.share(
                                      'Check out this amazing app for coupons! $appLink');
                                },
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.description,
                                title:
                                    localizations?.translate('terms_of_use') ??
                                        'Terms of Use',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const TermsScreen())),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.privacy_tip,
                                title: localizations
                                        ?.translate('privacy_policy') ??
                                    'Privacy Policy',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const PrivacyScreen())),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.quiz,
                                title: localizations?.translate('faq') ?? 'FAQ',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const FaqScreen())),
                              ),
                              _buildDivider(),
                              _buildMenuTile(
                                icon: Icons.info,
                                title: localizations?.translate('about') ??
                                    'About',
                                onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) =>
                                            const AboutAppScreen())),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
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

  Widget _buildUserCard(BuildContext context, User user, var localizations) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Supabase.instance.client
          .from('users')
          .select()
          .eq('uid', user.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
              height: 150,
              alignment: Alignment.center,
              child: const CircularProgressIndicator());
        }

        final userData = snapshot.data;
        final userName =
            userData?['name'] ?? user.userMetadata?['full_name'] ?? 'User';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Constants.primaryColor.withOpacity(0.1),
                    backgroundImage: user.userMetadata?['avatar_url'] != null
                        ? NetworkImage(user.userMetadata?['avatar_url'])
                        : null,
                    child: user.userMetadata?['avatar_url'] == null
                        ? Icon(Icons.person,
                            size: 35, color: Constants.primaryColor)
                        : null,
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(userName,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        Text(user.email ?? '',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const EditProfilePage())),
                      icon: const Icon(Icons.edit_note,
                          size: 24, color: Colors.white),
                      label: Text(
                          localizations?.translate('edit_profile') ?? 'Edit'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: () async {
                      await Supabase.instance.client.auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const BottomNavBar()),
                            (route) => false);
                      }
                    },
                    icon: const Icon(Icons.logout_rounded,
                        color: Colors.redAccent),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuestCard(BuildContext context, var localizations) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Constants.primaryColor,
          Constants.primaryColor.withOpacity(0.8)
        ]),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_circle, size: 60, color: Colors.white),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(localizations?.translate('welcome') ?? 'Welcome',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (context) => const SignIn())),
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero, foregroundColor: Colors.white),
                  child: Container(
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Colors.white, width: 1))),
                    child: Text(
                        localizations?.translate('Log in now') ?? 'Log in now',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(
      {required IconData icon,
      required String title,
      required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Constants.primaryColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      trailing:
          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildDivider() =>
      Divider(height: 1, indent: 60, color: Colors.grey[100]);

  Widget _buildLanguageSwitcher(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, provider, child) {
        bool isAr = provider.locale.languageCode == 'ar';
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                _buildLangBtn('English', !isAr,
                    () => provider.setLocale(const Locale('en'))),
                _buildLangBtn('العربية', isAr,
                    () => provider.setLocale(const Locale('ar'))),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLangBtn(String title, bool isActive, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            boxShadow: isActive
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05), blurRadius: 5)
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.black87 : Colors.grey[600])),
        ),
      ),
    );
  }

  Widget _buildNotificationCenterTile(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsHistoryScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(15),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      provider.isNotificationsEnabled
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_rounded,
                      color: Constants.primaryColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)
                                ?.translate('notification_center') ??
                            'Notification Center',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Switch(
                      value: provider.isNotificationsEnabled,
                      activeColor: Constants.primaryColor,
                      onChanged: (value) async {
                        // فتح إعدادات الإشعارات الفرعية مباشرة
                        await AppSettings.openAppSettings(
                            type: AppSettingsType.notification);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
