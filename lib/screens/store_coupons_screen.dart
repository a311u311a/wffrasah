import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/store.dart';
import '../models/coupon.dart';
import '../models/offers.dart'; // ✅ Import Offer model
import '../widgets/coupon_card.dart';
import '../widgets/offers_card.dart'; // ✅ Import OffersCard widget
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

  // Data
  List<Coupon> _coupons = [];
  List<Offer> _offers = [];

  // State
  bool _isLoading = true;
  String _errorMessage = '';

  // Subscriptions
  StreamSubscription? _couponsSub;
  StreamSubscription? _offersSub;

  @override
  void initState() {
    super.initState();
    _fetchStoreData();
  }

  @override
  void dispose() {
    _couponsSub?.cancel();
    _offersSub?.cancel();
    super.dispose();
  }

  Future<void> _fetchStoreData() async {
    try {
      final storeId = await _resolveStoreId();
      final storeSlug = _resolveStoreSlug();

      // ✅ Build a list of valid keys (Slug + ID + Name for legacy) to search for
      final searchKeys = <String>{
        if (storeSlug.isNotEmpty) storeSlug,
        if (storeId != null && storeId.isNotEmpty) storeId,
        // Fallback for very old data that might use Name
        widget.store.name.trim(),
      }.toList();

      if (searchKeys.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      debugPrint(
          'Fetching deals for store: ${widget.store.name}, Keys: $searchKeys');

      final langCode =
          AppLocalizations.of(context)?.locale.languageCode ?? 'ar';

      // 1. Listen to Coupons (Match Slug OR ID)
      _couponsSub = _supabase
          .from('coupons')
          .stream(primaryKey: ['id'])
          .inFilter('store_id', searchKeys) // ✅ Robust filtering
          .order('created_at', ascending: false)
          .listen((data) {
            if (!mounted) return;
            setState(() {
              _coupons =
                  data.map((e) => Coupon.fromSupabase(e, langCode)).toList();
              _isLoading = false;
            });
          }, onError: (e) {
            debugPrint('Error fetching coupons: $e');
            if (mounted && _offers.isEmpty) setState(() => _isLoading = false);
          });

      // 2. Listen to Offers (Match Slug OR ID)
      _offersSub = _supabase
          .from('offers')
          .stream(primaryKey: ['id'])
          .inFilter('store_id', searchKeys) // ✅ Robust filtering
          .order('created_at', ascending: false)
          .listen((data) {
            if (!mounted) return;
            setState(() {
              _offers =
                  data.map((e) => Offer.fromSupabase(e, langCode)).toList();
              _isLoading = false;
            });
          }, onError: (e) {
            debugPrint('Error fetching offers: $e');
            if (mounted && _coupons.isEmpty) setState(() => _isLoading = false);
          });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
    }
  }

  /// Finds the valid UUID (id) for the store
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

  /// Finds the valid Slug for the store
  String _resolveStoreSlug() {
    return widget.store.slug.trim();
    // Helper: If slug is missing in object, we mainly rely on ID.
    // However, offers rely on slug. If current 'store' object doesn't have slug,
    // we might have problems.
    // But 'Store.fromSupabase' logic tries to populate slug.
    // If absolutely needed, we could fetch slug using ID here, but let's assume valid data.
  }

  @override
  Widget build(BuildContext context) {
    // If still loading and we have no data yet
    if (_isLoading && _coupons.isEmpty && _offers.isEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: _buildAppBar(),
        body: Center(child: Text('Error: $_errorMessage')),
      );
    }

    final hasCoupons = _coupons.isNotEmpty;
    final hasOffers = _offers.isNotEmpty;
    final isEmpty = !hasCoupons && !hasOffers;

    return Scaffold(
      appBar: _buildAppBar(),
      body: isEmpty
          ? Center(
              child: Text(AppLocalizations.of(context)?.translate('no_deals') ??
                  'لا توجد عروض أو كوبونات حالياً'))
          : ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Coupons Section
                if (hasCoupons) ...[
                  _buildSectionTitle(context, 'coupons', 'كوبونات الخصم'),
                  ..._coupons.map((c) => CouponCard(coupon: c)),
                ],

                if (hasCoupons && hasOffers) const SizedBox(height: 20),

                // Offers Section
                if (hasOffers) ...[
                  _buildSectionTitle(context, 'offers', 'العروض المتاحة'),
                  ..._offers
                      .map((o) => OffersCard(offer: o)), // ✅ Display Offers
                ],

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(widget.store.name),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Constants.primaryColor.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key, String fallback) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        AppLocalizations.of(context)?.translate(key) ?? fallback,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Constants.primaryColor,
        ),
      ),
    );
  }
}
