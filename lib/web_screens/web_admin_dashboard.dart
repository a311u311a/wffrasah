part of 'web_admin_screen.dart';

// One-screen admin overview: KPI band, copy activity, latest events and the
// list of things that need an admin's action. Everything is sized to the
// available height, so on a desktop window nothing needs scrolling.

/// Pseudo section index: opens the coupon-performance tab (reports list).
const int _kReportsTarget = -1;

const Color _ink = Color(0xFF1E1B3A);
const Color _amber = Color(0xFFD97706);

enum _CouponStatus { active, inactive, expired }

class _ActivityEntry {
  final String type; // copy | shop_now | share
  final String code;
  final String storeName;
  final DateTime time;

  const _ActivityEntry({
    required this.type,
    required this.code,
    required this.storeName,
    required this.time,
  });
}

class _RecentCouponEntry {
  final String code;
  final String storeName;
  final DateTime createdAt;
  final _CouponStatus status;

  const _RecentCouponEntry({
    required this.code,
    required this.storeName,
    required this.createdAt,
    required this.status,
  });
}

class _DashboardStats {
  final int stores;
  final int activeCoupons;
  final int totalCoupons;
  final int activeOffers;
  final int totalOffers;
  final int activeBanners;
  final int totalBanners;
  final int pendingCoupons;
  final int pendingStores;
  final int expiredTotal;
  final String expiredLabel;
  final int expiringSoonTotal;
  final String expiringSoonLabel;
  final int users;
  final int newUsersThisWeek;
  final int reportedCoupons;
  final List<int> dailyCopies; // 14 days, oldest first
  final List<_ActivityEntry> recentActivity;
  final List<_RecentCouponEntry> recentCoupons;
  final List<_AdminAttentionItem> alerts;
  final DateTime? loadedAt;

  const _DashboardStats({
    required this.stores,
    required this.activeCoupons,
    required this.totalCoupons,
    required this.activeOffers,
    required this.totalOffers,
    required this.activeBanners,
    required this.totalBanners,
    required this.pendingCoupons,
    required this.pendingStores,
    required this.expiredTotal,
    required this.expiredLabel,
    required this.expiringSoonTotal,
    required this.expiringSoonLabel,
    required this.users,
    required this.newUsersThisWeek,
    required this.reportedCoupons,
    required this.dailyCopies,
    required this.recentActivity,
    required this.recentCoupons,
    required this.alerts,
    required this.loadedAt,
  });

  static const empty = _DashboardStats(
    stores: 0,
    activeCoupons: 0,
    totalCoupons: 0,
    activeOffers: 0,
    totalOffers: 0,
    activeBanners: 0,
    totalBanners: 0,
    pendingCoupons: 0,
    pendingStores: 0,
    expiredTotal: 0,
    expiredLabel: '',
    expiringSoonTotal: 0,
    expiringSoonLabel: '',
    users: 0,
    newUsersThisWeek: 0,
    reportedCoupons: 0,
    dailyCopies: <int>[],
    recentActivity: <_ActivityEntry>[],
    recentCoupons: <_RecentCouponEntry>[],
    alerts: <_AdminAttentionItem>[],
    loadedAt: null,
  );
}

String _relativeTime(BuildContext context, DateTime time) {
  final diff = DateTime.now().difference(time);
  if (diff.inMinutes < 1) return webText(context, 'الآن', 'now');
  if (diff.inMinutes < 60) {
    return webText(
        context, 'قبل ${diff.inMinutes} د', '${diff.inMinutes}m ago');
  }
  if (diff.inHours < 24) {
    return webText(context, 'قبل ${diff.inHours} س', '${diff.inHours}h ago');
  }
  if (diff.inDays == 1) return webText(context, 'أمس', 'yesterday');
  if (diff.inDays < 30) {
    return webText(context, 'قبل ${diff.inDays} يوم', '${diff.inDays}d ago');
  }
  return '${time.year}/${time.month}/${time.day}';
}

TextStyle _ts(double size, FontWeight weight, Color color, {double? height}) {
  return TextStyle(
    fontFamily: Constants.primaryFontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
  );
}

// ---------------------------------------------------------------------------
// Top bar shared by all overview tabs
// ---------------------------------------------------------------------------

