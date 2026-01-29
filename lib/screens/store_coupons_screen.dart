import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../widgets/coupon_card.dart';
import '../widgets/offers_card.dart';
import '../localization/app_localizations.dart';
import '../constants.dart';

class StoreCouponsScreen extends StatefulWidget {
  final Store store;

  const StoreCouponsScreen({super.key, required this.store});

  @override
  State<StoreCouponsScreen> createState() => _StoreCouponsScreenState();
}

class _StoreCouponsScreenState extends State<StoreCouponsScreen> {
  final _supabase = Supabase.instance.client;

  // --- Data & State ---
  List<Coupon> _coupons = [];
  List<Offer> _offers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  // --- Subscriptions ---
  StreamSubscription? _couponsSub;
  StreamSubscription? _offersSub;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_couponsSub == null && _offersSub == null) {
      _fetchStoreData();
    }
  }

  @override
  void dispose() {
    _couponsSub?.cancel();
    _offersSub?.cancel();
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
          .order('created_at', ascending: false)
          .listen((data) {
            if (!mounted) return;
            setState(() {
              _coupons =
                  data.map((e) => Coupon.fromSupabase(e, langCode)).toList();
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

  // --- UI Components ---
  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);

    if (_isLoading && _coupons.isEmpty && _offers.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FD),
        body: Center(
            child: CircularProgressIndicator(color: Constants.primaryColor)),
      );
    }

    if (_errorMessage.isNotEmpty) return _buildErrorScreen();

    final hasCoupons = _coupons.isNotEmpty;
    final hasOffers = _offers.isNotEmpty;
    final isEmpty = !hasCoupons && !hasOffers;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          if (widget.store.description.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _buildDescriptionCard(),
              ),
            ),
          if (isEmpty)
            _buildEmptyState(t)
          else ...[
            if (hasCoupons) ...[
              _buildSectionHeader(context, 'coupons', 'كوبونات الخصم',
                  topPadding: 24),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => CouponCard(coupon: _coupons[index]),
                    childCount: _coupons.length,
                  ),
                ),
              ),
            ],
            if (hasOffers) ...[
              _buildSectionHeader(context, 'offers', 'العروض المتاحة',
                  topPadding: hasCoupons ? 20 : 24),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => OffersCard(offer: _offers[index]),
                    childCount: _offers.length,
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: Constants.primaryColor, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Constants.primaryColor.withValues(alpha: 0.08),
                    Constants.primaryColor.withValues(alpha: 0.02),
                    Colors.white,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
            // Decorative elements
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Constants.primaryColor.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -30,
              left: -50,
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Constants.primaryColor.withValues(alpha: 0.04),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    _buildStoreLogo(),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.store.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Tajawal',
                          color: Constants.primaryColor,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreLogo() {
    return Hero(
      tag: 'store_logo_${widget.store.id}',
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Constants.primaryColor.withValues(alpha: 0.08),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Constants.primaryColor.withValues(alpha: 0.12),
              blurRadius: 24,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
    );
  }

  Widget _buildDescriptionCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Constants.primaryColor.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Constants.primaryColor.withValues(alpha: 0.04),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
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
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.7,
                fontSize: 14,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String key, String fallback,
      {required double topPadding}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, topPadding, 16, 12),
        child: _buildSectionTitle(context, key, fallback),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key, String fallback) {
    final t = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            t?.translate(key) ?? fallback,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Tajawal',
              color: Colors.grey[850],
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations? t) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_offer_outlined,
                size: 64,
                color: Constants.primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              t?.translate('no_deals') ?? 'لا توجد عروض حالياً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'تحقق مرة أخرى قريباً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 13,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
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
}
