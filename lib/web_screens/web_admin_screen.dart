import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants.dart';
import '../localization/app_localizations.dart';
import '../web_widgets/web_navigation_bar.dart';
import 'web_admin_stores_screen.dart';
import 'web_admin_coupons_screen.dart';
import 'web_admin_offers_screen.dart';
import 'web_admin_carousel_screen.dart';
import 'web_admin_notifications_screen.dart';
import 'web_admin_coupon_providers_screen.dart';
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
  String _version = '';
  final SupabaseClient _sb = Supabase.instance.client;

  final List<String> _titleKeys = [
    'admin_overview',
    'admin_manage_stores',
    'admin_manage_coupons',
    'admin_manage_offers',
    'admin_manage_categories',
    'admin_carousel_banner',
    'admin_pending_approval',
    'notifications',
    'admin_coupon_providers',
  ];

  final List<IconData> _icons = [
    Icons.dashboard_rounded,
    Icons.storefront_rounded,
    Icons.confirmation_number_rounded,
    Icons.local_offer_rounded,
    Icons.category_rounded,
    Icons.view_carousel_rounded,
    Icons.pending_actions_rounded,
    Icons.notifications_active_rounded,
    Icons.business_center_outlined,
  ];

  final List<String> _countSources = [
    'stores',
    'stores',
    'coupons',
    'offers',
    'categories',
    'carousel',
    'admin_pending_coupons',
    'notifications',
    'coupon_providers',
  ];

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
    });
  }

  Future<int> _countRows(String source) async {
    try {
      final rows = await _sb.from(source).select('id');
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  String _t(String key) => AppLocalizations.of(context)?.translate(key) ?? key;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isArabic = locale == 'ar';
    final textDirection = isArabic ? TextDirection.rtl : TextDirection.ltr;
    final titles = _titleKeys.map(_t).toList();
    final List<Widget> pages = [
      _AdminOverview(
        countRows: _countRows,
        onOpenSection: (index) => setState(() => _selectedIndex = index),
      ),
      const WebAdminStoresScreen(isEmbedded: true),
      const WebAdminCouponsScreen(isEmbedded: true),
      const WebAdminOffersScreen(isEmbedded: true),
      const AdminCategoriesScreen(isEmbedded: true),
      const WebAdminCarouselScreen(isEmbedded: true),
      const AdminPendingCouponsScreen(isEmbedded: true),
      const WebAdminNotificationsScreen(isEmbedded: true),
      const WebAdminCouponProvidersScreen(),
    ];

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
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
                  left: BorderSide(color: Colors.grey[200]!),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: Offset(isArabic ? -2 : 2, 0),
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
                        Text(
                          _t('admin_panel'),
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
                      itemCount: titles.length,
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
                                      titles[index],
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
                      _version.isEmpty ? '' : '${_t('version')} $_version',
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

class _CouponPerformanceItem {
  final String couponId;
  final String code;
  final String storeName;
  final String value;
  final String subtitle;

  const _CouponPerformanceItem({
    required this.couponId,
    required this.code,
    required this.storeName,
    required this.value,
    required this.subtitle,
  });
}

class _CouponPerformanceSnapshot {
  final List<_CouponPerformanceItem> mostCopiedCoupons;
  final List<_CouponPerformanceItem> mostVisitedCoupons;
  final List<_CouponPerformanceItem> mostSharedCoupons;
  final List<_CouponPerformanceItem> recentlyUsedCoupons;
  final List<_CouponPerformanceItem> staleCoupons;
  final List<_CouponPerformanceItem> notWorkingCoupons;

  const _CouponPerformanceSnapshot({
    required this.mostCopiedCoupons,
    required this.mostVisitedCoupons,
    required this.mostSharedCoupons,
    required this.recentlyUsedCoupons,
    required this.staleCoupons,
    required this.notWorkingCoupons,
  });
}

class _StorePerformanceItem {
  final String storeName;
  final String value;
  final String subtitle;

  const _StorePerformanceItem({
    required this.storeName,
    required this.value,
    required this.subtitle,
  });
}

class _UserFavoriteItem {
  final String title;
  final String value;
  final String subtitle;

  const _UserFavoriteItem({
    required this.title,
    required this.value,
    required this.subtitle,
  });
}

class _AdminAttentionItem {
  final String title;
  final String subtitle;
  final int count;
  final IconData icon;
  final Color color;
  final int? sectionIndex;

  const _AdminAttentionItem({
    required this.title,
    required this.subtitle,
    required this.count,
    required this.icon,
    required this.color,
    this.sectionIndex,
  });
}

class _OverviewData {
  final int stores;
  final int coupons;
  final int offers;
  final int categories;
  final int carousel;
  final int pending;
  final int notifications;
  final int couponProviders;
  final int couponCopies;
  final int offerCopies;
  final int storeClicks;
  final int activeItems;
  final int users;
  final int activeCoupons;
  final int expiredOrInactiveCoupons;
  final int pendingStores;
  final int copiesToday;
  final int copiesThisWeek;
  final int copiesThisMonth;
  final List<_CouponPerformanceItem> mostCopiedCoupons;
  final List<_CouponPerformanceItem> mostVisitedCoupons;
  final List<_CouponPerformanceItem> mostSharedCoupons;
  final List<_CouponPerformanceItem> recentlyUsedCoupons;
  final List<_CouponPerformanceItem> staleCoupons;
  final List<_CouponPerformanceItem> notWorkingCoupons;
  final _CouponPerformanceSnapshot performanceToday;
  final _CouponPerformanceSnapshot performanceThisWeek;
  final _CouponPerformanceSnapshot performanceThisMonth;
  final List<_StorePerformanceItem> mostFollowedStores;
  final List<_StorePerformanceItem> storesWithMostCouponCopies;
  final List<_StorePerformanceItem> storesWithMostCouponVisits;
  final List<_StorePerformanceItem> storesWithoutActiveCoupons;
  final List<_StorePerformanceItem> storesNeedingUpdate;
  final List<_StorePerformanceItem> storesByInteraction;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int activeUsers;
  final int followedStores;
  final double averageFavoritesPerUser;
  final int returningUsersRate;
  final List<_UserFavoriteItem> mostFavoritedItems;
  final List<_AdminAttentionItem> attentionItems;

  const _OverviewData({
    required this.stores,
    required this.coupons,
    required this.offers,
    required this.categories,
    required this.carousel,
    required this.pending,
    required this.notifications,
    required this.couponProviders,
    required this.couponCopies,
    required this.offerCopies,
    required this.storeClicks,
    required this.activeItems,
    required this.users,
    required this.activeCoupons,
    required this.expiredOrInactiveCoupons,
    required this.pendingStores,
    required this.copiesToday,
    required this.copiesThisWeek,
    required this.copiesThisMonth,
    required this.mostCopiedCoupons,
    required this.mostVisitedCoupons,
    required this.mostSharedCoupons,
    required this.recentlyUsedCoupons,
    required this.staleCoupons,
    required this.notWorkingCoupons,
    required this.performanceToday,
    required this.performanceThisWeek,
    required this.performanceThisMonth,
    required this.mostFollowedStores,
    required this.storesWithMostCouponCopies,
    required this.storesWithMostCouponVisits,
    required this.storesWithoutActiveCoupons,
    required this.storesNeedingUpdate,
    required this.storesByInteraction,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.activeUsers,
    required this.followedStores,
    required this.averageFavoritesPerUser,
    required this.returningUsersRate,
    required this.mostFavoritedItems,
    required this.attentionItems,
  });

  factory _OverviewData.empty() {
    return const _OverviewData(
      stores: 0,
      coupons: 0,
      offers: 0,
      categories: 0,
      carousel: 0,
      pending: 0,
      notifications: 0,
      couponProviders: 0,
      couponCopies: 0,
      offerCopies: 0,
      storeClicks: 0,
      activeItems: 0,
      users: 0,
      activeCoupons: 0,
      expiredOrInactiveCoupons: 0,
      pendingStores: 0,
      copiesToday: 0,
      copiesThisWeek: 0,
      copiesThisMonth: 0,
      mostCopiedCoupons: <_CouponPerformanceItem>[],
      mostVisitedCoupons: <_CouponPerformanceItem>[],
      mostSharedCoupons: <_CouponPerformanceItem>[],
      recentlyUsedCoupons: <_CouponPerformanceItem>[],
      staleCoupons: <_CouponPerformanceItem>[],
      notWorkingCoupons: <_CouponPerformanceItem>[],
      performanceToday: _CouponPerformanceSnapshot(
        mostCopiedCoupons: <_CouponPerformanceItem>[],
        mostVisitedCoupons: <_CouponPerformanceItem>[],
        mostSharedCoupons: <_CouponPerformanceItem>[],
        recentlyUsedCoupons: <_CouponPerformanceItem>[],
        staleCoupons: <_CouponPerformanceItem>[],
        notWorkingCoupons: <_CouponPerformanceItem>[],
      ),
      performanceThisWeek: _CouponPerformanceSnapshot(
        mostCopiedCoupons: <_CouponPerformanceItem>[],
        mostVisitedCoupons: <_CouponPerformanceItem>[],
        mostSharedCoupons: <_CouponPerformanceItem>[],
        recentlyUsedCoupons: <_CouponPerformanceItem>[],
        staleCoupons: <_CouponPerformanceItem>[],
        notWorkingCoupons: <_CouponPerformanceItem>[],
      ),
      performanceThisMonth: _CouponPerformanceSnapshot(
        mostCopiedCoupons: <_CouponPerformanceItem>[],
        mostVisitedCoupons: <_CouponPerformanceItem>[],
        mostSharedCoupons: <_CouponPerformanceItem>[],
        recentlyUsedCoupons: <_CouponPerformanceItem>[],
        staleCoupons: <_CouponPerformanceItem>[],
        notWorkingCoupons: <_CouponPerformanceItem>[],
      ),
      mostFollowedStores: <_StorePerformanceItem>[],
      storesWithMostCouponCopies: <_StorePerformanceItem>[],
      storesWithMostCouponVisits: <_StorePerformanceItem>[],
      storesWithoutActiveCoupons: <_StorePerformanceItem>[],
      storesNeedingUpdate: <_StorePerformanceItem>[],
      storesByInteraction: <_StorePerformanceItem>[],
      newUsersToday: 0,
      newUsersThisWeek: 0,
      activeUsers: 0,
      followedStores: 0,
      averageFavoritesPerUser: 0,
      returningUsersRate: 0,
      mostFavoritedItems: <_UserFavoriteItem>[],
      attentionItems: <_AdminAttentionItem>[],
    );
  }

  factory _OverviewData.fromRows({
    required List<int> counts,
    required List<dynamic> events,
    required List<dynamic> usageEvents,
    required List<dynamic> couponStatusReports,
    required List<dynamic> couponRows,
    required List<dynamic> offerRows,
    required List<dynamic> storeRows,
    required List<dynamic> storeFollowRows,
    required List<dynamic> userRows,
    required List<dynamic> favoriteRows,
    required bool isArabic,
  }) {
    var couponCopies = 0;
    var offerCopies = 0;
    var storeClicks = 0;
    var copiesToday = 0;
    var copiesThisWeek = 0;
    var copiesThisMonth = 0;
    final activeItemKeys = <String>{};
    final usageCopyCounts = <String, int>{};
    final usageVisitCounts = <String, int>{};
    final usageShareCounts = <String, int>{};
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart =
        todayStart.subtract(Duration(days: todayStart.weekday - 1));
    final monthStart = DateTime(now.year, now.month);
    final expiringSoonLimit = now.add(const Duration(days: 14));

    for (final event in events) {
      if (event is! Map) continue;
      final eventType = event['event_type']?.toString() ?? '';
      final itemType = event['item_type']?.toString() ?? '';
      final itemId = event['item_id']?.toString() ?? '';
      final createdAt =
          DateTime.tryParse(event['created_at']?.toString() ?? '')?.toLocal();
      final isCopyEvent =
          eventType == 'coupon_copy' || eventType == 'offer_copy';

      if (eventType == 'coupon_copy') {
        couponCopies++;
      }
      if (eventType == 'offer_copy') offerCopies++;
      if (eventType == 'store_click') storeClicks++;
      if (isCopyEvent && createdAt != null) {
        if (!createdAt.isBefore(todayStart)) copiesToday++;
        if (!createdAt.isBefore(weekStart)) copiesThisWeek++;
        if (!createdAt.isBefore(monthStart)) copiesThisMonth++;
      }
      if (itemType.isNotEmpty && itemId.isNotEmpty) {
        activeItemKeys.add('$itemType:$itemId');
      }
    }

    final couponsById = <String, Map<dynamic, dynamic>>{};
    final couponsByLookupKey = <String, Map<dynamic, dynamic>>{};
    final offersById = <String, Map<dynamic, dynamic>>{};
    final storeNamesByKey = <String, String>{};
    final storeRowsByKey = <String, Map<dynamic, dynamic>>{};
    final activeCouponCountByStore = <String, int>{};
    var expiredOrInactiveCoupons = 0;
    var activeCoupons = 0;
    var expiringSoonCoupons = 0;
    var couponsWithoutImage = 0;

    for (final row in storeRows) {
      if (row is! Map) continue;
      final id = row['id']?.toString().trim() ?? '';
      final slug = row['slug']?.toString().trim() ?? '';
      final name = isArabic
          ? (row['name_ar'] ?? row['name'] ?? '').toString()
          : (row['name_en'] ?? row['name'] ?? '').toString();
      final fallbackName = (row['name'] ?? '').toString();
      final displayName = name.trim().isNotEmpty ? name.trim() : fallbackName;
      if (id.isNotEmpty) storeNamesByKey[id.toLowerCase()] = displayName;
      if (slug.isNotEmpty) storeNamesByKey[slug.toLowerCase()] = displayName;
      if (id.isNotEmpty) storeRowsByKey[id.toLowerCase()] = row;
      if (slug.isNotEmpty) storeRowsByKey[slug.toLowerCase()] = row;
    }

    for (final row in couponRows) {
      if (row is! Map) continue;
      final id = row['id']?.toString() ?? '';
      final code = row['code']?.toString().trim() ?? '';
      if (id.isNotEmpty) {
        couponsById[id] = row;
        couponsByLookupKey[id.toLowerCase()] = row;
      }
      if (code.isNotEmpty) {
        couponsByLookupKey[code.toLowerCase()] = row;
      }

      final isActiveRaw = row['is_active'];
      final isActive = isActiveRaw == null
          ? true
          : isActiveRaw == true ||
              isActiveRaw.toString().toLowerCase().trim() == 'true';

      final expiry = DateTime.tryParse(row['expiry_date']?.toString() ?? '');
      final isExpired = expiry != null && expiry.isBefore(now);
      final image = row['image']?.toString().trim() ?? '';
      if (image.isEmpty) couponsWithoutImage++;
      if (expiry != null &&
          expiry.isAfter(now) &&
          expiry.isBefore(expiringSoonLimit)) {
        expiringSoonCoupons++;
      }
      if (isActive && !isExpired) {
        activeCoupons++;
        final storeId = row['store_id']?.toString().trim().toLowerCase() ?? '';
        if (storeId.isNotEmpty) {
          activeCouponCountByStore[storeId] =
              (activeCouponCountByStore[storeId] ?? 0) + 1;
        }
      }
      if (!isActive || isExpired) {
        expiredOrInactiveCoupons++;
      }
    }

    for (final row in offerRows) {
      if (row is! Map) continue;
      final id = row['id']?.toString().trim() ?? '';
      if (id.isNotEmpty) offersById[id] = row;
    }

    var offersWithMissingDetails = 0;
    for (final row in offerRows) {
      if (row is! Map) continue;
      final link = row['web']?.toString().trim() ?? '';
      final description = [
        row['description'],
        row['description_ar'],
        row['description_en'],
      ].map((value) => value?.toString().trim() ?? '').join();
      if (link.isEmpty || description.isEmpty) offersWithMissingDetails++;
    }

    for (final event in usageEvents) {
      if (event is! Map) continue;
      final couponId = event['coupon_id']?.toString() ?? '';
      if (couponId.isEmpty) continue;
      final eventType = event['event_type']?.toString() ?? '';
      if (eventType == 'copy') {
        usageCopyCounts[couponId] = (usageCopyCounts[couponId] ?? 0) + 1;
      } else if (eventType == 'shop_now') {
        usageVisitCounts[couponId] = (usageVisitCounts[couponId] ?? 0) + 1;
      } else if (eventType == 'share') {
        usageShareCounts[couponId] = (usageShareCounts[couponId] ?? 0) + 1;
      }
    }

    var pendingStores = 0;
    var storesWithoutLogo = 0;
    var importedStoresPending = 0;
    for (final row in storeRows) {
      if (row is! Map) continue;
      final approvalStatus =
          (row['approval_status'] ?? 'approved').toString().trim();
      final image = row['image']?.toString().trim() ?? '';
      final importSource =
          (row['import_source'] ?? 'manual').toString().trim().toLowerCase();
      if (approvalStatus == 'waiting_approval') pendingStores++;
      if (image.isEmpty) storesWithoutLogo++;
      if (approvalStatus == 'waiting_approval' && importSource != 'manual') {
        importedStoresPending++;
      }
    }

    final followCountsByStore = <String, int>{};
    for (final row in storeFollowRows) {
      if (row is! Map) continue;
      final storeId = row['store_id']?.toString().trim().toLowerCase() ?? '';
      if (storeId.isEmpty) continue;
      followCountsByStore[storeId] = (followCountsByStore[storeId] ?? 0) + 1;
    }

    String storeNameFor(Map<dynamic, dynamic>? row) {
      final storeId = row?['store_id']?.toString().trim().toLowerCase() ?? '';
      return (storeNamesByKey[storeId] ?? '').trim();
    }

    Map<dynamic, dynamic>? couponRowFor(String couponId) {
      final normalized = couponId.trim().toLowerCase();
      return couponsById[couponId] ?? couponsByLookupKey[normalized];
    }

    _CouponPerformanceItem itemFor(
      String couponId,
      String value,
      String subtitle,
    ) {
      final row = couponRowFor(couponId);
      final code = row?['code']?.toString().trim() ?? '';
      final storeName = storeNameFor(row);
      return _CouponPerformanceItem(
        couponId: couponId,
        code: code.isEmpty ? couponId : code,
        storeName: storeName,
        value: value,
        subtitle: subtitle,
      );
    }

    List<_CouponPerformanceItem> topFromCounts(
      Map<String, int> source,
      String unit,
    ) {
      final entries = source.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries
          .take(5)
          .map((entry) => itemFor(entry.key, '${entry.value}', unit))
          .where((item) => item.storeName.isNotEmpty && item.code.isNotEmpty)
          .toList();
    }

    final recentlyUsedRows = couponRows.whereType<Map>().toList()
      ..sort((a, b) {
        final aDate = DateTime.tryParse(a['last_used_at']?.toString() ?? '');
        final bDate = DateTime.tryParse(b['last_used_at']?.toString() ?? '');
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

    final recentlyUsedCoupons = recentlyUsedRows
        .where((row) => row['last_used_at'] != null)
        .take(5)
        .map((row) {
      final id = row['id']?.toString() ?? '';
      final lastUsed = DateTime.tryParse(row['last_used_at'].toString());
      final days = lastUsed == null ? 0 : now.difference(lastUsed).inDays;
      return itemFor(id, days == 0 ? 'اليوم' : 'قبل $days يوم', 'آخر استخدام');
    }).toList();

    final staleBefore = now.subtract(const Duration(days: 60));
    final staleCoupons = couponRows
        .whereType<Map>()
        .where((row) {
          final lastUsed =
              DateTime.tryParse(row['last_used_at']?.toString() ?? '');
          return lastUsed == null || lastUsed.isBefore(staleBefore);
        })
        .take(5)
        .map((row) {
          final id = row['id']?.toString() ?? '';
          final lastUsed =
              DateTime.tryParse(row['last_used_at']?.toString() ?? '');
          final value = lastUsed == null
              ? 'لم يستخدم'
              : 'قبل ${now.difference(lastUsed).inDays} يوم';
          return itemFor(id, value, 'خامل');
        })
        .toList();

    final latestWorkingAtByCoupon = <String, DateTime>{};
    for (final report in couponStatusReports) {
      if (report is! Map) continue;
      final couponId = report['coupon_id']?.toString() ?? '';
      if (couponId.isEmpty) continue;
      if (report['status']?.toString() != 'working') continue;
      final createdAt =
          DateTime.tryParse(report['created_at']?.toString() ?? '')?.toLocal();
      if (createdAt == null) continue;
      final current = latestWorkingAtByCoupon[couponId];
      if (current == null || createdAt.isAfter(current)) {
        latestWorkingAtByCoupon[couponId] = createdAt;
      }
    }
    for (final event in events) {
      if (event is! Map) continue;
      if (event['event_type']?.toString() != 'coupon_status_working') {
        continue;
      }
      final couponId = event['item_id']?.toString() ?? '';
      if (couponId.isEmpty) continue;
      final createdAt =
          DateTime.tryParse(event['created_at']?.toString() ?? '')?.toLocal();
      if (createdAt == null) continue;
      final current = latestWorkingAtByCoupon[couponId];
      if (current == null || createdAt.isAfter(current)) {
        latestWorkingAtByCoupon[couponId] = createdAt;
      }
    }

    final notWorkingReportCounts = <String, int>{};
    for (final report in couponStatusReports) {
      if (report is! Map) continue;
      if (report['status']?.toString() != 'not_working') continue;
      final couponId = report['coupon_id']?.toString() ?? '';
      if (couponId.isEmpty) continue;
      final createdAt =
          DateTime.tryParse(report['created_at']?.toString() ?? '')?.toLocal();
      final latestWorkingAt = latestWorkingAtByCoupon[couponId];
      if (createdAt != null &&
          latestWorkingAt != null &&
          !createdAt.isAfter(latestWorkingAt)) {
        continue;
      }
      notWorkingReportCounts[couponId] =
          (notWorkingReportCounts[couponId] ?? 0) + 1;
    }
    for (final event in events) {
      if (event is! Map) continue;
      if (event['event_type']?.toString() != 'coupon_status_not_working') {
        continue;
      }
      final couponId = event['item_id']?.toString() ?? '';
      if (couponId.isEmpty) continue;
      final createdAt =
          DateTime.tryParse(event['created_at']?.toString() ?? '')?.toLocal();
      final latestWorkingAt = latestWorkingAtByCoupon[couponId];
      if (createdAt != null &&
          latestWorkingAt != null &&
          !createdAt.isAfter(latestWorkingAt)) {
        continue;
      }
      notWorkingReportCounts[couponId] =
          (notWorkingReportCounts[couponId] ?? 0) + 1;
    }

    final notWorkingCoupons = notWorkingReportCounts.isNotEmpty
        ? topFromCounts(notWorkingReportCounts, 'بلاغ لا يعمل')
        : couponRows
            .whereType<Map>()
            .where((row) {
              final isActiveRaw = row['is_active'];
              return !(isActiveRaw == null ||
                  isActiveRaw == true ||
                  isActiveRaw.toString().toLowerCase().trim() == 'true');
            })
            .take(5)
            .map((row) {
              final id = row['id']?.toString() ?? '';
              return itemFor(id, 'لا يعمل', 'حالة قديمة');
            })
            .toList();

    Map<String, int> usageCountsSince(String type, DateTime start) {
      final counts = <String, int>{};
      for (final event in usageEvents) {
        if (event is! Map) continue;
        if (event['event_type']?.toString() != type) continue;
        final createdAt =
            DateTime.tryParse(event['created_at']?.toString() ?? '')?.toLocal();
        if (createdAt == null || createdAt.isBefore(start)) continue;
        final couponId = event['coupon_id']?.toString() ?? '';
        if (couponId.isEmpty) continue;
        counts[couponId] = (counts[couponId] ?? 0) + 1;
      }
      return counts;
    }

    List<_CouponPerformanceItem> recentlyUsedSince(DateTime start) {
      return recentlyUsedRows
          .where((row) {
            final lastUsed =
                DateTime.tryParse(row['last_used_at']?.toString() ?? '')
                    ?.toLocal();
            return lastUsed != null && !lastUsed.isBefore(start);
          })
          .take(5)
          .map((row) {
            final id = row['id']?.toString() ?? '';
            final lastUsed =
                DateTime.tryParse(row['last_used_at'].toString())?.toLocal();
            final days = lastUsed == null ? 0 : now.difference(lastUsed).inDays;
            return itemFor(
              id,
              days == 0 ? 'اليوم' : 'قبل $days يوم',
              'آخر استخدام',
            );
          })
          .toList();
    }

    _CouponPerformanceSnapshot snapshotSince(DateTime start) {
      return _CouponPerformanceSnapshot(
        mostCopiedCoupons:
            topFromCounts(usageCountsSince('copy', start), 'نسخ'),
        mostVisitedCoupons:
            topFromCounts(usageCountsSince('shop_now', start), 'زيارة'),
        mostSharedCoupons:
            topFromCounts(usageCountsSince('share', start), 'مشاركة'),
        recentlyUsedCoupons: recentlyUsedSince(start),
        staleCoupons: staleCoupons,
        notWorkingCoupons: notWorkingCoupons,
      );
    }

    String storeNameByKey(String key) {
      return (storeNamesByKey[key.trim().toLowerCase()] ?? '').trim();
    }

    String? storeKeyForCouponId(String couponId) {
      final row = couponRowFor(couponId);
      final storeId = row?['store_id']?.toString().trim().toLowerCase() ?? '';
      return storeId.isEmpty ? null : storeId;
    }

    Map<String, int> storeCountsFromCouponCounts(Map<String, int> source) {
      final result = <String, int>{};
      for (final entry in source.entries) {
        final storeKey = storeKeyForCouponId(entry.key);
        if (storeKey == null) continue;
        result[storeKey] = (result[storeKey] ?? 0) + entry.value;
      }
      return result;
    }

    List<_StorePerformanceItem> topStoresFromCounts(
      Map<String, int> source,
      String unit,
    ) {
      final entries = source.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return entries
          .take(5)
          .map((entry) {
            final storeName = storeNameByKey(entry.key);
            return _StorePerformanceItem(
              storeName: storeName,
              value: '${entry.value}',
              subtitle: unit,
            );
          })
          .where((item) => item.storeName.isNotEmpty)
          .toList();
    }

    final storeCopyCounts = storeCountsFromCouponCounts(usageCopyCounts);
    final storeVisitCounts = storeCountsFromCouponCounts(usageVisitCounts);
    final storeInteractionCounts = <String, int>{};
    for (final key in {
      ...followCountsByStore.keys,
      ...storeCopyCounts.keys,
      ...storeVisitCounts.keys,
    }) {
      storeInteractionCounts[key] = (followCountsByStore[key] ?? 0) +
          (storeCopyCounts[key] ?? 0) +
          (storeVisitCounts[key] ?? 0);
    }

    final storesWithoutActiveCoupons = storeRows
        .whereType<Map>()
        .where((row) {
          final id = row['id']?.toString().trim().toLowerCase() ?? '';
          final slug = row['slug']?.toString().trim().toLowerCase() ?? '';
          final count = (activeCouponCountByStore[id] ?? 0) +
              (activeCouponCountByStore[slug] ?? 0);
          return count == 0;
        })
        .take(5)
        .map((row) {
          final key = (row['slug'] ?? row['id'] ?? '').toString();
          return _StorePerformanceItem(
            storeName: storeNameByKey(key),
            value: '0',
            subtitle: 'كوبون فعال',
          );
        })
        .where((item) => item.storeName.isNotEmpty)
        .toList();

    final storesNeedingUpdate = storeRows
        .whereType<Map>()
        .where((row) {
          final image = row['image']?.toString().trim() ?? '';
          final approvalStatus =
              (row['approval_status'] ?? 'approved').toString().trim();
          return image.isEmpty || approvalStatus == 'waiting_approval';
        })
        .take(5)
        .map((row) {
          final key = (row['slug'] ?? row['id'] ?? '').toString();
          final image = row['image']?.toString().trim() ?? '';
          return _StorePerformanceItem(
            storeName: storeNameByKey(key),
            value: image.isEmpty ? 'شعار' : 'مراجعة',
            subtitle: 'يحتاج تحديث',
          );
        })
        .where((item) => item.storeName.isNotEmpty)
        .toList();

    var newUsersToday = 0;
    var newUsersThisWeek = 0;
    for (final row in userRows) {
      if (row is! Map) continue;
      final createdAt =
          DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal();
      if (createdAt == null) continue;
      if (!createdAt.isBefore(todayStart)) newUsersToday++;
      if (!createdAt.isBefore(weekStart)) newUsersThisWeek++;
    }

    final activeUserIds = <String>{};
    final userEventCounts = <String, int>{};
    for (final row in [...events, ...usageEvents]) {
      if (row is! Map) continue;
      final userId = row['user_id']?.toString().trim() ?? '';
      if (userId.isEmpty) continue;
      activeUserIds.add(userId);
      userEventCounts[userId] = (userEventCounts[userId] ?? 0) + 1;
    }
    final returningUsers =
        userEventCounts.values.where((count) => count > 1).length;
    final returningUsersRate = activeUserIds.isEmpty
        ? 0
        : ((returningUsers / activeUserIds.length) * 100).round();

    final favoriteCountsByItem = <String, int>{};
    final favoriteLabelsByItem = <String, String>{};
    final favoriteUsers = <String>{};
    Map<dynamic, dynamic>? asMap(dynamic value) {
      if (value is Map) return value;
      if (value is String && value.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is Map) return decoded;
        } catch (_) {}
      }
      return null;
    }

    String firstText(Map<dynamic, dynamic>? data, List<String> keys) {
      if (data == null) return '';
      for (final key in keys) {
        final value = data[key]?.toString().trim() ?? '';
        if (value.isNotEmpty) return value;
      }
      return '';
    }

    String favoriteLabel({
      required String itemId,
      required String itemType,
      required dynamic itemData,
    }) {
      final data = asMap(itemData);
      final localizedKeys = isArabic
          ? [
              'store_name_ar',
              'storeNameAr',
              'name_ar',
              'nameAr',
              'store_name',
              'storeName',
              'name',
            ]
          : [
              'store_name_en',
              'storeNameEn',
              'name_en',
              'nameEn',
              'store_name',
              'storeName',
              'name',
            ];
      final fromData = firstText(data, localizedKeys);
      if (fromData.isNotEmpty) return fromData;

      if (itemType == 'coupon') {
        final row = couponRowFor(itemId);
        final storeName = storeNameFor(row);
        if (storeName.isNotEmpty) return storeName;
        return firstText(row, localizedKeys);
      }
      if (itemType == 'offer') {
        final row = offersById[itemId];
        final storeId = row?['store_id']?.toString().trim().toLowerCase() ?? '';
        final storeName = storeNameByKey(storeId);
        if (storeName.isNotEmpty) return storeName;
        return firstText(row, localizedKeys);
      }

      return itemId.length > 10 ? itemId.substring(0, 10) : itemId;
    }

    for (final row in favoriteRows) {
      if (row is! Map) continue;
      final itemId = row['item_id']?.toString().trim() ?? '';
      if (itemId.isEmpty) continue;
      final itemType = row['item_type']?.toString().trim() ?? '';
      favoriteCountsByItem[itemId] = (favoriteCountsByItem[itemId] ?? 0) + 1;
      final userId = row['user_id']?.toString().trim() ?? '';
      if (userId.isNotEmpty) favoriteUsers.add(userId);
      if (!favoriteLabelsByItem.containsKey(itemId)) {
        favoriteLabelsByItem[itemId] = favoriteLabel(
          itemId: itemId,
          itemType: itemType,
          itemData: row['item_data'],
        );
      }
    }
    final mostFavoritedItems = favoriteCountsByItem.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topFavoritedItems = mostFavoritedItems.take(5).map((entry) {
      return _UserFavoriteItem(
        title: favoriteLabelsByItem[entry.key] ?? entry.key,
        value: '${entry.value}',
        subtitle: 'إضافة',
      );
    }).toList();
    final averageFavoritesPerUser = favoriteUsers.isEmpty
        ? 0.0
        : favoriteRows.length / favoriteUsers.length;
    final attentionItems = <_AdminAttentionItem>[
      _AdminAttentionItem(
        title: 'كوبونات منتهية قريبًا',
        subtitle: 'تنتهي خلال 14 يومًا',
        count: expiringSoonCoupons,
        icon: Icons.timer_rounded,
        color: const Color(0xFFF59E0B),
        sectionIndex: 2,
      ),
      _AdminAttentionItem(
        title: 'كوبونات بدون صورة',
        subtitle: 'تحتاج صورة واضحة',
        count: couponsWithoutImage,
        icon: Icons.image_not_supported_rounded,
        color: const Color(0xFF7C3AED),
        sectionIndex: 2,
      ),
      _AdminAttentionItem(
        title: 'متاجر بدون شعار',
        subtitle: 'أكمل هوية المتجر',
        count: storesWithoutLogo,
        icon: Icons.store_mall_directory_rounded,
        color: const Color(0xFF0284C7),
        sectionIndex: 1,
      ),
      _AdminAttentionItem(
        title: 'متاجر مستوردة تنتظر الموافقة',
        subtitle: 'تحتاج مراجعة واعتماد',
        count: importedStoresPending,
        icon: Icons.fact_check_rounded,
        color: Constants.primaryColor,
        sectionIndex: 1,
      ),
      _AdminAttentionItem(
        title: 'كوبونات كثيرة لا تعمل',
        subtitle: 'غير فعالة أو منتهية',
        count: expiredOrInactiveCoupons,
        icon: Icons.report_problem_rounded,
        color: const Color(0xFFE11D48),
        sectionIndex: 2,
      ),
      _AdminAttentionItem(
        title: 'عروض بدون رابط أو وصف ناقص',
        subtitle: 'أكمل تفاصيل العرض',
        count: offersWithMissingDetails,
        icon: Icons.link_off_rounded,
        color: const Color(0xFF0EA5A4),
        sectionIndex: 3,
      ),
    ];

    return _OverviewData(
      stores: counts[0],
      coupons: counts[1],
      offers: counts[2],
      categories: counts[3],
      carousel: counts[4],
      pending: counts[5],
      notifications: counts[6],
      couponProviders: counts[7],
      users: counts[8],
      couponCopies: couponCopies,
      offerCopies: offerCopies,
      storeClicks: storeClicks,
      activeItems: activeItemKeys.length,
      activeCoupons: activeCoupons,
      expiredOrInactiveCoupons: expiredOrInactiveCoupons,
      pendingStores: pendingStores,
      copiesToday: copiesToday,
      copiesThisWeek: copiesThisWeek,
      copiesThisMonth: copiesThisMonth,
      mostCopiedCoupons: topFromCounts(usageCopyCounts, 'نسخ'),
      mostVisitedCoupons: topFromCounts(usageVisitCounts, 'زيارة'),
      mostSharedCoupons: topFromCounts(usageShareCounts, 'مشاركة'),
      recentlyUsedCoupons: recentlyUsedCoupons,
      staleCoupons: staleCoupons,
      notWorkingCoupons: notWorkingCoupons,
      performanceToday: snapshotSince(todayStart),
      performanceThisWeek: snapshotSince(weekStart),
      performanceThisMonth: snapshotSince(monthStart),
      mostFollowedStores: topStoresFromCounts(followCountsByStore, 'متابع'),
      storesWithMostCouponCopies: topStoresFromCounts(storeCopyCounts, 'نسخ'),
      storesWithMostCouponVisits:
          topStoresFromCounts(storeVisitCounts, 'زيارة'),
      storesWithoutActiveCoupons: storesWithoutActiveCoupons,
      storesNeedingUpdate: storesNeedingUpdate,
      storesByInteraction: topStoresFromCounts(storeInteractionCounts, 'تفاعل'),
      newUsersToday: newUsersToday,
      newUsersThisWeek: newUsersThisWeek,
      activeUsers: activeUserIds.length,
      followedStores: storeFollowRows.length,
      averageFavoritesPerUser: averageFavoritesPerUser,
      returningUsersRate: returningUsersRate,
      mostFavoritedItems: topFavoritedItems,
      attentionItems: attentionItems,
    );
  }
}

class _AdminOverview extends StatefulWidget {
  final Future<int> Function(String source) countRows;
  final ValueChanged<int> onOpenSection;

  const _AdminOverview({
    required this.countRows,
    required this.onOpenSection,
  });

  @override
  State<_AdminOverview> createState() => _AdminOverviewState();
}

class _AdminOverviewState extends State<_AdminOverview> {
  Future<_OverviewData> _dataFuture = Future.value(_OverviewData.empty());
  bool _didLoadData = false;
  int _selectedOverviewPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didLoadData) return;
    _didLoadData = true;
    _dataFuture = _loadData(context);
  }

  void _refreshData() {
    setState(() {
      _dataFuture = _loadData(context);
    });
  }

  Future<_OverviewData> _loadData(BuildContext context) async {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final counts = await Future.wait([
      widget.countRows('stores'),
      widget.countRows('coupons'),
      widget.countRows('offers'),
      widget.countRows('categories'),
      widget.countRows('carousel'),
      widget.countRows('admin_pending_coupons'),
      widget.countRows('notifications'),
      widget.countRows('coupon_providers'),
      widget.countRows('users'),
    ]);

    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 30))
        .toIso8601String();

    List<dynamic> events = const [];
    List<dynamic> usageEvents = const [];
    List<dynamic> couponStatusReports = const [];
    try {
      events = await Supabase.instance.client
          .from('analytics_events')
          .select('event_type,item_type,item_id,store_id,user_id,created_at')
          .gte('created_at', since);
    } catch (_) {
      events = const [];
    }
    try {
      usageEvents = await Supabase.instance.client
          .from('coupon_usage_events')
          .select('coupon_id,event_type,user_id,created_at')
          .gte('created_at', since);
    } catch (_) {
      usageEvents = const [];
    }
    try {
      couponStatusReports = await Supabase.instance.client
          .from('coupon_status_reports')
          .select('coupon_id,status,user_id,created_at')
          .gte('created_at', since);
    } catch (_) {
      couponStatusReports = const [];
    }

    List<dynamic> couponRows = const [];
    List<dynamic> offerRows = const [];
    List<dynamic> storeRows = const [];
    List<dynamic> storeFollowRows = const [];
    List<dynamic> userRows = const [];
    List<dynamic> favoriteRows = const [];
    try {
      couponRows = await Supabase.instance.client
          .from('coupons')
          .select('id,code,store_id,image,is_active,expiry_date,last_used_at');
    } catch (_) {
      couponRows = const [];
    }
    try {
      offerRows = await Supabase.instance.client.from('offers').select(
          'id,store_id,name,name_ar,name_en,store_name,store_name_ar,store_name_en,web,description,description_ar,description_en');
    } catch (_) {
      offerRows = const [];
    }
    try {
      storeRows = await Supabase.instance.client.from('stores').select(
          'id,slug,name,name_ar,name_en,image,approval_status,import_source');
    } catch (_) {
      storeRows = const [];
    }
    try {
      storeFollowRows = await Supabase.instance.client
          .from('store_follows')
          .select('store_id');
    } catch (_) {
      storeFollowRows = const [];
    }
    try {
      userRows = await Supabase.instance.client
          .from('users')
          .select('id,uid,created_at');
    } catch (_) {
      userRows = const [];
    }
    try {
      favoriteRows = await Supabase.instance.client
          .from('favorites')
          .select('user_id,item_id,item_type,item_data,created_at');
    } catch (_) {
      favoriteRows = const [];
    }

    return _OverviewData.fromRows(
      counts: counts,
      events: events,
      usageEvents: usageEvents,
      couponStatusReports: couponStatusReports,
      couponRows: couponRows,
      offerRows: offerRows,
      storeRows: storeRows,
      storeFollowRows: storeFollowRows,
      userRows: userRows,
      favoriteRows: favoriteRows,
      isArabic: isArabic,
    );
  }

  Future<void> _clearNotWorkingReports(String couponId) async {
    final id = couponId.trim();
    if (id.isEmpty) return;

    Object? lastError;
    final sb = Supabase.instance.client;

    try {
      await sb
          .from('coupon_status_reports')
          .delete()
          .eq('coupon_id', id)
          .eq('status', 'not_working');
    } catch (error) {
      lastError = error;
      debugPrint('Failed to delete coupon_status_reports: $error');
    }

    try {
      await sb
          .from('analytics_events')
          .delete()
          .eq('event_type', 'coupon_status_not_working')
          .eq('item_type', 'coupon')
          .eq('item_id', id);
    } catch (error) {
      lastError = error;
      debugPrint('Failed to delete analytics_events report fallback: $error');
    }

    var markedFixed = false;
    try {
      await sb.from('coupon_status_reports').insert({
        'coupon_id': id,
        'user_id': sb.auth.currentUser?.id,
        'status': 'working',
      });
      markedFixed = true;
    } catch (error) {
      lastError = error;
      debugPrint('Failed to insert coupon_status_reports fix marker: $error');
    }

    try {
      await sb.from('analytics_events').insert({
        'event_type': 'coupon_status_working',
        'item_type': 'coupon',
        'item_id': id,
        'user_id': sb.auth.currentUser?.id,
      });
      markedFixed = true;
    } catch (error) {
      lastError = error;
      debugPrint('Failed to insert analytics_events fix marker: $error');
    }

    if (!mounted) return;
    if (!markedFixed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تعذر تأكيد إصلاح البلاغ: $lastError')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم حذف بلاغات الكوبون بعد الإصلاح'),
        backgroundColor: Color(0xFF16A34A),
      ),
    );
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewData>(
      future: _dataFuture,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _OverviewData.empty();
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final stores = data.stores;
        final coupons = data.coupons;
        final offers = data.offers;
        final categories = data.categories;
        final carousel = data.carousel;
        final pending = data.pending;
        final notifications = data.notifications;
        final couponProviders = data.couponProviders;
        final users = data.users;
        final copies = data.couponCopies + data.offerCopies;
        final clicks = data.storeClicks;
        final conversionRate =
            copies + clicks == 0 ? 0.0 : copies / (copies + clicks);
        final totalContent = coupons + offers;
        final approvalRate = coupons + pending == 0
            ? 1.0
            : coupons / (coupons + pending).clamp(1, 999999);
        final localizations = AppLocalizations.of(context);
        String t(String key) => localizations?.translate(key) ?? key;
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';

        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 28, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _OverviewHeader(
                  loading: loading,
                  totalContent: totalContent,
                  approvalRate: approvalRate,
                ),
                const SizedBox(height: 20),
                _OverviewPageTabs(
                  selectedIndex: _selectedOverviewPage,
                  onChanged: (index) {
                    setState(() => _selectedOverviewPage = index);
                  },
                ),
                const SizedBox(height: 18),
                if (_selectedOverviewPage == 0) ...[
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width < 720
                          ? 2
                          : width < 1150
                              ? 3
                              : 7;
                      return GridView.count(
                        crossAxisCount: crossAxisCount,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: width < 720 ? 1.55 : 1.45,
                        children: [
                          _MetricTile(
                            title: t('stores'),
                            value: stores,
                            subtitle: t('admin_stores_subtitle'),
                            icon: Icons.storefront_rounded,
                            color: const Color(0xFF0EA5A4),
                            onTap: () => widget.onOpenSection(1),
                          ),
                          _MetricTile(
                            title: t('coupons'),
                            value: coupons,
                            subtitle: t('admin_coupons_subtitle'),
                            icon: Icons.confirmation_number_rounded,
                            color: Constants.primaryColor,
                            onTap: () => widget.onOpenSection(2),
                          ),
                          _MetricTile(
                            title: t('offers'),
                            value: offers,
                            subtitle: t('admin_offers_subtitle'),
                            icon: Icons.local_offer_rounded,
                            color: const Color(0xFF0284C7),
                            onTap: () => widget.onOpenSection(3),
                          ),
                          _MetricTile(
                            title: t('admin_carousel_banner'),
                            value: carousel,
                            subtitle: t('admin_carousel_subtitle'),
                            icon: Icons.view_carousel_rounded,
                            color: const Color(0xFF0EA5A4),
                            onTap: () => widget.onOpenSection(5),
                          ),
                          _MetricTile(
                            title: t('categories'),
                            value: categories,
                            subtitle: t('admin_categories_subtitle'),
                            icon: Icons.category_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => widget.onOpenSection(4),
                          ),
                          _MetricTile(
                            title: 'متاجر بانتظار الموافقة',
                            value: data.pendingStores,
                            subtitle: 'تحتاج مراجعة',
                            icon: Icons.pending_actions_rounded,
                            color: const Color(0xFFE11D48),
                            onTap: () => widget.onOpenSection(1),
                          ),
                          _MetricTile(
                            title: 'الكوبونات الفعالة',
                            value: data.activeCoupons,
                            subtitle: 'فعالة وغير منتهية',
                            icon: Icons.verified_rounded,
                            color: const Color(0xFF16A34A),
                            onTap: () => widget.onOpenSection(2),
                          ),
                          _MetricTile(
                            title: 'منتهية أو غير فعالة',
                            value: data.expiredOrInactiveCoupons,
                            subtitle: 'تحتاج مراجعة',
                            icon: Icons.block_rounded,
                            color: const Color(0xFFF59E0B),
                            onTap: () => widget.onOpenSection(2),
                          ),
                          _MetricTile(
                            title: 'نسخ اليوم',
                            value: data.copiesToday,
                            subtitle: 'عمليات النسخ اليوم',
                            icon: Icons.today_rounded,
                            color: Constants.primaryColor,
                            onTap: () {},
                          ),
                          _MetricTile(
                            title: 'نسخ هذا الأسبوع',
                            value: data.copiesThisWeek,
                            subtitle: 'من بداية الأسبوع',
                            icon: Icons.date_range_rounded,
                            color: const Color(0xFF7C3AED),
                            onTap: () {},
                          ),
                          _MetricTile(
                            title: 'نسخ هذا الشهر',
                            value: data.copiesThisMonth,
                            subtitle: 'من بداية الشهر',
                            icon: Icons.calendar_month_rounded,
                            color: const Color(0xFF0EA5A4),
                            onTap: () {},
                          ),
                          _MetricTile(
                            title: 'المستخدمين',
                            value: users,
                            subtitle: 'حسابات المستخدمين',
                            icon: Icons.group_rounded,
                            color: const Color(0xFF10B981),
                            onTap: () {},
                          ),
                          _MetricTile(
                            title: t('admin_coupon_providers'),
                            value: couponProviders,
                            subtitle: t('admin_coupon_providers_subtitle'),
                            icon: Icons.business_center_outlined,
                            color: const Color(0xFF16A34A),
                            onTap: () => widget.onOpenSection(8),
                          ),
                          _MetricTile(
                            title: t('notifications'),
                            value: notifications,
                            subtitle: t('admin_notifications_subtitle'),
                            icon: Icons.notifications_active_rounded,
                            color: const Color(0xFF7C3AED),
                            onTap: () => widget.onOpenSection(7),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  _AdminAttentionSection(
                    items: data.attentionItems,
                    onOpenSection: widget.onOpenSection,
                  ),
                ] else if (_selectedOverviewPage == 1) ...[
                  const SizedBox(height: 22),
                  _CouponPerformanceSection(
                    data: data,
                    activeCoupons: data.activeCoupons,
                    inactiveCoupons: data.expiredOrInactiveCoupons,
                    onClearNotWorkingReport: _clearNotWorkingReports,
                  ),
                ] else if (_selectedOverviewPage == 2) ...[
                  const SizedBox(height: 22),
                  _StorePerformanceSection(data: data),
                ] else if (_selectedOverviewPage == 3) ...[
                  const SizedBox(height: 22),
                  _UserStatsSection(data: data),
                ] else ...[
                  _AnalyticsOverviewSection(
                    data: data,
                    conversionRate: conversionRate,
                    approvedCoupons: coupons,
                    pendingReviews: pending,
                    t: t,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  final bool loading;
  final int totalContent;
  final double approvalRate;

  const _OverviewHeader({
    required this.loading,
    required this.totalContent,
    required this.approvalRate,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    String t(String key) => localizations?.translate(key) ?? key;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.analytics_rounded, color: Constants.primaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('admin_performance_dashboard'),
                  style: const TextStyle(
                    fontSize: 22,
                    height: 1.35,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  t('admin_performance_subtitle'),
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'Tajawal',
                    color: Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
          ),
          if (loading)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Constants.primaryColor,
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$totalContent',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                    color: Colors.white,
                  ),
                ),
                Text(
                  t('admin_published_approval')
                      .replaceAll('{count}', '$totalContent')
                      .replaceAll(
                        '{rate}',
                        '${(approvalRate * 100).round()}',
                      ),
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'Tajawal',
                    color: Color(0xFFD1D5DB),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OverviewPageTabs extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _OverviewPageTabs({
    required this.selectedIndex,
    required this.onChanged,
  });

  static const _items = <_OverviewPageTabItem>[
    _OverviewPageTabItem('الملخص العام', Icons.dashboard_rounded),
    _OverviewPageTabItem('أداء الكوبونات', Icons.confirmation_number_rounded),
    _OverviewPageTabItem('أداء المتاجر', Icons.storefront_rounded),
    _OverviewPageTabItem('المستخدمون', Icons.group_rounded),
    _OverviewPageTabItem('التحليلات والإدارة', Icons.insights_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 920;
          final children = List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = selectedIndex == index;
            final button = _OverviewPageTabButton(
              label: item.label,
              icon: item.icon,
              selected: selected,
              onTap: () => onChanged(index),
            );
            return compact ? button : Expanded(child: button);
          });

          if (compact) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    SizedBox(width: 180, child: children[i]),
                  ],
                ],
              ),
            );
          }

          return Row(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                children[i],
              ],
            ],
          );
        },
      ),
    );
  }
}

