import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../widgets/coupon_card.dart';
import '../widgets/loading_indicator.dart';
import '../localization/app_localizations.dart';
import '../constants.dart';

class StoreCouponsScreen extends StatefulWidget {
  final Store store;

  const StoreCouponsScreen({super.key, required this.store});

  @override
  State<StoreCouponsScreen> createState() => _StoreCouponsScreenState();
}

class _StoreContentTab {
  final int index;
  final IconData icon;
  final String label;

  const _StoreContentTab({
    required this.index,
    required this.icon,
    required this.label,
  });
}

class _StoreLogoOrbitPainter extends CustomPainter {
  final Color color;

  const _StoreLogoOrbitPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.48;

    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;

    final arcRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(arcRect, -1.42, 2.72, false, arcPaint);
    canvas.drawArc(arcRect, 1.48, 0.78, false, arcPaint);

    final smallDotPaint = Paint()..color = color.withValues(alpha: 0.24);
    final dotPaint = Paint()..color = color.withValues(alpha: 0.82);

    canvas.drawCircle(_pointOnCircle(center, radius, 0.22), 8.2, dotPaint);
    canvas.drawCircle(_pointOnCircle(center, radius, 1.64), 3.2, smallDotPaint);

    _drawSparkle(
      canvas,
      _pointOnCircle(center, radius + .44, -0.9),
      10,
      color.withValues(alpha: 0.88),
    );
  }

  Offset _pointOnCircle(Offset center, double radius, double angle) {
    return Offset(
      center.dx + math.cos(angle) * radius,
      center.dy + math.sin(angle) * radius,
    );
  }

  void _drawSparkle(Canvas canvas, Offset center, double size, Color color) {
    final path = Path()
      ..moveTo(center.dx, center.dy - size)
      ..quadraticBezierTo(
        center.dx + size * 0.22,
        center.dy - size * 0.22,
        center.dx + size,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx + size * 0.22,
        center.dy + size * 0.22,
        center.dx,
        center.dy + size,
      )
      ..quadraticBezierTo(
        center.dx - size * 0.22,
        center.dy + size * 0.22,
        center.dx - size,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx - size * 0.22,
        center.dy - size * 0.22,
        center.dx,
        center.dy - size,
      )
      ..close();

    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StoreLogoOrbitPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _StoreRatingStars extends StatelessWidget {
  final int value;
  final bool busy;
  final ValueChanged<int> onSelected;

  const _StoreRatingStars({
    required this.value,
    required this.busy,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final rating = index + 1;
        final selected = rating <= value;
        return InkResponse(
          onTap: busy ? null : () => onSelected(rating),
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: Icon(
              selected ? Icons.star_rounded : Icons.star_border_rounded,
              color: const Color(0xFFFFB928),
              size: 20,
            ),
          ),
        );
      }),
    );
  }
}

class _StoreHeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _StoreHeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Material(
        color: Constants.primaryColor.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(14),
          child: Icon(icon, color: Constants.primaryColor, size: 24),
        ),
      ),
    );
  }
}

class _StoreCouponsScreenState extends State<StoreCouponsScreen> {
  final _supabase = Supabase.instance.client;

  // --- Data & State ---
  List<Coupon> _coupons = [];
  List<Offer> _offers = [];
  bool _isLoading = true;
  String _errorMessage = '';
  int _selectedTab = 0;
  bool _isFollowing = false;
  bool _followBusy = false;
  double _averageRating = 0;
  int _ratingCount = 0;
  int? _myRating;
  bool _ratingBusy = false;

