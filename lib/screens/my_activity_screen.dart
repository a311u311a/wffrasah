import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants.dart';
import '../localization/app_localizations.dart';
import '../providers/favorites_provider.dart';

class MyActivityScreen extends StatefulWidget {
  const MyActivityScreen({super.key});

  @override
  State<MyActivityScreen> createState() => _MyActivityScreenState();
}

class _MyActivityScreenState extends State<MyActivityScreen> {
  late Future<_ActivityStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchActivityStats();
  }

  Future<_ActivityStats> _fetchActivityStats() async {
    final sb = Supabase.instance.client;
    final userId = sb.auth.currentUser?.id;
    if (userId == null) return const _ActivityStats.empty();

    try {
      final rows = await sb
          .from('coupon_usage_events')
          .select('coupon_id,event_type,created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final events = (rows as List).cast<Map<String, dynamic>>();
      if (events.isEmpty) {
        return await _fetchAnalyticsFallback(userId);
      }

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final sevenDaysStart = todayStart.subtract(const Duration(days: 6));
      final monthStart = DateTime(now.year, now.month);
      final copiedEvents = events.where((row) => row['event_type'] == 'copy');
      final usedEvents = events.where((row) => row['event_type'] == 'shop_now');

      return _ActivityStats(
        copiedCoupons: copiedEvents.length,
        usedCoupons: usedEvents.length,
        today: _countPeriod(
          events,
          copiedType: 'copy',
          usedType: 'shop_now',
          start: todayStart,
        ),
        sevenDays: _countPeriod(
          events,
          copiedType: 'copy',
          usedType: 'shop_now',
          start: sevenDaysStart,
        ),
        month: _countPeriod(
          events,
          copiedType: 'copy',
          usedType: 'shop_now',
          start: monthStart,
        ),
        lastActivity: _buildLatestActivity(events),
      );
    } catch (_) {
      return _fetchAnalyticsFallback(userId);
    }
  }

  Future<_ActivityStats> _fetchAnalyticsFallback(String userId) async {
    try {
      final rows = await Supabase.instance.client
          .from('analytics_events')
          .select('item_id,event_type,created_at')
          .eq('user_id', userId)
          .eq('item_type', 'coupon')
          .order('created_at', ascending: false);

      final events = (rows as List).cast<Map<String, dynamic>>();
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final sevenDaysStart = todayStart.subtract(const Duration(days: 6));
      final monthStart = DateTime(now.year, now.month);
      final copiedEvents =
          events.where((row) => row['event_type'] == 'coupon_copy');
      final usedEvents =
          events.where((row) => row['event_type'] == 'store_click');

      return _ActivityStats(
        copiedCoupons: copiedEvents.length,
        usedCoupons: usedEvents.length,
        today: _countPeriod(
          events,
          copiedType: 'coupon_copy',
          usedType: 'store_click',
          start: todayStart,
        ),
        sevenDays: _countPeriod(
          events,
          copiedType: 'coupon_copy',
          usedType: 'store_click',
          start: sevenDaysStart,
        ),
        month: _countPeriod(
          events,
          copiedType: 'coupon_copy',
          usedType: 'store_click',
          start: monthStart,
        ),
        lastActivity: _buildLatestActivity(events),
      );
    } catch (_) {
      return const _ActivityStats.empty();
    }
  }

  static DateTime? _parseLocalDate(dynamic value) {
    return DateTime.tryParse((value ?? '').toString())?.toLocal();
  }

  static _PeriodStats _countPeriod(
    List<Map<String, dynamic>> events, {
    required String copiedType,
    required String usedType,
    required DateTime start,
  }) {
    final periodEvents = events.where((row) {
      final createdAt = _parseLocalDate(row['created_at']);
      return createdAt != null && !createdAt.isBefore(start);
    }).toList();

    return _PeriodStats(
      copiedCoupons:
          periodEvents.where((row) => row['event_type'] == copiedType).length,
      usedCoupons:
          periodEvents.where((row) => row['event_type'] == usedType).length,
    );
  }

  static _LatestActivity? _buildLatestActivity(
      List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return null;
    final row = rows.first;
    final type = (row['event_type'] ?? '').toString();
    final createdAt = _parseLocalDate(row['created_at']);
    if (createdAt == null) return null;
    return _LatestActivity(type: type, createdAt: createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isArabic = localizations?.locale.languageCode != 'en';
    final topPadding = MediaQuery.of(context).padding.top + 18;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Constants.primaryColor.withValues(alpha: 0.14),
                Colors.white,
              ],
              stops: const [0, 0.34],
            ),
          ),
          child: SafeArea(
            top: false,
            child: FutureBuilder<_ActivityStats>(
              future: _statsFuture,
              builder: (context, snapshot) {
                final stats = snapshot.data ?? const _ActivityStats.empty();
                final isLoading =
                    snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData;

                return Consumer<FavoriteProvider>(
                  builder: (context, favorites, _) {
                    final favoritesCount = favorites.favoriteItems.length;

                    return RefreshIndicator(
                      color: Constants.primaryColor,
                      onRefresh: () async {
                        await favorites.loadFavorites();
                        setState(() {
                          _statsFuture = _fetchActivityStats();
                        });
                        await _statsFuture;
                      },
                      child: ListView(
                        padding: EdgeInsets.fromLTRB(20, topPadding, 20, 120),
                        children: [
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.maybePop(context),
                                icon: Icon(
                                  isArabic
                                      ? Icons.arrow_forward_ios_rounded
                                      : Icons.arrow_back_ios_new_rounded,
                                  color: Constants.primaryColor,
                                  size: 20,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  minimumSize: const Size(44, 44),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  isArabic ? 'نشاطي' : 'My Activity',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Tajawal',
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Constants.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 44),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _HeroWalletCard(
                            isArabic: isArabic,
                            isLoading: isLoading,
                            copiedCoupons: stats.copiedCoupons,
                            usedCoupons: stats.usedCoupons,
                            favoritesCount: favoritesCount,
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title: isArabic ? 'آخر نشاط' : 'Recent Activity',
                            icon: Icons.history_rounded,
                            child: _RecentActivityRow(
                              isArabic: isArabic,
                              activity: stats.lastActivity,
                              isLoading: isLoading,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            title:
                                isArabic ? 'نشاط الكوبونات' : 'Coupon Activity',
                            icon: Icons.calendar_month_rounded,
                            child: Column(
                              children: [
                                _PeriodActivityCard(
                                  title: isArabic ? 'اليوم' : 'Today',
                                  stats: stats.today,
                                  isArabic: isArabic,
                                ),
                                const SizedBox(height: 10),
                                _PeriodActivityCard(
                                  title: isArabic ? 'آخر 7 أيام' : '7 Days',
                                  stats: stats.sevenDays,
                                  isArabic: isArabic,
                                ),
                                const SizedBox(height: 10),
                                _PeriodActivityCard(
                                  title: isArabic ? 'هذا الشهر' : 'This Month',
                                  stats: stats.month,
                                  isArabic: isArabic,
                                  savedItems: favoritesCount,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroWalletCard extends StatelessWidget {
  final bool isArabic;
  final bool isLoading;
  final int copiedCoupons;
  final int usedCoupons;
  final int favoritesCount;

  const _HeroWalletCard({
    required this.isArabic,
    required this.isLoading,
    required this.copiedCoupons,
    required this.usedCoupons,
    required this.favoritesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Constants.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isArabic ? 'إجمالي النشاط' : 'Total Activity',
                      style: const TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Constants.textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isArabic
                          ? 'متابعة تفاعلك مع الكوبونات والمفضلة'
                          : 'Track your coupons and saved items',
                      style: TextStyle(
                        fontFamily: 'Tajawal',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActivityMetric(
                  value: isLoading ? '-' : copiedCoupons.toString(),
                  label: isArabic ? 'كوبون منسوخ' : 'Copied coupons',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActivityMetric(
                  value: isLoading ? '-' : usedCoupons.toString(),
                  label: isArabic ? 'فتح المتجر' : 'Store opens',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActivityMetric(
                  value: favoritesCount.toString(),
                  label: isArabic ? 'عنصر في المفضلة' : 'Favorites',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  final String value;
  final String label;

  const _ActivityMetric({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9E5FF)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 11,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: Constants.textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDE9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Constants.primaryColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: Constants.primaryColor, size: 22),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Constants.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  final bool isArabic;
  final _LatestActivity? activity;
  final bool isLoading;

  const _RecentActivityRow({
    required this.isArabic,
    required this.activity,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final text = isLoading
        ? (isArabic ? 'جاري تحميل نشاطك...' : 'Loading your activity...')
        : _activityText();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.bolt_rounded,
            color: Constants.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Constants.textColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _activityText() {
    if (activity == null) {
      return isArabic
          ? 'ابدأ بنسخ كوبون أو حفظ عرض لعرض نشاطك هنا'
          : 'Copy a coupon or save an offer to see activity here';
    }

    final ago = _timeAgo(activity!.createdAt, isArabic);
    if (activity!.type == 'copy' || activity!.type == 'coupon_copy') {
      return isArabic ? 'نسخت كوبون منذ $ago' : 'Copied a coupon $ago ago';
    }
    if (activity!.type == 'shop_now' || activity!.type == 'store_click') {
      return isArabic ? 'فتحت المتجر منذ $ago' : 'Opened a store $ago ago';
    }
    if (activity!.type == 'share') {
      return isArabic ? 'شاركت كوبون منذ $ago' : 'Shared a coupon $ago ago';
    }
    return isArabic ? 'آخر نشاط منذ $ago' : 'Last activity $ago ago';
  }

  static String _timeAgo(DateTime date, bool isArabic) {
    final difference = DateTime.now().difference(date);
    if (difference.inMinutes < 1) return isArabic ? 'لحظات' : 'moments';
    if (difference.inHours < 1) {
      return isArabic
          ? '${difference.inMinutes} دقيقة'
          : '${difference.inMinutes} min';
    }
    if (difference.inDays < 1) {
      return isArabic
          ? '${difference.inHours} ساعة'
          : '${difference.inHours} hours';
    }
    if (difference.inDays == 1) return isArabic ? 'يوم' : '1 day';
    return isArabic ? '${difference.inDays} أيام' : '${difference.inDays} days';
  }
}

class _PeriodActivityCard extends StatelessWidget {
  final String title;
  final _PeriodStats stats;
  final bool isArabic;
  final int? savedItems;

  const _PeriodActivityCard({
    required this.title,
    required this.stats,
    required this.isArabic,
    this.savedItems,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFBFAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDE9FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Tajawal',
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Constants.textColor,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _PeriodPill(
                  icon: Icons.content_copy_rounded,
                  value: stats.copiedCoupons,
                  label: isArabic ? 'نسخ' : 'Copied',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _PeriodPill(
                  icon: Icons.shopping_bag_rounded,
                  value: stats.usedCoupons,
                  label: isArabic ? 'فتح المتجر' : 'Opened',
                ),
              ),
              if (savedItems != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: _PeriodPill(
                    icon: Icons.star_rounded,
                    value: savedItems!,
                    label: isArabic ? 'محفوظ' : 'Saved',
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;

  const _PeriodPill({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Constants.primaryColor, size: 17),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 17,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: Constants.primaryColor,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Tajawal',
                    fontSize: 10,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: Constants.textColor,
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

class _ActivityStats {
  final int copiedCoupons;
  final int usedCoupons;
  final _PeriodStats today;
  final _PeriodStats sevenDays;
  final _PeriodStats month;
  final _LatestActivity? lastActivity;

  const _ActivityStats({
    required this.copiedCoupons,
    required this.usedCoupons,
    required this.today,
    required this.sevenDays,
    required this.month,
    required this.lastActivity,
  });

  const _ActivityStats.empty()
      : copiedCoupons = 0,
        usedCoupons = 0,
        today = const _PeriodStats.empty(),
        sevenDays = const _PeriodStats.empty(),
        month = const _PeriodStats.empty(),
        lastActivity = null;
}

class _PeriodStats {
  final int copiedCoupons;
  final int usedCoupons;

  const _PeriodStats({
    required this.copiedCoupons,
    required this.usedCoupons,
  });

  const _PeriodStats.empty()
      : copiedCoupons = 0,
        usedCoupons = 0;
}

class _LatestActivity {
  final String type;
  final DateTime createdAt;

  const _LatestActivity({
    required this.type,
    required this.createdAt,
  });
}