class _OverviewPageTabItem {
  final String label;
  final IconData icon;

  const _OverviewPageTabItem(this.label, this.icon);
}

class _OverviewPageTabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _OverviewPageTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Constants.primaryColor.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? Constants.primaryColor.withValues(alpha: 0.28)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 19,
                color:
                    selected ? Constants.primaryColor : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? Constants.primaryColor
                        : const Color(0xFF374151),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final String title;
  final int value;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _MetricTile({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFE5E7EB)),
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, size: 16, color: color),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Tajawal',
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Tajawal',
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontFamily: 'Tajawal',
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Constants.primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(child: child),
        ],
      ),
    );
  }
}

enum _CouponPerformancePeriod { day, week, month }

class _CouponPerformanceSection extends StatefulWidget {
  final _OverviewData data;
  final int activeCoupons;
  final int inactiveCoupons;
  final Future<void> Function(String couponId) onClearNotWorkingReport;

  const _CouponPerformanceSection({
    required this.data,
    required this.activeCoupons,
    required this.inactiveCoupons,
    required this.onClearNotWorkingReport,
  });

  @override
  State<_CouponPerformanceSection> createState() =>
      _CouponPerformanceSectionState();
}

class _StorePerformanceSection extends StatelessWidget {
  final _OverviewData data;