class _OverviewTopBar extends StatelessWidget {
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onRefresh;
  final bool loading;
  final DateTime? loadedAt;

  const _OverviewTopBar({
    required this.selectedTab,
    required this.onTabChanged,
    required this.onRefresh,
    required this.loading,
    required this.loadedAt,
  });

  static const _tabs = <_OverviewPageTabItem>[
    _OverviewPageTabItem('الملخص', Icons.space_dashboard_outlined),
    _OverviewPageTabItem('أداء الكوبونات', Icons.confirmation_number_outlined),
    _OverviewPageTabItem('أداء المتاجر', Icons.storefront_outlined),
    _OverviewPageTabItem('المستخدمون', Icons.group_outlined),
    _OverviewPageTabItem('التحليلات', Icons.insights_rounded),
  ];

  Widget _titleText(BuildContext context, String updated) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(webText(context, 'النظرة العامة', 'Overview'),
            style: _ts(22, FontWeight.w800, _ink, height: 1.2)),
        const SizedBox(height: 2),
        Text(
          loading ? webText(context, 'جارٍ التحميل…', 'Loading…') : updated,
          style: _ts(12, FontWeight.w500, Constants.secondaryTextColor),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final updated = loadedAt == null
        ? ''
        : webText(
            context,
            'آخر تحديث ${TimeOfDay.fromDateTime(loadedAt!).format(context)}',
            'Updated ${TimeOfDay.fromDateTime(loadedAt!).format(context)}',
          );

    final title = Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Constants.primaryLightColor,
            borderRadius: BorderRadius.circular(Constants.radiusButton),
          ),
          child: Icon(Icons.space_dashboard_outlined,
              size: 21, color: Constants.primaryColor),
        ),
        const SizedBox(width: 12),
        Flexible(child: _titleText(context, updated)),
      ],
    );

    final tabs = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Constants.radiusButton),
        border: Border.all(color: Constants.mutedBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _tabs.length; i++)
            _TopBarTab(
              item: _tabs[i],
              selected: i == selectedTab,
              onTap: () => onTabChanged(i),
            ),
        ],
      ),
    );

    final refresh = Tooltip(
      message: webText(context, 'تحديث البيانات', 'Refresh'),
      child: InkWell(
        onTap: loading ? null : onRefresh,
        borderRadius: BorderRadius.circular(Constants.radiusButton),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Constants.radiusButton),
            border: Border.all(color: Constants.mutedBorderColor),
          ),
          child: loading
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Constants.primaryColor,
                  ),
                )
              : Icon(Icons.refresh_rounded,
                  size: 20, color: Constants.primaryColor),
        ),
      ),
    );

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth >= 860) {
        return Row(
          children: [
            Expanded(child: title),
            tabs,
            const SizedBox(width: 8),
            refresh,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [Expanded(child: title), refresh]),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: tabs,
          ),
        ],
      );
    });
  }
}

class _TopBarTab extends StatelessWidget {
  final _OverviewPageTabItem item;
  final bool selected;
  final VoidCallback onTap;

  const _TopBarTab({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : Constants.secondaryTextColor;
    return Material(
      color: selected ? Constants.primaryColor : Colors.transparent,
      borderRadius: BorderRadius.circular(Constants.radiusSmall - 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Constants.radiusSmall - 2),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 17, color: color),
              const SizedBox(width: 6),
              Text(item.label, style: _ts(13, FontWeight.w700, color)),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Summary tab
// ---------------------------------------------------------------------------

class _DashboardView extends StatelessWidget {
  final _DashboardStats stats;
  final ValueChanged<int> onOpen;

  const _DashboardView({required this.stats, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final wide = constraints.maxWidth >= 900 && constraints.maxHeight >= 470;
      final kpis = _KpiBand(
        stats: stats,
        onOpen: onOpen,
        columns: constraints.maxWidth >= 900 ? 8 : 4,
      );
      final alerts = _AlertsPanel(items: stats.alerts, onOpen: onOpen);
      final activity = _ActivityPanel(entries: stats.recentActivity);
      final chart = _CopiesChartPanel(daily: stats.dailyCopies);
      final latest = _RecentCouponsPanel(
        entries: stats.recentCoupons,
        onOpenAll: () => onOpen(2),
      );

      if (!wide) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              kpis,
              const SizedBox(height: 14),
              SizedBox(height: 380, child: alerts),
              const SizedBox(height: 14),
              SizedBox(height: 240, child: chart),
              const SizedBox(height: 14),
              SizedBox(height: 360, child: activity),
              const SizedBox(height: 14),
              SizedBox(height: 360, child: latest),
            ],
          ),
        );
      }

      const gap = 14.0;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          kpis,
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 4, child: alerts),
                const SizedBox(width: gap),
                Expanded(flex: 4, child: activity),
                const SizedBox(width: gap),
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 5, child: chart),
                      const SizedBox(height: gap),
                      Expanded(flex: 6, child: latest),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ---- KPI band -------------------------------------------------------------

