import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import 'responsive_layout.dart';

/// شريط تنقل احترافي للويب
class WebNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  const WebNavigationBar({super.key});

  @override
  State<WebNavigationBar> createState() => _WebNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

class _WebNavigationBarState extends State<WebNavigationBar> {
  bool isSearchExpanded = false;
  final TextEditingController searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final localizations = AppLocalizations.of(context);
    final isArabic = localeProvider.locale.languageCode == 'ar';

    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isDesktop(context) ? 60 : 20,
        ),
        child: Row(
          children: [
            // Logo
            _buildLogo(context, isArabic),
            const SizedBox(width: 40),

            // Navigation Links (Desktop only)
            if (ResponsiveLayout.isDesktop(context)) ...[
              Expanded(child: _buildNavLinks(localizations, isArabic)),
            ] else ...[
              const Spacer(),
            ],

            // Search Icon
            _buildSearchButton(),
            const SizedBox(width: 16),

            // Language Switcher
            _buildLanguageSwitcher(localeProvider, isArabic),
            const SizedBox(width: 16),

            // User Account / Login
            _buildUserSection(userProvider, localizations, isArabic),

            // Mobile Menu (Tablet & Mobile)
            if (!ResponsiveLayout.isDesktop(context)) ...[
              const SizedBox(width: 16),
              _buildMobileMenu(localizations, isArabic),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(BuildContext context, bool isArabic) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Constants.primaryColor,
                    Constants.primaryColor.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_offer_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'كوبونات',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Constants.primaryColor,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavLinks(AppLocalizations? localizations, bool isArabic) {
    final userProvider = Provider.of<UserProvider>(context);

    final allItems = [
      {'label': 'الرئيسية', 'route': '/', 'icon': Icons.home_rounded},
      {'label': 'المتاجر', 'route': '/stores', 'icon': Icons.store_rounded},
      {
        'label': 'الكوبونات',
        'route': '/coupons',
        'icon': Icons.confirmation_number_rounded
      },
      {
        'label': 'العروض',
        'route': '/offers',
        'icon': Icons.local_offer_rounded
      },
      {
        'label': 'المفضلة',
        'route': '/favorites',
        'icon': Icons.favorite_rounded
      },
      {
        'label': 'لوحة التحكم',
        'route': '/admin',
        'icon': Icons.admin_panel_settings_rounded,
        'adminOnly': true, // علامة للعناصر الخاصة بالإدارة فقط
      },
    ];

    // تصفية العناصر: إخفاء لوحة التحكم إذا لم يكن المستخدم أدمن
    final items = allItems.where((item) {
      if (item['adminOnly'] == true) {
        return userProvider.isAdmin;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.map((item) {
          final isCurrent =
              ModalRoute.of(context)?.settings.name == item['route'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, item['route'] as String),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                backgroundColor: isCurrent
                    ? Constants.primaryColor.withOpacity(0.1)
                    : Colors.transparent,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    size: 20,
                    color:
                        isCurrent ? Constants.primaryColor : Colors.grey[700],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
                      color:
                          isCurrent ? Constants.primaryColor : Colors.grey[700],
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSearchButton() {
    return IconButton(
      onPressed: () {
        // TODO: Implement search
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ميزة البحث قادمة قريباً')),
        );
      },
      icon: Icon(Icons.search_rounded, color: Constants.primaryColor),
      tooltip: 'بحث',
    );
  }

  Widget _buildLanguageSwitcher(LocaleProvider localeProvider, bool isArabic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildLanguageButton('ع', isArabic, () {
            localeProvider.setLocale(const Locale('ar'));
          }),
          _buildLanguageButton('EN', !isArabic, () {
            localeProvider.setLocale(const Locale('en'));
          }),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(String label, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Constants.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isActive ? Colors.white : Constants.primaryColor,
            fontFamily: 'Tajawal',
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(
    UserProvider userProvider,
    AppLocalizations? localizations,
    bool isArabic,
  ) {
    final user = userProvider.user;

    if (user != null) {
      return PopupMenuButton(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Constants.primaryColor.withOpacity(0.1),
              child: Icon(
                Icons.person_rounded,
                color: Constants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            if (ResponsiveLayout.isDesktop(context))
              Text(
                user.email ?? 'مستخدم',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Constants.primaryColor,
                  fontFamily: 'Tajawal',
                ),
              ),
          ],
        ),
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            child: const Text('الملف الشخصي'),
            onTap: () {},
          ),
          PopupMenuItem(
            child: const Text('الإعدادات'),
            onTap: () {},
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            child: const Text('تسجيل الخروج'),
            onTap: () {
              // TODO: Implement sign out
            },
          ),
        ],
      );
    } else {
      return ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/signin'),
        icon: const Icon(Icons.login_rounded, size: 18),
        label: Text(
          ResponsiveLayout.isDesktop(context) ? 'تسجيل الدخول' : '',
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Tajawal',
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(
            horizontal: ResponsiveLayout.isDesktop(context) ? 24 : 12,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Widget _buildMobileMenu(AppLocalizations? localizations, bool isArabic) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          builder: (context) => _buildMobileMenuSheet(localizations, isArabic),
        );
      },
      icon: Icon(Icons.menu_rounded, color: Constants.primaryColor),
    );
  }

  Widget _buildMobileMenuSheet(AppLocalizations? localizations, bool isArabic) {
    final userProvider = Provider.of<UserProvider>(context);

    final allItems = [
      {'label': 'الرئيسية', 'route': '/', 'icon': Icons.home_rounded},
      {'label': 'المتاجر', 'route': '/stores', 'icon': Icons.store_rounded},
      {
        'label': 'الكوبونات',
        'route': '/coupons',
        'icon': Icons.confirmation_number_rounded
      },
      {
        'label': 'العروض',
        'route': '/offers',
        'icon': Icons.local_offer_rounded
      },
      {
        'label': 'المفضلة',
        'route': '/favorites',
        'icon': Icons.favorite_rounded
      },
      {'label': 'من نحن', 'route': '/about', 'icon': Icons.info_rounded},
      {
        'label': 'اتصل بنا',
        'route': '/contact',
        'icon': Icons.contact_mail_rounded
      },
      {'label': 'الأسئلة الشائعة', 'route': '/faq', 'icon': Icons.help_rounded},
      {
        'label': 'لوحة التحكم',
        'route': '/admin',
        'icon': Icons.admin_panel_settings_rounded,
        'adminOnly': true, // علامة للعناصر الخاصة بالإدارة فقط
      },
    ];

    // تصفية العناصر: إخفاء لوحة التحكم إذا لم يكن المستخدم أدمن
    final items = allItems.where((item) {
      if (item['adminOnly'] == true) {
        return userProvider.isAdmin;
      }
      return true;
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          return ListTile(
            leading:
                Icon(item['icon'] as IconData, color: Constants.primaryColor),
            title: Text(
              item['label'] as String,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'Tajawal',
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, item['route'] as String);
            },
          );
        }).toList(),
      ),
    );
  }
}