  const _StorePerformanceSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final panels = <Widget>[
      _StorePerformanceListPanel(
        title: 'أكثر المتاجر متابعة',
        items: data.mostFollowedStores,
        emptyText: 'لا توجد متابعات متاجر',
      ),
      _StorePerformanceListPanel(
        title: 'أكثر المتاجر حصولًا على نسخ كوبونات',
        items: data.storesWithMostCouponCopies,
        emptyText: 'لا توجد نسخ كوبونات للمتاجر',
      ),
      _StorePerformanceListPanel(
        title: 'أكثر المتاجر زيارة من الكوبونات',
        items: data.storesWithMostCouponVisits,
        emptyText: 'لا توجد زيارات من الكوبونات',
      ),
      _StorePerformanceListPanel(
        title: 'المتاجر بدون كوبونات نشطة',
        items: data.storesWithoutActiveCoupons,
        emptyText: 'كل المتاجر لديها كوبونات نشطة',
      ),
      _StorePerformanceListPanel(
        title: 'المتاجر التي تحتاج تحديث',
        items: data.storesNeedingUpdate,
        emptyText: 'لا توجد متاجر تحتاج تحديث',
      ),
      _StorePerformanceListPanel(
        title: 'ترتيب المتاجر حسب التفاعل',
        items: data.storesByInteraction,
        emptyText: 'لا توجد تفاعلات متاجر',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(start: 2, bottom: 10),
          child: Text(
            'أداء المتاجر',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: Color(0xFF111827),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 760
                ? 1
                : width < 1180
                    ? 2
                    : 3;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: width < 760 ? 2.2 : 2.15,
              children: panels,
            );
          },
        ),
      ],
    );
  }
}

