import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../web_widgets/web_navigation_bar.dart';
import 'web_admin_stores_screen.dart';
import 'web_admin_coupons_screen.dart';
import 'web_admin_offers_screen.dart';
import 'web_admin_carousel_screen.dart';
import 'web_admin_notifications_screen.dart';
import '../screens/admin/admin_categories_screen.dart';
import '../screens/admin/admin_pending_coupons_screen.dart';

class WebAdminScreen extends StatefulWidget {
  static const routeName = '/admin';

  const WebAdminScreen({super.key});

  @override
  State<WebAdminScreen> createState() => _WebAdminScreenState();
}

class _WebAdminScreenState extends State<WebAdminScreen> {
  int _selectedIndex = 0;
  final SupabaseClient _sb = Supabase.instance.client;

  final List<String> _titles = [
    'إدارة المتاجر',
    'إدارة الكوبونات',
    'بانتظار الموافقة',
    'إدارة الفئات',
    'إدارة العروض',
    'بنر الصور',
    'الإشعارات',
  ];

  final List<IconData> _icons = [
    Icons.storefront_rounded,
    Icons.confirmation_number_rounded,
    Icons.pending_actions_rounded,
    Icons.category_rounded,
    Icons.local_offer_rounded,
    Icons.view_carousel_rounded,
    Icons.notifications_active_rounded,
  ];

  final List<String> _countSources = [
    'stores',
    'coupons',
    'admin_pending_coupons',
    'categories',
    'offers',
    'carousel',
    'notifications',
  ];

  Future<int> _countRows(String source) async {
    try {
      final rows = await _sb.from(source).select('id');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const WebAdminStoresScreen(isEmbedded: true),
      const WebAdminCouponsScreen(isEmbedded: true),
      const AdminPendingCouponsScreen(isEmbedded: true),
      const AdminCategoriesScreen(isEmbedded: true),
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
                        child: InkWell(
                          onTap: () => setState(() => _selectedIndex = index),
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            child: Row(
                              children: [
                                Icon(
                                  _icons[index],
                                  color: isSelected
                                      ? Constants.primaryColor
                                      : Colors.grey[600],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _titles[index],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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
                                ),
                                const SizedBox(width: 10),
                                _AdminCountBadge(
                                  future: _countRows(_countSources[index]),
                                  color: Constants.primaryColor,
                                  isSelected: isSelected,
                                ),
                              ],
                            ),
                          ),
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

class _AdminCountBadge extends StatelessWidget {
  final Future<int> future;
  final Color color;
  final bool isSelected;

  const _AdminCountBadge({
    required this.future,
    required this.color,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        final count = snapshot.data;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minWidth: 34, minHeight: 26),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.14)
                : Colors.grey.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? color.withValues(alpha: 0.22)
                  : Colors.grey.withValues(alpha: 0.12),
            ),
          ),
          alignment: Alignment.center,
          child: snapshot.connectionState == ConnectionState.waiting
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isSelected ? color : Colors.grey[500],
                  ),
                )
              : Text(
                  '${count ?? 0}',
                  style: TextStyle(
                    color: isSelected ? color : Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                  ),
                ),
        );
      },
    );
  }
}
