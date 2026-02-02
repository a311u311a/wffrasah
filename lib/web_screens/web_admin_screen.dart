import 'package:flutter/material.dart';
import '../constants.dart';
import '../web_widgets/web_navigation_bar.dart';
import 'web_admin_stores_screen.dart';
import 'web_admin_coupons_screen.dart';
import 'web_admin_offers_screen.dart';
import 'web_admin_carousel_screen.dart';
import 'web_admin_notifications_screen.dart';

class WebAdminScreen extends StatefulWidget {
  static const routeName = '/admin';

  const WebAdminScreen({super.key});

  @override
  State<WebAdminScreen> createState() => _WebAdminScreenState();
}

class _WebAdminScreenState extends State<WebAdminScreen> {
  int _selectedIndex = 0;

  final List<String> _titles = [
    'إدارة المتاجر',
    'إدارة الكوبونات',
    'إدارة العروض',
    'بنر الصور',
    'الإشعارات',
  ];

  final List<IconData> _icons = [
    Icons.storefront_rounded,
    Icons.confirmation_number_rounded,
    Icons.local_offer_rounded,
    Icons.view_carousel_rounded,
    Icons.notifications_active_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const WebAdminStoresScreen(isEmbedded: true),
      const WebAdminCouponsScreen(isEmbedded: true),
      const WebAdminOffersScreen(isEmbedded: true),
      const WebAdminCarouselScreen(isEmbedded: true),
      const WebAdminNotificationsScreen(isEmbedded: true),
    ];

    // Assuming RTL directionality is handled by the higher-level app theme or Directionality widget.
    // In RTL, Row adds children from Right to Left.
    // So Sidebar should be first content-wise to appear on the Right.
    // Wait, in RTL, Row children are: [First, Second] -> First is on Right, Second is on Left.
    // So yes, Sidebar first.

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: const WebNavigationBar(),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- Sidebar ---
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                left: BorderSide(
                    color: Colors.grey[200]!), // Left border for RTL sidebar
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(-2, 0), // Shadow to the left
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 30),
                // Sidebar Header / User Info could go here
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Constants.primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.admin_panel_settings,
                            color: Constants.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'لوحة التحكم',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Divider(height: 40),

                // Navigation Items
                Expanded(
                  child: ListView.builder(
                    itemCount: _titles.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Constants.primaryColor.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          onTap: () => setState(() => _selectedIndex = index),
                          leading: Icon(
                            _icons[index],
                            color: isSelected
                                ? Constants.primaryColor
                                : Colors.grey[600],
                          ),
                          title: Text(
                            _titles[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Constants.primaryColor
                                  : Colors.grey[800],
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontFamily: 'Tajawal',
                              fontSize: 15,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                  ),
                ),

                // Footer in Sidebar (Optional)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

          // --- Main Content Area ---
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