class _StorePerformanceListPanel extends StatelessWidget {
  final String title;
  final List<_StorePerformanceItem> items;
  final String emptyText;

  const _StorePerformanceListPanel({
    required this.title,
    required this.items,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      title: title,
      child: items.isEmpty
          ? _EmptyOverviewMessage(
              icon: Icons.storefront_rounded,
              text: emptyText,
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Constants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: Constants.primaryColor,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Tajawal',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.storeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Tajawal',
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SmallValueBadge(value: item.value, label: item.subtitle),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AdminAttentionSection extends StatelessWidget {
  final List<_AdminAttentionItem> items;
  final ValueChanged<int> onOpenSection;

  const _AdminAttentionSection({
    required this.items,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width < 760
            ? 1
            : width < 1180
                ? 2
                : 3;
        final tileHeight = width < 760 ? 82.0 : 92.0;
        if (items.isEmpty) {
          return const SizedBox(
            height: 180,
            child: _ChartPanel(
              title: 'يحتاج انتباهك',
              child: _EmptyOverviewMessage(
                icon: Icons.check_circle_outline_rounded,
                text: 'لا توجد عناصر تحتاج انتباهك الآن',
              ),
            ),
          );
        }

        final rows = (items.length / columns).ceil();
        final panelHeight = 62 + (rows * tileHeight) + ((rows - 1) * 10);

        return SizedBox(
          height: panelHeight.toDouble(),
          child: _ChartPanel(
            title: 'يحتاج انتباهك',
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: tileHeight,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: item.sectionIndex == null
                      ? null
                      : () => onOpenSection(item.sectionIndex!),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(item.icon, color: item.color, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Tajawal',
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'Tajawal',
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${item.count}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Tajawal',
                            color: item.count == 0
                                ? const Color(0xFF9CA3AF)
                                : item.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _UserStatsSection extends StatelessWidget {
  final _OverviewData data;

  const _UserStatsSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsetsDirectional.only(start: 2, bottom: 10),
          child: Text(
            'إحصائيات المستخدمين',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: Color(0xFF111827),
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final metricColumns = width < 720
                ? 2
                : width < 1150
                    ? 3
                    : 5;
            return GridView.count(
              crossAxisCount: metricColumns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: width < 720 ? 1.55 : 1.55,
              children: [
                _MetricTile(
                  title: 'مستخدمون جدد اليوم',
                  value: data.newUsersToday,
                  subtitle: 'تسجيلات اليوم',
                  icon: Icons.person_add_alt_1_rounded,
                  color: Constants.primaryColor,
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'مستخدمون جدد هذا الأسبوع',
                  value: data.newUsersThisWeek,
                  subtitle: 'من بداية الأسبوع',
                  icon: Icons.group_add_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'المستخدمون النشطون',
                  value: data.activeUsers,
                  subtitle: 'آخر 30 يومًا',
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF16A34A),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'المتاجر المتابعة',
                  value: data.followedStores,
                  subtitle: 'إجمالي المتابعات',
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFE11D48),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'معدل رجوع المستخدمين',
                  value: data.returningUsersRate,
                  subtitle: 'نسبة مئوية',
                  icon: Icons.repeat_rounded,
                  color: const Color(0xFF7C3AED),
                  onTap: () {},
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final favoritesPanel = _UserFavoritePanel(
              items: data.mostFavoritedItems,
            );
            final averagePanel = _AverageFavoritesPanel(
              value: data.averageFavoritesPerUser,
            );
            if (!wide) {
              return Column(
                children: [
                  SizedBox(height: 300, child: favoritesPanel),
                  const SizedBox(height: 10),
                  SizedBox(height: 220, child: averagePanel),
                ],
              );
            }
            return SizedBox(
              height: 300,
              child: Row(
                children: [
                  Expanded(flex: 2, child: favoritesPanel),
                  const SizedBox(width: 10),
                  Expanded(child: averagePanel),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UserFavoritePanel extends StatelessWidget {
  final List<_UserFavoriteItem> items;

  const _UserFavoritePanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      title: 'أكثر العناصر إضافة للمفضلة',
      child: items.isEmpty
          ? const _EmptyOverviewMessage(
              icon: Icons.favorite_border_rounded,
              text: 'لا توجد عناصر مفضلة حتى الآن',
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'Tajawal',
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _SmallValueBadge(value: item.value, label: item.subtitle),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _AverageFavoritesPanel extends StatelessWidget {
  final double value;

  const _AverageFavoritesPanel({required this.value});

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      title: 'متوسط عدد المفضلات لكل مستخدم',
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                color: Constants.primaryColor,
                fontSize: 42,
                fontWeight: FontWeight.w900,
                fontFamily: 'Tajawal',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'عنصر مفضل لكل مستخدم',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                fontFamily: 'Tajawal',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CouponPerformanceSectionState extends State<_CouponPerformanceSection> {
  _CouponPerformancePeriod _period = _CouponPerformancePeriod.month;

  _CouponPerformanceSnapshot get _snapshot {
    switch (_period) {
      case _CouponPerformancePeriod.day:
        return widget.data.performanceToday;
      case _CouponPerformancePeriod.week:
        return widget.data.performanceThisWeek;
      case _CouponPerformancePeriod.month:
        return widget.data.performanceThisMonth;
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _snapshot;
    final panels = <Widget>[
      _CouponPerformanceListPanel(
        title: 'أكثر الكوبونات نسخًا',
        items: snapshot.mostCopiedCoupons,
        emptyText: 'لا توجد عمليات نسخ حديثة',
      ),
      _CouponPerformanceListPanel(
        title: 'أكثر الكوبونات زيارة للمتجر',
        items: snapshot.mostVisitedCoupons,
        emptyText: 'لا توجد زيارات متجر حديثة',
      ),
      _CouponPerformanceListPanel(
        title: 'أكثر الكوبونات مشاركة',
        items: snapshot.mostSharedCoupons,
        emptyText: 'لا توجد مشاركات حديثة',
      ),
      _CouponPerformanceListPanel(
        title: 'آخر كوبونات تم استخدامها',
        items: snapshot.recentlyUsedCoupons,
        emptyText: 'لا توجد استخدامات حديثة',
      ),
      _CouponPerformanceListPanel(
        title: 'كوبونات لم تُستخدم منذ فترة',
        items: snapshot.staleCoupons,
        emptyText: 'لا توجد كوبونات خاملة',
      ),
      _CouponPerformanceListPanel(
        title: 'كوبونات عليها بلاغات “لا يعمل”',
        items: snapshot.notWorkingCoupons,
        emptyText: 'لا توجد بلاغات لا يعمل',
        actionLabel: 'تم الإصلاح',
        onItemAction: widget.onClearNotWorkingReport,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 10),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'أداء الكوبونات',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              _PeriodButton(
                label: 'يوم',
                selected: _period == _CouponPerformancePeriod.day,
                onTap: () =>
                    setState(() => _period = _CouponPerformancePeriod.day),
              ),
              const SizedBox(width: 8),
              _PeriodButton(
                label: 'أسبوع',
                selected: _period == _CouponPerformancePeriod.week,
                onTap: () =>
                    setState(() => _period = _CouponPerformancePeriod.week),
              ),
              const SizedBox(width: 8),
              _PeriodButton(
                label: 'شهر',
                selected: _period == _CouponPerformancePeriod.month,
                onTap: () =>
                    setState(() => _period = _CouponPerformancePeriod.month),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 760
                ? 1
                : width < 1180
                    ? 2
                    : 3;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                mainAxisExtent: width < 760 ? 270 : 238,
              ),
              itemCount: panels.length,
              itemBuilder: (context, index) => panels[index],
            );
          },
        ),
      ],
    );
  }
}

class _CouponPerformanceListPanel extends StatelessWidget {
  final String title;
  final List<_CouponPerformanceItem> items;
  final String emptyText;
  final String? actionLabel;
  final Future<void> Function(String couponId)? onItemAction;

  const _CouponPerformanceListPanel({
    required this.title,
    required this.items,
    required this.emptyText,
    this.actionLabel,
    this.onItemAction,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartPanel(
      title: title,
      child: items.isEmpty
          ? _EmptyOverviewMessage(
              icon: Icons.confirmation_number_outlined,
              text: emptyText,
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                return _CompactCouponPerformanceRow(
                  item: items[index],
                  actionLabel: actionLabel,
                  onItemAction: onItemAction,
                );
              },
            ),
    );
  }
}

class _CompactCouponPerformanceRow extends StatelessWidget {
  final _CouponPerformanceItem item;
  final String? actionLabel;
  final Future<void> Function(String couponId)? onItemAction;

  const _CompactCouponPerformanceRow({
    required this.item,
    this.actionLabel,
    this.onItemAction,
  });

  @override
  Widget build(BuildContext context) {
    final action = onItemAction;
    return SizedBox(
      height: 40,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    flex: 2,
                    child: Text(
                      item.storeName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'Tajawal',
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      item.code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Tajawal',
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _SmallValueBadge.compact(
              value: item.value,
              label: item.subtitle,
            ),
            if (action != null && actionLabel != null) ...[
              const SizedBox(width: 8),
              _CouponReportActionButton(
                label: actionLabel!,
                couponId: item.couponId,
                onPressed: action,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? Constants.primaryColor : Colors.white,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          constraints: const BoxConstraints(minWidth: 58),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color:
                  selected ? Constants.primaryColor : const Color(0xFFE5E7EB),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponReportActionButton extends StatefulWidget {
  final String label;
  final String couponId;
  final Future<void> Function(String couponId) onPressed;

  const _CouponReportActionButton({
    required this.label,
    required this.couponId,
    required this.onPressed,
  });

  @override
  State<_CouponReportActionButton> createState() =>
      _CouponReportActionButtonState();
}

class _CouponReportActionButtonState extends State<_CouponReportActionButton> {
  bool _busy = false;

  Future<void> _handleTap() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onPressed(widget.couponId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'حذف البلاغ بعد إصلاح الكوبون',
      child: SizedBox(
        height: 30,
        child: OutlinedButton.icon(
          onPressed: _busy ? null : _handleTap,
          icon: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: Text(widget.label),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF16A34A),
            side: const BorderSide(color: Color(0xFFBBF7D0)),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            textStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }
}

class _CouponStatusRatioPanel extends StatelessWidget {
  final int activeCoupons;
  final int inactiveCoupons;

  const _CouponStatusRatioPanel({
    required this.activeCoupons,
    required this.inactiveCoupons,
  });

  @override
  Widget build(BuildContext context) {
    final total = activeCoupons + inactiveCoupons;
    final activeRatio = total == 0 ? 0.0 : activeCoupons / total;

    return _ChartPanel(
      title: 'نسبة الكوبونات الفعالة مقابل غير الفعالة',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: activeRatio,
              minHeight: 14,
              backgroundColor: const Color(0xFFFEE2E2),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _RatioStat(
                  label: 'فعالة',
                  value: activeCoupons,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _RatioStat(
                  label: 'غير فعالة',
                  value: inactiveCoupons,
                  color: const Color(0xFFE11D48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnalyticsOverviewSection extends StatelessWidget {
  final _OverviewData data;
  final double conversionRate;
  final int approvedCoupons;
  final int pendingReviews;
  final String Function(String key) t;

  const _AnalyticsOverviewSection({
    required this.data,
    required this.conversionRate,
    required this.approvedCoupons,
    required this.pendingReviews,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    final engagementTotal =
        data.couponCopies + data.offerCopies + data.storeClicks;
    final activeCouponTotal =
        data.activeCoupons + data.expiredOrInactiveCoupons;
    final activeCouponRate = activeCouponTotal == 0
        ? 0
        : ((data.activeCoupons / activeCouponTotal) * 100).round();
    final reportCount = data.notWorkingCoupons.fold<int>(
      0,
      (sum, item) => sum + (int.tryParse(item.value) ?? 0),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final columns = width < 720
                ? 2
                : width < 1180
                    ? 3
                    : 6;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: width < 720 ? 1.65 : 1.75,
              children: [
                _MetricTile(
                  title: 'إجمالي التفاعل',
                  value: engagementTotal,
                  subtitle: 'نسخ وزيارات ونقرات',
                  icon: Icons.insights_rounded,
                  color: Constants.primaryColor,
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'معدل التحويل',
                  value: (conversionRate * 100).round(),
                  subtitle: 'نسبة مئوية',
                  icon: Icons.speed_rounded,
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'صحة الكوبونات',
                  value: activeCouponRate,
                  subtitle: 'فعالة من الإجمالي',
                  icon: Icons.health_and_safety_rounded,
                  color: const Color(0xFF16A34A),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'بلاغات لا يعمل',
                  value: reportCount,
                  subtitle: 'بلاغات مفتوحة',
                  icon: Icons.report_problem_rounded,
                  color: const Color(0xFFE11D48),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'مستخدمون نشطون',
                  value: data.activeUsers,
                  subtitle: 'آخر 30 يومًا',
                  icon: Icons.bolt_rounded,
                  color: const Color(0xFF0284C7),
                  onTap: () {},
                ),
                _MetricTile(
                  title: 'متاجر متابعة',
                  value: data.followedStores,
                  subtitle: 'إجمالي المتابعات',
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFDB2777),
                  onTap: () {},
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1100;
            final activityChart = _ChartPanel(
              title: 'اتجاه التفاعل',
              child: _LineChart(
                values: [
                  data.copiesToday.toDouble(),
                  data.copiesThisWeek.toDouble(),
                  data.copiesThisMonth.toDouble(),
                  engagementTotal.toDouble(),
                ],
              ),
            );
            final conversionChart = _ChartPanel(
              title: t('admin_conversion_rate'),
              child: _GaugeChart(value: conversionRate),
            );

            if (compact) {
              return Column(
                children: [
                  SizedBox(height: 280, child: activityChart),
                  const SizedBox(height: 14),
                  SizedBox(height: 260, child: conversionChart),
                ],
              );
            }

            return SizedBox(
              height: 290,
              child: Row(
                children: [
                  Expanded(flex: 3, child: activityChart),
                  const SizedBox(width: 10),
                  Expanded(child: conversionChart),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1180;
            final charts = [
              _ChartPanel(
                title: 'النسخ حسب الفترة',
                child: _BarChart(
                  labels: const ['اليوم', 'الأسبوع', 'الشهر'],
                  values: [
                    data.copiesToday.toDouble(),
                    data.copiesThisWeek.toDouble(),
                    data.copiesThisMonth.toDouble(),
                  ],
                  color: Constants.primaryColor,
                ),
              ),
              _ChartPanel(
                title: 'توزيع المحتوى',
                child: _BarChart(
                  labels: const ['متاجر', 'كوبونات', 'عروض', 'فئات', 'بنرات'],
                  values: [
                    data.stores.toDouble(),
                    data.coupons.toDouble(),
                    data.offers.toDouble(),
                    data.categories.toDouble(),
                    data.carousel.toDouble(),
                  ],
                  color: const Color(0xFF0EA5A4),
                ),
              ),
              _ChartPanel(
                title: 'حالة المراجعة',
                child: _BarChart(
                  labels: const ['معتمد', 'معلق', 'متاجر معلقة'],
                  values: [
                    approvedCoupons.toDouble(),
                    pendingReviews.toDouble(),
                    data.pendingStores.toDouble(),
                  ],
                  color: const Color(0xFF7C3AED),
                ),
              ),
            ];

            if (compact) {
              return Column(
                children: charts
                    .map((chart) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: SizedBox(height: 320, child: chart),
                        ))
                    .toList(),
              );
            }

            return SizedBox(
              height: 330,
              child: Row(
                children: [
                  Expanded(child: charts[0]),
                  const SizedBox(width: 10),
                  Expanded(child: charts[1]),
                  const SizedBox(width: 10),
                  Expanded(child: charts[2]),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 1180;
            final charts = [
              _ChartPanel(
                title: 'نشاط المستخدمين',
                child: _BarChart(
                  labels: const [
                    'جدد اليوم',
                    'جدد الأسبوع',
                    'نشطون',
                    'متابعات'
                  ],
                  values: [
                    data.newUsersToday.toDouble(),
                    data.newUsersThisWeek.toDouble(),
                    data.activeUsers.toDouble(),
                    data.followedStores.toDouble(),
                  ],
                  color: const Color(0xFF0284C7),
                ),
              ),
              _ChartPanel(
                title: 'مصادر التفاعل',
                child: _BarChart(
                  labels: const ['نسخ كوبونات', 'نسخ عروض', 'زيارات'],
                  values: [
                    data.couponCopies.toDouble(),
                    data.offerCopies.toDouble(),
                    data.storeClicks.toDouble(),
                  ],
                  color: const Color(0xFFF59E0B),
                ),
              ),
              _CouponStatusRatioPanel(
                activeCoupons: data.activeCoupons,
                inactiveCoupons: data.expiredOrInactiveCoupons,
              ),
            ];

            if (compact) {
              return Column(
                children: charts
                    .map((chart) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: SizedBox(height: 300, child: chart),
                        ))
                    .toList(),
              );
            }

            return SizedBox(
              height: 320,
              child: Row(
                children: [
                  Expanded(child: charts[0]),
                  const SizedBox(width: 10),
                  Expanded(child: charts[1]),
                  const SizedBox(width: 10),
                  Expanded(child: charts[2]),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _RatioStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _RatioStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallValueBadge extends StatelessWidget {
  final String value;
  final String label;
  final bool compact;

  const _SmallValueBadge({
    required this.value,
    required this.label,
  }) : compact = false;

  const _SmallValueBadge.compact({
    required this.value,
    required this.label,
  }) : compact = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minWidth: compact ? 0 : 62),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 9,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.18),
        ),
      ),
      child: compact
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Constants.primaryColor.withValues(alpha: 0.72),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            )
          : Column(
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Constants.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Tajawal',
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Constants.primaryColor.withValues(alpha: 0.72),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Tajawal',
                  ),
                ),
              ],
            ),
    );
  }
}

class _EmptyOverviewMessage extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyOverviewMessage({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF9CA3AF), size: 36),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'Tajawal',
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> values;

  const _LineChart({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(values),
      child: const SizedBox.expand(),
    );
  }
}

class _BarChart extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color color;

  const _BarChart({
    required this.labels,
    required this.values,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BarChartPainter(labels: labels, values: values, color: color),
      child: const SizedBox.expand(),
    );
  }
}

class _GaugeChart extends StatelessWidget {
  final double value;

  const _GaugeChart({required this.value});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GaugePainter(value.clamp(0.0, 1.0)),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 56),
          child: Text(
            '${(value * 100).round()}%',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> values;

  _LineChartPainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    const axisColor = Color(0xFFE5E7EB);
    final gridPaint = Paint()
      ..color = axisColor
      ..strokeWidth = 1;
    final linePaint = Paint()
      ..color = Constants.primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final pointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final pointStroke = Paint()
      ..color = Constants.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final chart = Rect.fromLTWH(38, 12, size.width - 54, size.height - 42);
    for (var i = 0; i <= 4; i++) {
      final y = chart.top + (chart.height / 4) * i;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
    }

    if (values.isEmpty) return;
    final maxValue = values.reduce((a, b) => a > b ? a : b).clamp(1, 999999);
    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? chart.center.dx
          : chart.left + (chart.width / (values.length - 1)) * i;
      final y = chart.bottom - (values[i] / maxValue) * chart.height;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, linePaint);

    for (final point in points) {
      canvas.drawCircle(point, 4, pointPaint);
      canvas.drawCircle(point, 4, pointStroke);
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _BarChartPainter extends CustomPainter {
  final List<String> labels;
  final List<double> values;
  final Color color;

  _BarChartPainter({
    required this.labels,
    required this.values,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.center,
    );
    final chart = Rect.fromLTWH(18, 8, size.width - 36, size.height - 42);
    final maxValue = values.isEmpty
        ? 1.0
        : values.reduce((a, b) => a > b ? a : b).clamp(1, 999999).toDouble();
    final barWidth = chart.width / (values.length * 2.2);
    final gap =
        (chart.width - (barWidth * values.length)) / (values.length + 1);
    final axisPaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1;
    final barPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawLine(
      Offset(chart.left, chart.bottom),
      Offset(chart.right, chart.bottom),
      axisPaint,
    );

    for (var i = 0; i < values.length; i++) {
      final left = chart.left + gap + i * (barWidth + gap);
      final height = (values[i] / maxValue) * chart.height;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, chart.bottom - height, barWidth, height),
        const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);

      textPainter.text = TextSpan(
        text: labels[i],
        style: const TextStyle(
          fontSize: 10,
          color: Color(0xFF6B7280),
          fontFamily: 'Tajawal',
        ),
      );
      textPainter.layout(maxWidth: barWidth + gap);
      textPainter.paint(
        canvas,
        Offset(left - gap / 2, chart.bottom + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.labels != labels ||
        oldDelegate.color != color;
  }
}

class _GaugePainter extends CustomPainter {
  final double value;

  _GaugePainter(this.value);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.68);
    final radius = size.shortestSide * 0.36;
    final baseRect = Rect.fromCircle(center: center, radius: radius);
    final basePaint = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;
    final valuePaint = Paint()
      ..shader = SweepGradient(
        startAngle: 3.14159,
        endAngle: 6.28318,
        colors: const [
          Color(0xFFE11D48),
          Color(0xFFF59E0B),
          Color(0xFF10B981),
        ],
      ).createShader(baseRect)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.butt;

    canvas.drawArc(baseRect, 3.14159, 3.14159, false, basePaint);
    canvas.drawArc(baseRect, 3.14159, 3.14159 * value, false, valuePaint);

    final needleAngle = 3.14159 + 3.14159 * value;
    final needleEnd = Offset(
      center.dx + radius * 0.78 * math.cos(needleAngle),
      center.dy + radius * 0.78 * math.sin(needleAngle),
    );
    final needlePaint = Paint()
      ..color = const Color(0xFF111827)
      ..strokeWidth = 2;
    canvas.drawLine(center, needleEnd, needlePaint);
    canvas.drawCircle(center, 5, Paint()..color = const Color(0xFF111827));
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
