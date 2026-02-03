import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/store.dart';
import '../models/coupon.dart';
import '../models/offers.dart';
import '../constants.dart';
import '../providers/locale_provider.dart';
import '../web_widgets/responsive_layout.dart';
import '../web_widgets/web_navigation_bar.dart';
import '../web_widgets/web_footer.dart';
import '../web_widgets/web_coupon_card.dart';
import '../web_widgets/web_offer_card.dart';

/// Web version of Store Detail Screen
/// Shows store information with coupons and offers in tabs
class WebStoreDetailScreen extends StatefulWidget {
  final Store store;

  const WebStoreDetailScreen({super.key, required this.store});

  @override
  State<WebStoreDetailScreen> createState() => _WebStoreDetailScreenState();
}

class _WebStoreDetailScreenState extends State<WebStoreDetailScreen>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  List<Coupon> _coupons = [];
  List<Offer> _offers = [];
  bool _isLoading = true;
  String _errorMessage = '';

  StreamSubscription? _couponsSub;
  StreamSubscription? _offersSub;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

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
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchStoreData() async {
    try {
      final localeProvider =
          Provider.of<LocaleProvider>(context, listen: false);
      final langCode = localeProvider.locale.languageCode;
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _coupons.isEmpty && _offers.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: const WebNavigationBar(),
        body: Center(
          child: CircularProgressIndicator(color: Constants.primaryColor),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) return _buildErrorScreen();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: const WebNavigationBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStoreHeader(),
            if (widget.store.description.isNotEmpty) _buildDescription(),
            _buildTabBar(),
            _buildTabContent(),
            const SizedBox(height: 40),
            const WebFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreHeader() {
    return Container(
      padding: ResponsivePadding.page(context),
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
      child: Column(
        children: [
          const SizedBox(height: 40),
          // Store Logo
          Container(
            width: 140,
            height: 140,
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
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: widget.store.image.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.store.image,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.storefront_rounded,
                        size: 64,
                        color: Constants.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                  )
                : Icon(
                    Icons.storefront_rounded,
                    size: 64,
                    color: Constants.primaryColor.withValues(alpha: 0.3),
                  ),
          ),
          const SizedBox(height: 20),
          // Store Name
          Text(
            widget.store.name,
            style: TextStyle(
              fontSize: ResponsiveLayout.isDesktop(context) ? 42 : 32,
              fontWeight: FontWeight.w900,
              color: Constants.primaryColor,
              fontFamily: 'Tajawal',
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    return Container(
      margin: ResponsivePadding.page(context).copyWith(top: 20, bottom: 0),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Constants.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              color: Constants.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              widget.store.description,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.7,
                fontSize: 16,
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final hasCoupons = _coupons.isNotEmpty;
    final hasOffers = _offers.isNotEmpty;

    return Container(
      margin: ResponsivePadding.page(context).copyWith(top: 30, bottom: 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Constants.primaryColor,
            indicator: BoxDecoration(
              color: Constants.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              fontFamily: 'Tajawal',
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              fontFamily: 'Tajawal',
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                        'كوبونات الخصم ${hasCoupons ? '(${_coupons.length})' : ''}'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.local_offer_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text(
                        'العروض المتاحة ${hasOffers ? '(${_offers.length})' : ''}'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    return Container(
      margin: ResponsivePadding.page(context).copyWith(top: 30),
      constraints: const BoxConstraints(minHeight: 300),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildCouponsGrid(),
          _buildOffersGrid(),
        ],
      ),
    );
  }

  Widget _buildCouponsGrid() {
    if (_coupons.isEmpty) {
      return _buildEmptyState('لا توجد كوبونات متاحة حالياً');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveGrid.columns(context, max: 6),
        crossAxisSpacing: ResponsiveGrid.spacing(context),
        mainAxisSpacing: ResponsiveGrid.spacing(context),
        childAspectRatio: 0.48, // ✅ زيادة الارتفاع
      ),
      itemCount: _coupons.length,
      itemBuilder: (context, index) {
        return WebCouponCard(
          coupon: _coupons[index],
          storeName: widget.store.name,
        );
      },
    );
  }

  Widget _buildOffersGrid() {
    if (_offers.isEmpty) {
      return _buildEmptyState('لا توجد عروض متاحة حالياً');
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: ResponsiveGrid.columns(context, max: 4),
        crossAxisSpacing: ResponsiveGrid.spacing(context),
        mainAxisSpacing: ResponsiveGrid.spacing(context),
        childAspectRatio: 0.75,
      ),
      itemCount: _offers.length,
      itemBuilder: (context, index) {
        return WebOfferCard(
          offer: _offers[index],
          storeName: widget.store.name,
          storeImage: widget.store.image, // ✅ إضافة شعار المتجر
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(60),
        decoration: BoxDecoration(
          color: Constants.primaryColor.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Constants.primaryColor.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_rounded,
                size: 64,
                color: Constants.primaryColor.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'تحقق مرة أخرى قريباً',
              style: TextStyle(
                fontFamily: 'Tajawal',
                fontSize: 14,
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
      appBar: const WebNavigationBar(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 80,
              color: Colors.red[300],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 16,
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
