import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:custom_navigation_bar/custom_navigation_bar.dart';

import '../constants.dart';
import '../screens/coupon_screen.dart';
import '../screens/offers_screen.dart';
import '../screens/stores_screen.dart';
import '../screens/favorites_screen.dart';
import '../screens/menu_screen.dart';

import '../services/notification_service.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with WidgetsBindingObserver {
  late int _selectedIndex;

  final List<Widget> _pages = const [
    StoresScreen(),
    CouponScreen(),
    OffersScreen(),
    FavoritesScreen(),
    MenuScreen(),
  ];

  final List<Map<String, String>> _icons = [
    {'active': 'assets/icon/grid.svg', 'inactive': 'assets/icon/grid.svg'},
    {
      'active': 'assets/icon/ticket.svg',
      'inactive': 'assets/icon/ticket_active.svg'
    },
    {
      'active': 'assets/icon/home.svg',
      'inactive': 'assets/icon/home_active.svg'
    },
    {
      'active': 'assets/icon/star.svg',
      'inactive': 'assets/icon/star_active.svg'
    },
    {
      'active': 'assets/icon/apps.svg',
      'inactive': 'assets/icon/apps_active.svg'
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);

    // Initialize notifications here so they appear on main pages
    NotificationService.listenToInAppNotifications(context);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      NotificationService.stopListening();
      debugPrint('⏸️ App paused - stopped notification stream');
    } else if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          NotificationService.listenToInAppNotifications(context);
          debugPrint('▶️ App resumed - restarted notification stream');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false, // لمنع رفع شريط التنقل عند ظهور الكيبورد
      body: _pages[_selectedIndex],
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            height: 60, // ارتفاع مناسب لجميع الشاشات
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Constants.primaryColor,
                  Constants.primaryColor.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: CustomNavigationBar(
              elevation: 0,
              backgroundColor: Colors.transparent,
              strokeColor: Colors.transparent,
              borderRadius: const Radius.circular(32),
              selectedColor: Colors.white,
              unSelectedColor: Colors.white70,
              currentIndex: _selectedIndex,
              items: List.generate(
                _icons.length,
                (index) => CustomNavigationBarItem(
                  icon: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SvgPicture.asset(
                          _selectedIndex == index
                              ? _icons[index]['active']!
                              : _icons[index]['inactive']!,
                          height: 22,
                          width: 22,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2), // تقليل المسافة لتجنب Overflow
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        height: 3,
                        width: _selectedIndex == index ? 14 : 0,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
            ),
          ),
        ),
      ),
    );
  }
}
