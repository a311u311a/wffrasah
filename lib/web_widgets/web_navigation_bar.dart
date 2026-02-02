import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../providers/user_provider.dart';
import 'responsive_layout.dart';

/// شريط تنقل احترافي وعصري للويب
class WebNavigationBar extends StatefulWidget implements PreferredSizeWidget {
  const WebNavigationBar({super.key});

  @override
  State<WebNavigationBar> createState() => _WebNavigationBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80); // Increased height
}

class _WebNavigationBarState extends State<WebNavigationBar> {
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
      height: 80,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95), // Slight transparency
        border: Border(
            bottom: BorderSide(
                color: Colors.grey.withValues(alpha: 0.1))), // Subtle border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: ResponsiveLayout.isDesktop(context) ? 80 : 20,
        ),
        child: Row(
          children: [
            // Logo + Site Name
            _buildLogo(context, isArabic),

            // Spacer to separate logo from nav links
            if (ResponsiveLayout.isDesktop(context)) const SizedBox(width: 60),

            // Navigation Links (Desktop only)
            if (ResponsiveLayout.isDesktop(context)) ...[
              Expanded(child: _buildNavLinks(localizations, isArabic)),
            ] else ...[
              const Spacer(),
            ],

            // Actions Area
            _buildActions(
                localeProvider, userProvider, localizations, isArabic),

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/image/Rbhan.svg',
            height: 45, // Slightly smaller for balance
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 12),
          Text(
            isArabic ? 'ربحان' : 'Rbhan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
              letterSpacing: isArabic ? 0 : 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavLinks(AppLocalizations? localizations, bool isArabic) {
    final userProvider = Provider.of<UserProvider>(context);

    final allItems = [
      {'label': 'الرئيسية', 'route': '/'},
      {'label': 'المتاجر', 'route': '/stores'},
      {'label': 'الكوبونات', 'route': '/coupons'},
      {'label': 'العروض', 'route': '/offers'},
      {'label': 'المفضلة', 'route': '/favorites'},
      {
        'label': 'لوحة التحكم',
        'route': '/admin',
        'adminOnly': true,
      },
    ];

    final items = allItems.where((item) {
      if (item['adminOnly'] == true) {
        return userProvider.isAdmin;
      }
      return true;
    }).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.start, // Align left/right based on locale
        children: items.map((item) {
          final isCurrent =
              ModalRoute.of(context)?.settings.name == item['route'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: TextButton(
              onPressed: () =>
                  Navigator.pushNamed(context, item['route'] as String),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                foregroundColor:
                    isCurrent ? Constants.primaryColor : Colors.grey[700],
                backgroundColor: isCurrent
                    ? Constants.primaryColor.withValues(alpha: 0.05)
                    : Colors.transparent,
              ),
              child: Text(
                item['label'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w500,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(
    LocaleProvider localeProvider,
    UserProvider userProvider,
    AppLocalizations? localizations,
    bool isArabic,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Search Icon
        IconButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ميزة البحث قادمة قريباً')),
            );
          },
          icon: Icon(Icons.search_rounded, color: Colors.grey[600]),
          tooltip: 'بحث',
          hoverColor: Constants.primaryColor.withValues(alpha: 0.05),
          style: IconButton.styleFrom(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(width: 8),

        // Language Switcher
        _buildLanguageSwitcher(localeProvider, isArabic),
        const SizedBox(width: 20),

        // User Account Link
        _buildUserButton(userProvider, localizations, isArabic),
      ],
    );
  }

  Widget _buildLanguageSwitcher(LocaleProvider localeProvider, bool isArabic) {
    return InkWell(
      onTap: () {
        localeProvider
            .setLocale(isArabic ? const Locale('en') : const Locale('ar'));
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.language_rounded, size: 16, color: Colors.grey[700]),
            const SizedBox(width: 6),
            Text(
              isArabic ? 'English' : 'العربية',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserButton(
    UserProvider userProvider,
    AppLocalizations? localizations,
    bool isArabic,
  ) {
    final user = userProvider.user;

    if (user != null) {
      return PopupMenuButton(
        offset: const Offset(0, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.2),
        constraints: const BoxConstraints.tightFor(width: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Constants.primaryColor.withValues(alpha: 0.1),
                backgroundImage: user.userMetadata?['avatar_url'] != null
                    ? NetworkImage(user.userMetadata!['avatar_url'])
                    : null,
                child: user.userMetadata?['avatar_url'] == null
                    ? Icon(Icons.person_rounded,
                        size: 20, color: Constants.primaryColor)
                    : null,
              ),
              if (ResponsiveLayout.isDesktop(context)) ...[
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    user.userMetadata?['full_name'] ?? 'مستخدم',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontFamily: 'Tajawal',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: Colors.grey[500]),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
        itemBuilder: (context) => <PopupMenuEntry>[
          PopupMenuItem(
            child:
                _buildPopupItem(Icons.person_outline_rounded, 'الملف الشخصي'),
            onTap: () async {
              await Future.delayed(Duration.zero);
              if (context.mounted) {
                Navigator.pushNamed(context, '/menu');
              }
            },
          ),
          PopupMenuItem(
            child: _buildPopupItem(Icons.edit_outlined, 'تعديل الملف الشخصي'),
            onTap: () async {
              await Future.delayed(Duration.zero);
              if (context.mounted) {
                Navigator.pushNamed(context, '/edit-profile');
              }
            },
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            child: _buildPopupItem(Icons.logout_rounded, 'تسجيل الخروج',
                isDestructive: true),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              }
            },
          ),
        ],
      );
    } else {
      return ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/signin'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Constants.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: const Text(
          'تسجيل الدخول',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontFamily: 'Tajawal',
            fontSize: 15,
          ),
        ),
      );
    }
  }

  Widget _buildPopupItem(IconData icon, String title,
      {bool isDestructive = false}) {
    return Row(
      children: [
        Icon(icon,
            size: 20, color: isDestructive ? Colors.red : Colors.grey[700]),
        const SizedBox(width: 12),
        Text(title,
            style: TextStyle(
                fontFamily: 'Tajawal',
                color: isDestructive ? Colors.red : Colors.grey[800],
                fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMobileMenu(AppLocalizations? localizations, bool isArabic) {
    return IconButton(
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => _buildMobileMenuSheet(localizations, isArabic),
        );
      },
      icon: Icon(Icons.menu_rounded, color: Colors.grey[800]),
    );
  }

  Widget _buildMobileMenuSheet(AppLocalizations? localizations, bool isArabic) {
    final userProvider = Provider.of<UserProvider>(context);

    final allItems = [
      {'label': 'الرئيسية', 'route': '/', 'icon': Icons.home_outlined},
      {'label': 'المتاجر', 'route': '/stores', 'icon': Icons.store_outlined},
      {
        'label': 'الكوبونات',
        'route': '/coupons',
        'icon': Icons.local_activity_outlined
      },
      {
        'label': 'العروض',
        'route': '/offers',
        'icon': Icons.local_offer_outlined
      },
      {
        'label': 'المفضلة',
        'route': '/favorites',
        'icon': Icons.favorite_border
      },
      {'label': 'من نحن', 'route': '/about', 'icon': Icons.info_outline},
      {'label': 'اتصل بنا', 'route': '/contact', 'icon': Icons.mail_outline},
      {
        'label': 'لوحة التحكم',
        'route': '/admin',
        'icon': Icons.admin_panel_settings_outlined,
        'adminOnly': true
      },
    ];

    final items = allItems.where((item) {
      if (item['adminOnly'] == true) return userProvider.isAdmin;
      return true;
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
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
