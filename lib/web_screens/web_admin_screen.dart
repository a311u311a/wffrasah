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

class _OverviewData {
  final int stores;
  final int coupons;
  final int offers;
  final int categories;
  final int carousel;
  final int pending;
  final int notifications;
  final int couponCopies;
  final int offerCopies;
  final int storeClicks;
  final int activeItems;

  const _OverviewData({
    required this.stores,
    required this.coupons,
    required this.offers,
    required this.categories,
    required this.carousel,
    required this.pending,
    required this.notifications,
    required this.couponCopies,
    required this.offerCopies,
    required this.storeClicks,
    required this.activeItems,
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
      couponCopies: 0,
      offerCopies: 0,
      storeClicks: 0,
      activeItems: 0,
    );
  }

  factory _OverviewData.fromRows({
    required List<int> counts,
    required List<dynamic> events,
  }) {
    var couponCopies = 0;
    var offerCopies = 0;
    var storeClicks = 0;
    final activeItemKeys = <String>{};

    for (final event in events) {
      if (event is! Map) continue;
      final eventType = event['event_type']?.toString() ?? '';
      final itemType = event['item_type']?.toString() ?? '';
      final itemId = event['item_id']?.toString() ?? '';

      if (eventType == 'coupon_copy') couponCopies++;
      if (eventType == 'offer_copy') offerCopies++;
      if (eventType == 'store_click') storeClicks++;
      if (itemType.isNotEmpty && itemId.isNotEmpty) {
        activeItemKeys.add('$itemType:$itemId');
      }
    }

    return _OverviewData(
      stores: counts[0],
      coupons: counts[1],
      offers: counts[2],
      categories: counts[3],
      carousel: counts[4],
      pending: counts[5],
      notifications: counts[6],
      couponCopies: couponCopies,
      offerCopies: offerCopies,
      storeClicks: storeClicks,
      activeItems: activeItemKeys.length,
    );
  }
}

class _AdminOverview extends StatelessWidget {
  final Future<int> Function(String source) countRows;
  final ValueChanged<int> onOpenSection;

  const _AdminOverview({
    required this.countRows,
    required this.onOpenSection,
  });