class _Kpi {
  final String label;
  final int value;
  final String caption;
  final IconData icon;
  final Color tone;
  final bool flag; // needs attention when value > 0
  final int? target;

  const _Kpi({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.tone,
    this.flag = false,
    this.target,
  });
}

class _KpiBand extends StatelessWidget {
  final _DashboardStats stats;
  final ValueChanged<int> onOpen;
  final int columns;

  const _KpiBand({
    required this.stats,
    required this.onOpen,
    required this.columns,
  });

  @override
  Widget build(BuildContext context) {
    final s = stats;
    final primary = Constants.primaryColor;
    final kpis = <_Kpi>[
      _Kpi(
        label: webText(context, 'المتاجر', 'Stores'),
        value: s.stores,
        caption: s.pendingStores > 0
            ? webText(context, '${s.pendingStores} بانتظار الموافقة',
                '${s.pendingStores} awaiting approval')
            : webText(context, 'كلها معتمدة', 'All approved'),
        icon: Icons.storefront_outlined,
        tone: primary,
        target: 1,
      ),
      _Kpi(
        label: webText(context, 'كوبونات فعّالة', 'Active coupons'),
        value: s.activeCoupons,
        caption: webText(context, 'من ${s.totalCoupons} كوبون',
            'of ${s.totalCoupons} coupons'),
        icon: Icons.confirmation_number_outlined,
        tone: Constants.successColor,
        target: 2,
      ),
      _Kpi(
        label: webText(context, 'عروض فعّالة', 'Active offers'),
        value: s.activeOffers,
        caption: webText(
            context, 'من ${s.totalOffers} عرض', 'of ${s.totalOffers} offers'),
        icon: Icons.local_offer_outlined,
        tone: Constants.accentColor,
        target: 3,
      ),
      _Kpi(
        label: webText(context, 'بنرات ظاهرة', 'Live banners'),
        value: s.activeBanners,
        caption: webText(context, 'من ${s.totalBanners} بنر',
            'of ${s.totalBanners} banners'),
        icon: Icons.view_carousel_outlined,
        tone: const Color(0xFF0EA5A4),
        target: 5,
      ),
      _Kpi(
        label: webText(context, 'معلّقة', 'Pending'),
        value: s.pendingCoupons,
        caption: s.pendingCoupons > 0
            ? webText(context, 'كوبونات بانتظار موافقتك', 'Coupons to approve')
            : webText(context, 'لا شيء معلّق', 'Nothing pending'),
        icon: Icons.pending_actions_outlined,
        tone: _amber,
        flag: true,
        target: 6,
      ),
      _Kpi(
        label: webText(context, 'منتهية', 'Expired'),
        value: s.expiredTotal,
        caption: s.expiredTotal > 0
            ? s.expiredLabel
            : webText(context, 'لا يوجد منتهٍ', 'None expired'),
        icon: Icons.event_busy_outlined,
        tone: Constants.errorColor,
        flag: true,
        target: 2,
      ),
      _Kpi(
        label: webText(context, 'تنتهي قريبًا', 'Expiring soon'),
        value: s.expiringSoonTotal,
        caption: s.expiringSoonTotal > 0
            ? webText(context, '${s.expiringSoonLabel} خلال 7 أيام',
                '${s.expiringSoonLabel} within 7 days')
            : webText(context, 'لا شيء خلال 7 أيام', 'Nothing within 7 days'),
        icon: Icons.timer_outlined,
        tone: _amber,
        flag: true,
        target: 2,
      ),
      _Kpi(
        label: webText(context, 'المستخدمون', 'Users'),
        value: s.users,
        caption: webText(context, '+${s.newUsersThisWeek} هذا الأسبوع',
            '+${s.newUsersThisWeek} this week'),
        icon: Icons.group_outlined,
        tone: primary,
      ),
    ];

    final rows = <List<_Kpi>>[];
    for (var i = 0; i < kpis.length; i += columns) {
      rows.add(kpis.sublist(i, math.min(i + columns, kpis.length)));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Constants.radiusCard),
        border: Border.all(color: Constants.mutedBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0)
              const Divider(
                  height: 1, thickness: 1, color: Constants.mutedBorderColor),
            SizedBox(
              height: 98,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rows[r].length; i++) ...[
                    if (i > 0)
                      const VerticalDivider(
                        width: 1,
                        thickness: 1,
                        indent: 16,
                        endIndent: 16,
                        color: Constants.mutedBorderColor,
                      ),
                    Expanded(
                      child: _KpiCell(
                        kpi: rows[r][i],
                        onTap: rows[r][i].target == null
                            ? null
                            : () => onOpen(rows[r][i].target!),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiCell extends StatelessWidget {
  final _Kpi kpi;
  final VoidCallback? onTap;

  const _KpiCell({required this.kpi, this.onTap});

  @override
  Widget build(BuildContext context) {
    final alert = kpi.flag && kpi.value > 0;
    return Material(
      color: alert ? kpi.tone.withValues(alpha: 0.06) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(kpi.icon, size: 15, color: kpi.tone),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      kpi.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _ts(
                          12, FontWeight.w700, Constants.secondaryTextColor),
                    ),
                  ),
                ],
              ),
              Text(
                '${kpi.value}',
                style: _ts(28, FontWeight.w800, alert ? kpi.tone : _ink,
                    height: 1.1),
              ),
              Text(
                kpi.caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _ts(11.5, FontWeight.w500, Constants.secondaryTextColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Panel chrome ---------------------------------------------------------

class _DashPanel extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final Widget child;
  final EdgeInsetsGeometry bodyPadding;

  const _DashPanel({
    required this.title,
    required this.child,
    this.trailing,
    this.bodyPadding = const EdgeInsets.fromLTRB(8, 0, 8, 8),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Constants.radiusMedium),
        border: Border.all(color: Constants.mutedBorderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 46,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _ts(14.5, FontWeight.w800, _ink)),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
            ),
          ),
          Expanded(child: Padding(padding: bodyPadding, child: child)),
        ],
      ),
    );
  }
}