  // --- Subscriptions ---
  StreamSubscription? _couponsSub;
  StreamSubscription? _offersSub;
  StreamSubscription? _ratingsSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_couponsSub == null && _offersSub == null) {
      _fetchStoreData();
      unawaited(_loadFollowState());
      _listenToRatings();
      unawaited(_loadMyRating());
    }
  }

  @override
  void dispose() {
    _couponsSub?.cancel();
    _offersSub?.cancel();
    _ratingsSub?.cancel();
    super.dispose();
  }

  // --- Logic Methods ---
  Future<void> _fetchStoreData() async {
    try {
      final langCode =
          AppLocalizations.of(context)?.locale.languageCode ?? 'ar';
      final storeId = await _resolveStoreId();
      final storeSlug = _resolveStoreSlug();

      final searchKeys = <String>{
        if (storeId != null && storeId.isNotEmpty) storeId,
        if (storeSlug.isNotEmpty) storeSlug,
        if (widget.store.name.isNotEmpty) widget.store.name,
        if (widget.store.nameEn.isNotEmpty) widget.store.nameEn,
        if (widget.store.nameAr.isNotEmpty) widget.store.nameAr,
      }.where((e) => e.trim().isNotEmpty).toList();

      // Coupons Stream
      _couponsSub = _supabase
          .from('coupons')
          .stream(primaryKey: ['id'])
          .inFilter('store_id', searchKeys)
          .eq('approval_status', 'approved')
          .order('created_at', ascending: false)
          .listen((data) {
            if (!mounted) return;
            setState(() {
              _coupons = data
                  .map((e) => Coupon.fromSupabase(
                        _withCurrentStore(e),
                        langCode,
                      ))
                  .toList();
              _isLoading = false;
            });
          }, onError: (e) {
            if (mounted && _offers.isEmpty) setState(() => _isLoading = false);
          });

      // Offers Stream
      _offersSub = _supabase
          .from('offers')
          .stream(primaryKey: ['id'])
          .inFilter('store_id', searchKeys)
          .order('created_at', ascending: false)
          .listen((data) {
            if (!mounted) return;
            setState(() {
              _offers =
                  data.map((e) => Offer.fromSupabase(e, langCode)).toList();
              _isLoading = false;
            });
          }, onError: (e) {
            if (mounted && _coupons.isEmpty) setState(() => _isLoading = false);
          });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<String?> _resolveStoreId() async {
    final rawId = widget.store.id.trim();
    if (rawId.isNotEmpty) return rawId;
    final slug = widget.store.slug.trim();
    if (slug.isEmpty) return null;
    final res = await _supabase
        .from('stores')
        .select('id')
        .eq('slug', slug)
        .maybeSingle();
    return res?['id']?.toString();
  }

  String _resolveStoreSlug() => widget.store.slug.trim();

  String get _storeFollowKey {
    final key = widget.store.key.trim();
    if (key.isNotEmpty) return key;
    return widget.store.id.trim();
  }

  List<_StoreContentTab> get _availableTabs {
    return [
      if (_coupons.isNotEmpty)
        const _StoreContentTab(
          index: 0,
          icon: Icons.confirmation_number_outlined,
          label: 'الكوبونات',
        ),
      if (_offers.isNotEmpty)
        const _StoreContentTab(
          index: 1,
          icon: Icons.local_offer_outlined,
          label: 'العروض',
        ),
    ];
  }

  int? get _activeTabIndex {
    final tabs = _availableTabs;
    if (tabs.isEmpty) return null;
    if (tabs.any((tab) => tab.index == _selectedTab)) return _selectedTab;
    return tabs.first.index;
  }

  Future<void> _loadFollowState() async {
    final userId = _supabase.auth.currentUser?.id;
    final storeKey = _storeFollowKey;
    if (userId == null || storeKey.isEmpty) return;

    try {
      final row = await _supabase
          .from('store_follows')
          .select('id')
          .eq('user_id', userId)
          .eq('store_id', storeKey)
          .maybeSingle();
      if (mounted) setState(() => _isFollowing = row != null);
    } catch (_) {}
  }

  Future<void> _toggleFollow() async {
    if (_followBusy) return;
    final user = _supabase.auth.currentUser;
    final storeKey = _storeFollowKey;
    if (user == null || storeKey.isEmpty) return;

    setState(() => _followBusy = true);
    try {
      if (_isFollowing) {
        await _supabase
            .from('store_follows')
            .delete()
            .eq('user_id', user.id)
            .eq('store_id', storeKey);
      } else {
        await _supabase.from('store_follows').insert({
          'user_id': user.id,
          'store_id': storeKey,
        });
      }
      if (mounted) setState(() => _isFollowing = !_isFollowing);
    } on PostgrestException catch (e) {
      if (e.code == '23505') {
        if (mounted) setState(() => _isFollowing = true);
      }
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  void _listenToRatings() {
    final storeKey = _storeFollowKey;
    if (storeKey.isEmpty) return;

    _ratingsSub?.cancel();
    _ratingsSub = _supabase
        .from('store_ratings')
        .stream(primaryKey: ['id'])
        .eq('store_id', storeKey)
        .listen((data) {
          if (!mounted) return;
          final ratings = data
              .map((row) => int.tryParse((row['rating'] ?? '').toString()))
              .whereType<int>()
              .toList();
          final total = ratings.fold<int>(0, (sum, value) => sum + value);
          setState(() {
            _ratingCount = ratings.length;
            _averageRating = ratings.isEmpty ? 0 : total / ratings.length;
          });
        }, onError: (_) {});
  }

  Future<void> _loadMyRating() async {
    final userId = _supabase.auth.currentUser?.id;
    final storeKey = _storeFollowKey;
    if (userId == null || storeKey.isEmpty) return;

    try {
      final row = await _supabase
          .from('store_ratings')
          .select('rating')
          .eq('user_id', userId)
          .eq('store_id', storeKey)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _myRating = int.tryParse((row?['rating'] ?? '').toString());
      });
    } catch (_) {}
  }

  Future<void> _submitRating(int rating) async {
    if (_ratingBusy) return;
    final user = _supabase.auth.currentUser;
    final storeKey = _storeFollowKey;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('سجل الدخول أولاً لتقييم المتجر')),
      );
      return;
    }
    if (storeKey.isEmpty) return;

    setState(() => _ratingBusy = true);
    try {
      await _supabase.from('store_ratings').upsert({
        'user_id': user.id,
        'store_id': storeKey,
        'rating': rating,
      }, onConflict: 'user_id,store_id');
      if (mounted) setState(() => _myRating = rating);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذر حفظ تقييم المتجر')),
      );
    } finally {
      if (mounted) setState(() => _ratingBusy = false);
    }
  }

  // --- UI Components ---
  @override
  Widget build(BuildContext context) {
    if (_isLoading && _coupons.isEmpty && _offers.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: const CustomLoadingIndicator(
          message: 'جاري تحميل تفاصيل المتجر',
        ),
      );
    }

    if (_errorMessage.isNotEmpty) return _buildErrorScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFFBFAFF),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _buildTopBar(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                children: [
                  _buildStoreHero(),
                  if (_availableTabs.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    _buildTabs(),
                    const SizedBox(height: 16),
                  ] else
                    const SizedBox(height: 18),
                  _buildSelectedContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 62,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          children: [
            _StoreHeaderIconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icons.arrow_back_rounded,
            ),
            const Expanded(
              child: Text(
                'صفحة المتجر',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Constants.textColor,
                ),
              ),
            ),
            const SizedBox(width: 44, height: 44),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHero() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.09),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStoreLogo(),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.store.name,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Tajawal',
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: Constants.storeNameColor,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(child: _buildRatingRow()),
                      const SizedBox(height: 14),
                      Center(
                        child: SizedBox(
                          width: 148,
                          height: 44,
                          child: ElevatedButton(
                            onPressed: _followBusy ? null : _toggleFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isFollowing
                                  ? Constants.primaryColor
                                  : Colors.white,
                              foregroundColor: _isFollowing
                                  ? Colors.white
                                  : Constants.primaryColor,
                              elevation: 0,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Constants.primaryColor,
                                  width: 1.4,
                                ),
                              ),
                            ),
                            child: Text(
                              _isFollowing ? 'متابَع' : 'متابعة المتجر',
                              style: const TextStyle(
                                fontFamily: 'Tajawal',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.store.description.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildDescriptionCard(),
          ],
        ],
      ),
    );
  }

  Widget _buildStoreLogo() {
    return Hero(
      tag: 'store_logo_${widget.store.id}',
      child: SizedBox(
        width: 148,
        height: 148,
        child: CustomPaint(
          painter: _StoreLogoOrbitPainter(color: Constants.primaryColor),
          child: Center(
            child: Container(
              width: 118,
              height: 118,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Constants.primaryColor.withValues(alpha: 0.13),
                    blurRadius: 26,
                    spreadRadius: 2,
                    offset: const Offset(0, 9),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.045),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(14),
              child: widget.store.image.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.store.image,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.storefront_rounded,
                          size: 48,
                          color: Constants.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                    )
                  : Icon(
                      Icons.storefront_rounded,
                      size: 48,
                      color: Constants.primaryColor.withValues(alpha: 0.3),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRatingRow() {
    final displayedRating = _averageRating.toStringAsFixed(1);
    final activeStars = _myRating ?? _averageRating.round();

    return Directionality(
      textDirection: TextDirection.ltr,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFFFE8AE)),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                displayedRating,
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 14,
                  color: Color(0xFF55515F),
                ),
              ),
              const SizedBox(width: 6),
              _StoreRatingStars(
                value: activeStars.clamp(0, 5),
                busy: _ratingBusy,
                onSelected: _submitRating,
              ),
              const SizedBox(width: 6),
              Text(
                '($_ratingCount)',
                style: const TextStyle(
                  fontFamily: 'Tajawal',
                  fontSize: 13,
                  color: Color(0xFF777283),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Constants.primaryColor.withValues(alpha: 0.035),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Constants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              widget.store.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.8,
                fontSize: 14,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = _availableTabs;
    if (tabs.isEmpty) return const SizedBox.shrink();
    final activeTab = _activeTabIndex;

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          for (var i = 0; i < tabs.length; i++) ...[
            Expanded(
              child: _StoreTabButton(
                icon: tabs[i].icon,
                label: tabs[i].label,
                selected: activeTab == tabs[i].index,
                onTap: () => setState(() => _selectedTab = tabs[i].index),
              ),
            ),
            if (i != tabs.length - 1)
              Container(
                width: 1,
                height: 28,
                color: Colors.grey.withValues(alpha: 0.12),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedContent() {
    final langCode = Localizations.localeOf(context).languageCode;
    final activeTab = _activeTabIndex;
    if (activeTab == 0) {
      return Column(
        children: _coupons.map((coupon) => CouponCard(coupon: coupon)).toList(),
      );
    }

    if (activeTab == 1) {
      return Column(
        children: _offers
            .map((offer) => CouponCard(
                  coupon: _offerAsCoupon(offer, langCode),
                  storeName: widget.store.name,
                ))
            .toList(),
      );
    }

    return _buildEmptyBox('لا توجد كوبونات أو عروض حالياً');
  }

  Coupon _offerAsCoupon(Offer offer, String langCode) {
    final tags = offer.tags;
    return Coupon.fromSupabase({
      ...offer.toJson(),
      'code': tags.isNotEmpty ? tags.first : '',
      'coupon_type': 'offer',
      'discount_percent': null,
      'terms': '',
      'terms_ar': '',
      'terms_en': '',
      'is_active': true,
      'last_used_at': null,
      'store_name': widget.store.name,
      'store_name_ar': widget.store.nameAr.isNotEmpty
          ? widget.store.nameAr
          : widget.store.name,
      'store_name_en': widget.store.nameEn.isNotEmpty
          ? widget.store.nameEn
          : widget.store.name,
      'store_image': widget.store.image,
      'tags': tags,
    }, langCode);
  }

  Widget _buildEmptyBox(String fallback) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Constants.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.local_offer_outlined,
            size: 54,
            color: Constants.primaryColor.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            fallback,
            style: TextStyle(
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        leading: BackButton(color: Constants.primaryColor),
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 14,
                  fontFamily: 'Tajawal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _withCurrentStore(Map<String, dynamic> row) {
    return {
      ...row,
      'store_name_ar': widget.store.nameAr,
      'store_name_en': widget.store.nameEn,
      'store_image': widget.store.image,
    };
  }
}

class _StoreTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _StoreTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? Constants.primaryColor : Colors.grey[600]!;

    return Material(
      color: selected
          ? Constants.primaryColor.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(11),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Tajawal',
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
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