  Future<_OverviewData> _loadData() async {
    final counts = await Future.wait([
      countRows('stores'),
      countRows('coupons'),
      countRows('offers'),
      countRows('categories'),
      countRows('carousel'),
      countRows('admin_pending_coupons'),
      countRows('notifications'),
    ]);

    final since = DateTime.now()
        .toUtc()
        .subtract(const Duration(days: 30))
        .toIso8601String();

    List<dynamic> events = const [];
    try {
      events = await Supabase.instance.client
          .from('analytics_events')
          .select('event_type,item_type,item_id,store_id,created_at')
          .gte('created_at', since);
    } catch (_) {
      events = const [];
    }

    return _OverviewData.fromRows(counts: counts, events: events);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_OverviewData>(
      future: _loadData(),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1050;
                    return GridView.count(
                      crossAxisCount: compact ? 2 : 4,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: compact ? 1.75 : 1.95,
                      children: [
                        _MetricTile(
                          title: t('admin_code_copies'),
                          value: copies,
                          subtitle: t('admin_last_30_days'),
                          icon: Icons.content_copy_rounded,
                          color: Constants.primaryColor,
                          onTap: () {},
                        ),
                        _MetricTile(
                          title: t('admin_store_clicks'),
                          value: clicks,
                          subtitle: t('admin_last_30_days'),
                          icon: Icons.open_in_new_rounded,
                          color: const Color(0xFF0284C7),
                          onTap: () {},
                        ),
                        _MetricTile(
                          title: t('admin_conversion_rate'),
                          value:
                              (conversionRate.clamp(0.0, 9.99) * 100).round(),
                          subtitle: t('admin_copies_per_clicks'),
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF10B981),
                          onTap: () {},
                        ),
                        _MetricTile(
                          title: t('admin_active_items'),
                          value: data.activeItems,
                          subtitle: t('admin_with_user_activity'),
                          icon: Icons.touch_app_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () {},
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                Padding(
                  padding: const EdgeInsetsDirectional.only(start: 2),
                  child: Text(
                    t('admin_content_overview'),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Tajawal',
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1050;
                    return GridView.count(
                      crossAxisCount: compact ? 3 : 6,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: compact ? 1.65 : 1.55,
                      children: [
                        _MetricTile(
                          title: t('stores'),
                          value: stores,
                          subtitle: t('admin_stores_subtitle'),
                          icon: Icons.storefront_rounded,
                          color: const Color(0xFF0EA5A4),
                          onTap: () => onOpenSection(1),
                        ),
                        _MetricTile(
                          title: t('coupons'),
                          value: coupons,
                          subtitle: t('admin_coupons_subtitle'),
                          icon: Icons.confirmation_number_rounded,
                          color: Constants.primaryColor,
                          onTap: () => onOpenSection(2),
                        ),
                        _MetricTile(
                          title: t('offers'),
                          value: offers,
                          subtitle: t('admin_offers_subtitle'),
                          icon: Icons.local_offer_rounded,
                          color: const Color(0xFF0284C7),
                          onTap: () => onOpenSection(3),
                        ),
                        _MetricTile(
                          title: t('categories'),
                          value: categories,
                          subtitle: t('admin_categories_subtitle'),
                          icon: Icons.category_rounded,
                          color: const Color(0xFFF59E0B),
                          onTap: () => onOpenSection(4),
                        ),
                        _MetricTile(
                          title: t('admin_carousel_banner'),
                          value: carousel,
                          subtitle: t('admin_carousel_subtitle'),
                          icon: Icons.view_carousel_rounded,
                          color: const Color(0xFF0EA5A4),
                          onTap: () => onOpenSection(5),
                        ),
                        _MetricTile(
                          title: t('admin_pending_approval'),
                          value: pending,
                          subtitle: t('admin_pending_subtitle'),
                          icon: Icons.pending_actions_rounded,
                          color: const Color(0xFFE11D48),
                          onTap: () => onOpenSection(6),
                        ),
                        _MetricTile(
                          title: t('notifications'),
                          value: notifications,
                          subtitle: t('admin_notifications_subtitle'),
                          icon: Icons.notifications_active_rounded,
                          color: const Color(0xFF7C3AED),
                          onTap: () => onOpenSection(7),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 1180;
                    final mainCharts = [
                      Expanded(
                        flex: 3,
                        child: _ChartPanel(
                          title: t('admin_activity_summary'),
                          child: _LineChart(
                            values: [
                              data.couponCopies.toDouble(),
                              data.offerCopies.toDouble(),
                              data.storeClicks.toDouble(),
                              data.activeItems.toDouble(),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 1,
                        child: _ChartPanel(
                          title: t('admin_conversion_rate'),
                          child: _GaugeChart(value: conversionRate),
                        ),
                      ),
                    ];

                    if (!wide) {
                      return Column(
                        children: [
                          SizedBox(height: 260, child: mainCharts.first),
                          const SizedBox(height: 14),
                          SizedBox(height: 260, child: mainCharts.last),
                        ],
                      );
                    }

                    return SizedBox(
                      height: 270,
                      child: Row(children: mainCharts),
                    );
                  },
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 1050;
                    final panels = [
                      _ChartPanel(
                        title: t('admin_management_distribution'),
                        child: _BarChart(
                          labels: [
                            t('admin_coupon_copies_short'),
                            t('admin_offer_copies_short'),
                            t('admin_store_clicks_short'),
                          ],
                          values: [
                            data.couponCopies.toDouble(),
                            data.offerCopies.toDouble(),
                            data.storeClicks.toDouble(),
                          ],
                          color: const Color(0xFF0EA5A4),
                        ),
                      ),
                      _ChartPanel(
                        title: t('admin_review_status'),
                        child: _BarChart(
                          labels: [t('admin_approved'), t('admin_pending')],
                          values: [coupons.toDouble(), pending.toDouble()],
                          color: Constants.primaryColor,
                        ),
                      ),
                      _QuickActions(onOpenSection: onOpenSection),
                    ];

                    if (compact) {
                      return Column(
                        children: panels
                            .map((panel) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: SizedBox(height: 320, child: panel),
                                ))
                            .toList(),
                      );
                    }

                    return SizedBox(
                      height: 350,
                      child: Row(
                        children: [
                          Expanded(child: panels[0]),
                          const SizedBox(width: 10),
                          Expanded(child: panels[1]),
                          const SizedBox(width: 10),
                          Expanded(child: panels[2]),
                        ],
                      ),
                    );
                  },
                ),
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
          padding: const EdgeInsets.all(14),
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
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, size: 18, color: color),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
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
                  fontSize: 26,
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
                  fontSize: 11,
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

class _QuickActions extends StatelessWidget {
  final ValueChanged<int> onOpenSection;

  const _QuickActions({required this.onOpenSection});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    String t(String key) => localizations?.translate(key) ?? key;
    final actions = [
      (
        title: t('admin_manage_stores'),
        icon: Icons.storefront_rounded,
        index: 1
      ),
      (
        title: t('admin_manage_coupons'),
        icon: Icons.confirmation_number_rounded,
        index: 2
      ),
      (
        title: t('admin_manage_offers'),
        icon: Icons.local_offer_rounded,
        index: 3
      ),
      (
        title: t('admin_review_pending'),
        icon: Icons.pending_actions_rounded,
        index: 6
      ),
    ];

    return _ChartPanel(
      title: t('admin_shortcuts'),
      child: ListView(
        padding: EdgeInsets.zero,
        children: actions
            .map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    onTap: () => onOpenSection(action.index),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(action.icon,
                              color: Constants.primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              action.title,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'Tajawal',
                                color: Color(0xFF111827),
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_left_rounded,
                              color: Color(0xFF9CA3AF), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
            .toList(),
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