/// Shows as many rows as fit the available height, never scrolls.
class _FitList extends StatelessWidget {
  final double itemExtent;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Widget empty;

  const _FitList({
    required this.itemExtent,
    required this.itemCount,
    required this.itemBuilder,
    required this.empty,
  });

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return empty;
    return LayoutBuilder(builder: (context, constraints) {
      final fit = (constraints.maxHeight / itemExtent).floor();
      final count = math.max(0, math.min(fit, itemCount));
      return Column(
        children: [
          for (var i = 0; i < count; i++)
            SizedBox(height: itemExtent, child: itemBuilder(context, i)),
        ],
      );
    });
  }
}

class _CountPill extends StatelessWidget {
  final String text;
  final Color color;

  const _CountPill({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: _ts(11.5, FontWeight.w700, color)),
    );
  }
}

// ---- Alerts ---------------------------------------------------------------

class _AlertsPanel extends StatelessWidget {
  final List<_AdminAttentionItem> items;
  final ValueChanged<int> onOpen;

  const _AlertsPanel({required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final open = items.where((item) => item.count > 0).toList();
    return _DashPanel(
      title: webText(context, 'يحتاج إجراء', 'Needs action'),
      trailing: open.isEmpty
          ? null
          : _CountPill(text: '${open.length}', color: Constants.errorColor),
      child: _FitList(
        itemExtent: 56,
        itemCount: open.length,
        empty: _PanelEmpty(
          icon: Icons.task_alt_rounded,
          text: webText(context, 'لا شيء يحتاج إجراء الآن',
              'Nothing needs action right now'),
        ),
        itemBuilder: (context, index) {
          final item = open[index];
          return InkWell(
            borderRadius: BorderRadius.circular(Constants.radiusSmall),
            onTap: item.sectionIndex == null
                ? null
                : () => onOpen(item.sectionIndex!),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(Constants.radiusSmall),
                    ),
                    child: Icon(item.icon, size: 19, color: item.color),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(13.5, FontWeight.w700, _ink)),
                        const SizedBox(height: 2),
                        Text(item.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(11.5, FontWeight.w500,
                                Constants.secondaryTextColor)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${item.count}',
                      style: _ts(18, FontWeight.w800, item.color)),
                  const SizedBox(width: 4),
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.chevron_left_rounded
                        : Icons.chevron_right_rounded,
                    size: 18,
                    color: Constants.disabledTextColor,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---- Recent activity ------------------------------------------------------

class _ActivityPanel extends StatelessWidget {
  final List<_ActivityEntry> entries;

  const _ActivityPanel({required this.entries});

  @override
  Widget build(BuildContext context) {
    return _DashPanel(
      title: webText(
          context, 'آخر النشاط على الكوبونات', 'Latest coupon activity'),
      child: _FitList(
        itemExtent: 50,
        itemCount: entries.length,
        empty: _PanelEmpty(
          icon: Icons.history_rounded,
          text: webText(context, 'لا نشاط خلال آخر 30 يومًا',
              'No activity in the last 30 days'),
        ),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final (IconData icon, Color color, String verb) =
              switch (entry.type) {
            'shop_now' => (
                Icons.open_in_new_rounded,
                Constants.accentColor,
                webText(context, 'زيارة متجر', 'Store visit'),
              ),
            'share' => (
                Icons.share_outlined,
                const Color(0xFF0EA5A4),
                webText(context, 'مشاركة', 'Share'),
              ),
            _ => (
                Icons.content_copy_rounded,
                Constants.primaryColor,
                webText(context, 'نسخ', 'Copy'),
              ),
          };
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('$verb ',
                              style: _ts(12, FontWeight.w500,
                                  Constants.secondaryTextColor)),
                          Flexible(
                            child: Text(
                              entry.code,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textDirection: TextDirection.ltr,
                              style: _ts(13, FontWeight.w800, _ink),
                            ),
                          ),
                        ],
                      ),
                      if (entry.storeName.isNotEmpty)
                        Text(entry.storeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _ts(11.5, FontWeight.w500,
                                Constants.secondaryTextColor)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(_relativeTime(context, entry.time),
                    style: _ts(
                        11.5, FontWeight.w600, Constants.secondaryTextColor)),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---- Latest coupons -------------------------------------------------------

class _RecentCouponsPanel extends StatelessWidget {
  final List<_RecentCouponEntry> entries;
  final VoidCallback onOpenAll;

  const _RecentCouponsPanel({required this.entries, required this.onOpenAll});

  @override
  Widget build(BuildContext context) {
    return _DashPanel(
      title: webText(context, 'آخر الكوبونات المضافة', 'Latest coupons'),
      trailing: TextButton(
        onPressed: onOpenAll,
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: Constants.primaryColor,
          textStyle: _ts(12.5, FontWeight.w700, Constants.primaryColor),
        ),
        child: Text(webText(context, 'إدارة الكوبونات', 'Manage coupons')),
      ),
      child: _FitList(
        itemExtent: 44,
        itemCount: entries.length,
        empty: _PanelEmpty(
          icon: Icons.confirmation_number_outlined,
          text: webText(context, 'لا توجد كوبونات بعد', 'No coupons yet'),
        ),
        itemBuilder: (context, index) {
          final entry = entries[index];
          final (String label, Color color) = switch (entry.status) {
            _CouponStatus.active => (
                webText(context, 'فعّال', 'Active'),
                Constants.successColor,
              ),
            _CouponStatus.inactive => (
                webText(context, 'متوقف', 'Paused'),
                Constants.inactiveBadgeColor,
              ),
            _CouponStatus.expired => (
                webText(context, 'منتهٍ', 'Expired'),
                Constants.errorColor,
              ),
          };
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(entry.code,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: TextDirection.ltr,
                            style: _ts(13, FontWeight.w800, _ink)),
                      ),
                      if (entry.storeName.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(entry.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _ts(12, FontWeight.w500,
                                  Constants.secondaryTextColor)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _CountPill(text: label, color: color),
                const SizedBox(width: 10),
                SizedBox(
                  width: 70,
                  child: Text(_relativeTime(context, entry.createdAt),
                      textAlign: TextAlign.end,
                      style: _ts(
                          11.5, FontWeight.w600, Constants.secondaryTextColor)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ---- Copies chart ---------------------------------------------------------

class _CopiesChartPanel extends StatelessWidget {
  final List<int> daily;

  const _CopiesChartPanel({required this.daily});

  @override
  Widget build(BuildContext context) {
    final values = daily.length == 14 ? daily : List<int>.filled(14, 0);
    final last7 = values.sublist(7).fold<int>(0, (a, b) => a + b);
    final prev7 = values.sublist(0, 7).fold<int>(0, (a, b) => a + b);
    final maxValue = values.fold<int>(0, math.max);

    String? delta;
    Color deltaColor = Constants.secondaryTextColor;
    if (prev7 > 0) {
      final pct = (((last7 - prev7) / prev7) * 100).round();
      // LTR isolate keeps "+12%" readable inside Arabic text.
      delta = webText(
        context,
        '\u2066${pct >= 0 ? '+' : ''}$pct%\u2069 عن الأسبوع السابق',
        '${pct >= 0 ? '+' : ''}$pct% vs previous week',
      );
      deltaColor = pct >= 0 ? Constants.successColor : Constants.errorColor;
    }

    return _DashPanel(
      title: webText(context, 'نسخ الكوبونات، آخر 14 يومًا',
          'Coupon copies, last 14 days'),
      bodyPadding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$last7', style: _ts(24, FontWeight.w800, _ink, height: 1)),
              const SizedBox(width: 6),
              Text(webText(context, 'نسخة خلال 7 أيام', 'copies in 7 days'),
                  style:
                      _ts(12, FontWeight.w500, Constants.secondaryTextColor)),
              const Spacer(),
              if (delta != null)
                Text(delta, style: _ts(12, FontWeight.w700, deltaColor)),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: maxValue == 0
                ? _PanelEmpty(
                    icon: Icons.bar_chart_rounded,
                    text: webText(context, 'لا نسخ خلال آخر 14 يومًا',
                        'No copies in the last 14 days'),
                  )
                : _CopiesBars(values: values, maxValue: maxValue),
          ),
        ],
      ),
    );
  }
}

class _CopiesBars extends StatelessWidget {
  final List<int> values;
  final int maxValue;

  const _CopiesBars({required this.values, required this.maxValue});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day)
        .subtract(const Duration(days: 13));
    const labelHeight = 18.0;
    return LayoutBuilder(builder: (context, constraints) {
      final plotHeight = math.max(0.0, constraints.maxHeight - labelHeight);
      return Column(
        children: [
          SizedBox(
            height: plotHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Tooltip(
                      message: () {
                        final d = first.add(Duration(days: i));
                        return webText(
                          context,
                          '${d.day}/${d.month}: ${values[i]} نسخة',
                          '${d.month}/${d.day}: ${values[i]} copies',
                        );
                      }(),
                      waitDuration: Duration.zero,
                      child: Container(
                        // full-height hit target, bar drawn at the bottom
                        color: Colors.transparent,
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: values[i] == 0
                              ? 2
                              : math.max(
                                  3.0, plotHeight * values[i] / maxValue),
                          decoration: BoxDecoration(
                            color: values[i] == 0
                                ? Constants.mutedBorderColor
                                : i == values.length - 1
                                    ? Constants.primaryColor
                                    : Constants.primaryColor
                                        .withValues(alpha: 0.55),
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4)),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(height: 1, color: Constants.borderColor),
          SizedBox(
            height: labelHeight - 1,
            child: Row(
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Center(
                      child: Text(
                        i == values.length - 1
                            ? webText(context, 'اليوم', 'Today')
                            : i.isEven
                                ? '${first.add(Duration(days: i)).day}'
                                : '',
                        maxLines: 1,
                        style: _ts(10.5, FontWeight.w600,
                            Constants.secondaryTextColor),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _PanelEmpty extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PanelEmpty({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28, color: Constants.disabledTextColor),
          const SizedBox(height: 8),
          Text(text,
              textAlign: TextAlign.center,
              style: _ts(12.5, FontWeight.w600, Constants.secondaryTextColor)),
        ],
      ),
    );
  }
}
